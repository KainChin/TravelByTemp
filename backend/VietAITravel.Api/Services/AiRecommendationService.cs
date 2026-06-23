using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using MongoDB.Bson;
using Pgvector;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Mongo;

namespace VietAITravel.Api.Services;

public class AiRecommendationService(
    AppDbContext db,
    WeatherService weather,
    OllamaService ollama,
    VectorSearchService vectorSearch,
    MongoLogService mongo,
    ILogger<AiRecommendationService> logger)
{
    public async Task<AiRecommendResponse> RecommendAsync(
        Guid userId, AiRecommendRequest request, CancellationToken ct = default)
    {
        var weatherResult = await weather.GetCurrentWeatherAsync(request.Latitude, request.Longitude, ct);
        var locationName = request.LocationName ?? $"({request.Latitude:F2}, {request.Longitude:F2})";

        await mongo.SaveWeatherSnapshotAsync(new WeatherSnapshot
        {
            UserId = userId.ToString(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            LocationName = locationName,
            Temperature = weatherResult.TemperatureC,
            WeatherDescription = weatherResult.Description,
            Humidity = weatherResult.Humidity,
            WindSpeed = weatherResult.WindSpeedKmh
        }, ct);

        var queryText = BuildQueryText(request, weatherResult, locationName);
        var embedding = await ollama.GetEmbeddingAsync(queryText, ct);
        var matches = await vectorSearch.SearchAsync(embedding, request.TopK, request.BudgetInput, ct);

        if (matches.Count == 0)
            throw new InvalidOperationException("Không tìm thấy địa điểm phù hợp.");

        var prompt = BuildPrompt(request, weatherResult, locationName, matches);
        var rawResponse = await ollama.ChatAsync(prompt, ct);
        var parsed = ParseAiResponse(rawResponse, matches);

        if (parsed == null)
        {
            logger.LogWarning("Ollama returned an invalid AI schedule payload. Falling back to deterministic schedule.");
            parsed = BuildFallbackResponse(request, weatherResult, matches);
        }
        else
        {
            parsed = NormalizeAiResponse(parsed, request, weatherResult, matches);
        }

        var scheduleId = Guid.NewGuid();
        var schedule = new Schedule
        {
            Id = scheduleId,
            UserId = userId,
            Title = parsed.title,
            TotalDays = request.TotalDays,
            BudgetInput = request.BudgetInput,
            PreferenceInput = request.PreferenceInput,
            UserLatitude = (decimal)request.Latitude,
            UserLongitude = (decimal)request.Longitude,
            UserLocationName = locationName,
            CurrentTemperature = (decimal)weatherResult.TemperatureC,
            CurrentWeatherDescription = weatherResult.Description,
            AiModelUsed = ollama.ChatModel,
            EmbeddingModelUsed = ollama.EmbeddingModel,
            GeneratedAt = DateTime.UtcNow
        };

        db.Schedules.Add(schedule);
        await PersistDailyPlanAsync(scheduleId, parsed, matches, ct);

        var mongoLog = new AiRecommendationLog
        {
            UserId = userId.ToString(),
            ScheduleId = scheduleId.ToString(),
            AiModelUsed = ollama.ChatModel,
            EmbeddingModelUsed = ollama.EmbeddingModel,
            PromptText = prompt,
            RawResponseText = rawResponse,
            ParsedResponse = BsonDocument.Parse(JsonSerializer.Serialize(parsed))
        };
        var mongoId = await mongo.SaveAiLogAsync(mongoLog, ct);
        schedule.MongoAiLogId = mongoId;
        await db.SaveChangesAsync(ct);

        await mongo.LogInteractionAsync(new UserInteractionLog
        {
            UserId = userId.ToString(),
            EventType = "AI_RECOMMENDATION",
            Metadata = new BsonDocument { { "scheduleId", scheduleId.ToString() } }
        }, ct);

        return new AiRecommendResponse(
            scheduleId,
            mongoId,
            parsed.title,
            parsed.summary,
            (decimal)weatherResult.TemperatureC,
            weatherResult.Description,
            parsed.recommendedDestinations.Select(r => new RecommendedDestinationDto(
                Guid.Parse(r.destinationId), r.name, r.reason, r.weatherFit, r.estimatedCost)).ToList(),
            parsed.dailyPlan.Select(d => new DailyPlanDto(
                d.day,
                d.items.Select(i => new DailyPlanItemDto(
                    Guid.Parse(i.destinationId), i.time, i.activity, i.note)).ToList())).ToList());
    }

    private static string BuildQueryText(AiRecommendRequest req, WeatherResult w, string location) =>
        $"Tôi muốn đi du lịch nơi phù hợp với thời tiết {w.TemperatureC:F0}°C tại {location}, " +
        $"ngân sách {req.BudgetInput:N0} VND, {req.TotalDays} ngày, sở thích: {req.PreferenceInput}";

    private static string BuildPrompt(
        AiRecommendRequest req, WeatherResult w, string location,
        IReadOnlyList<VectorSearchResult> matches)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Bạn là AI travel planner cho ứng dụng du lịch Việt Nam.");
        sb.AppendLine("QUY ĐỊNH: Chỉ chọn địa điểm trong danh sách. Không bịa địa điểm mới. Trả về JSON hợp lệ.");
        sb.AppendLine($"Vị trí: {location} ({req.Latitude}, {req.Longitude})");
        sb.AppendLine($"Nhiệt độ: {w.TemperatureC:F1}°C - {w.Description}");
        sb.AppendLine($"Ngân sách: {req.BudgetInput:N0} VND | Số ngày: {req.TotalDays}");
        sb.AppendLine($"Sở thích: {req.PreferenceInput}");
        sb.AppendLine("DANH SÁCH ĐỊA ĐIỂM:");
        foreach (var m in matches)
        {
            sb.AppendLine($"- ID={m.Destination.Id} | {m.Destination.Name} | {m.Destination.Province} | " +
                            $"{m.Destination.Category} | {m.Destination.EstimatedCost:N0} VND | sim={m.Similarity:F2}");
        }
        sb.AppendLine("FORMAT JSON: { title, summary, recommendedDestinations[{destinationId,name,reason,weatherFit,estimatedCost}], dailyPlan[{day,items[{destinationId,time,activity,note}]}] }");
        return sb.ToString();
    }

    private static AiScheduleJson? ParseAiResponse(string raw, IReadOnlyList<VectorSearchResult> matches)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        try
        {
            var json = ExtractJson(raw);
            var parsed = JsonSerializer.Deserialize<AiScheduleJson>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            if (parsed?.recommendedDestinations?.Count > 0)
                return parsed;
        }
        catch (Exception) { /* fallback below */ }
        return null;
    }

    private static string ExtractJson(string text)
    {
        var start = text.IndexOf('{');
        var end = text.LastIndexOf('}');
        return start >= 0 && end > start ? text[start..(end + 1)] : text;
    }

    private static AiScheduleJson BuildFallbackResponse(
        AiRecommendRequest req, WeatherResult w, IReadOnlyList<VectorSearchResult> matches)
    {
        var top = matches.Take(Math.Min(req.TotalDays, matches.Count)).ToList();
        var recs = top.Select(m => new AiRecommendedDestination(
            m.Destination.Id.ToString(),
            m.Destination.Name,
            $"Phù hợp ngân sách và thời tiết {w.TemperatureC:F0}°C",
            m.Destination.SuitableWeather ?? w.Description,
            m.Destination.EstimatedCost)).ToList();

        var daily = new List<AiDailyPlan>();
        for (var day = 1; day <= req.TotalDays; day++)
        {
            var dest = top[(day - 1) % top.Count];
            daily.Add(new AiDailyPlan(day, new List<AiDailyPlanItem>
            {
                new(dest.Destination.Id.ToString(), "08:00", $"Khám phá {dest.Destination.Name}", "Gợi ý tự động"),
                new(dest.Destination.Id.ToString(), "14:00", "Tham quan & ẩm thực", null)
            }));
        }

        return new AiScheduleJson(
            $"Lịch trình {req.TotalDays} ngày - {w.Description}",
            $"Gợi ý dựa trên vector search và thời tiết {w.TemperatureC:F0}°C",
            recs,
            daily);
    }

    private static AiScheduleJson NormalizeAiResponse(
        AiScheduleJson parsed,
        AiRecommendRequest req,
        WeatherResult weatherResult,
        IReadOnlyList<VectorSearchResult> matches)
    {
        var destinationsById = matches.ToDictionary(m => m.Destination.Id);
        var fallback = matches.First().Destination;

        var recs = (parsed.recommendedDestinations ?? [])
            .Where(r => Guid.TryParse(r.destinationId, out var id) && destinationsById.ContainsKey(id))
            .Select(r =>
            {
                var destination = destinationsById[Guid.Parse(r.destinationId)].Destination;
                return new AiRecommendedDestination(
                    destination.Id.ToString(),
                    destination.Name,
                    string.IsNullOrWhiteSpace(r.reason) ? "Phu hop voi so thich va ngan sach." : r.reason,
                    string.IsNullOrWhiteSpace(r.weatherFit) ? weatherResult.Description : r.weatherFit,
                    destination.EstimatedCost);
            })
            .GroupBy(r => r.destinationId)
            .Select(g => g.First())
            .ToList();

        if (recs.Count == 0)
        {
            recs.Add(new AiRecommendedDestination(
                fallback.Id.ToString(),
                fallback.Name,
                "Phu hop voi so thich va ngan sach.",
                fallback.SuitableWeather ?? weatherResult.Description,
                fallback.EstimatedCost));
        }

        var days = (parsed.dailyPlan ?? [])
            .Where(d => d.day >= 1 && d.day <= req.TotalDays)
            .OrderBy(d => d.day)
            .Select(d => new AiDailyPlan(
                d.day,
                (d.items ?? [])
                    .Select(i => NormalizeDailyItem(i, destinationsById, fallback))
                    .ToList()))
            .Where(d => d.items.Count > 0)
            .GroupBy(d => d.day)
            .Select(g => g.First())
            .ToList();

        if (days.Count == 0)
            days = BuildFallbackResponse(req, weatherResult, matches).dailyPlan;

        return new AiScheduleJson(
            string.IsNullOrWhiteSpace(parsed.title) ? $"Lich trinh {req.TotalDays} ngay" : parsed.title,
            string.IsNullOrWhiteSpace(parsed.summary) ? "Goi y dua tren AI, vector search va thoi tiet." : parsed.summary,
            recs,
            days);
    }

    private static AiDailyPlanItem NormalizeDailyItem(
        AiDailyPlanItem item,
        IReadOnlyDictionary<Guid, VectorSearchResult> destinationsById,
        Destination fallback)
    {
        var destinationId = Guid.TryParse(item.destinationId, out var id) && destinationsById.ContainsKey(id)
            ? id
            : fallback.Id;

        var time = TimeOnly.TryParse(item.time, out var parsedTime)
            ? parsedTime.ToString("HH:mm")
            : "08:00";

        var activity = string.IsNullOrWhiteSpace(item.activity)
            ? $"Tham quan {fallback.Name}"
            : item.activity;

        return new AiDailyPlanItem(destinationId.ToString(), time, activity, item.note);
    }

    private async Task PersistDailyPlanAsync(
        Guid scheduleId, AiScheduleJson parsed, IReadOnlyList<VectorSearchResult> matches, CancellationToken ct)
    {
        var validIds = matches.Select(m => m.Destination.Id).ToHashSet();
        foreach (var day in parsed.dailyPlan)
        {
            var order = 1;
            foreach (var item in day.items)
            {
                if (!Guid.TryParse(item.destinationId, out var destId) || !validIds.Contains(destId))
                    destId = matches.First().Destination.Id;

                TimeOnly? time = TimeOnly.TryParse(item.time, out var t) ? t : null;
                db.ScheduleDestinations.Add(new ScheduleDestination
                {
                    Id = Guid.NewGuid(),
                    ScheduleId = scheduleId,
                    DestinationId = destId,
                    DayNumber = day.day,
                    OrderInDay = order++,
                    Note = item.note,
                    EstimatedTime = time,
                    AiReason = item.activity,
                    WeatherFitNote = parsed.recommendedDestinations
                        .FirstOrDefault(r => r.destinationId == destId.ToString())?.weatherFit
                });
            }
        }
        await db.SaveChangesAsync(ct);
    }

    public async Task UpdateDestinationEmbeddingAsync(Guid destinationId, CancellationToken ct = default)
    {
        var dest = await db.Destinations.FindAsync([destinationId], ct)
            ?? throw new KeyNotFoundException("Destination not found");

        var text = dest.EmbeddingText ?? $"{dest.Name} {dest.Province} {dest.Category} {dest.Description}";
        var embedding = await ollama.GetEmbeddingAsync(text, ct);
        dest.Embedding = new Vector(EmbeddingVector.NormalizeDimension(embedding));
        dest.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }
}
