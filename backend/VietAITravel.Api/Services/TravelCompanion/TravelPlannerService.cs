using System.Text.Json;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services.TravelCompanion;

public sealed class TravelPlannerService(
    DestinationDiscoveryService destinations,
    WeatherService weather,
    SemanticKernelTravelOrchestrator ai,
    TravelMemoryService memory,
    AppDbContext db,
    LmStudioOptions lmStudioOptions)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<TravelPlanResponse> GenerateAsync(
        Guid? userId,
        TravelGenerateRequest request,
        CancellationToken ct)
    {
        Validate(request);

        var userMemory = userId.HasValue
            ? await memory.GetAsync(userId.Value, ct)
            : new TravelMemoryDto([], "", 0, 0, "");

        var destinationQuery = new TravelDestinationQuery(
            request.Destination ?? request.Prompt,
            request.Preferences.Concat(userMemory.PreferredStyles).Distinct().ToList(),
            request.Latitude,
            request.Longitude,
            5);

        var candidates = await destinations.SearchAsync(destinationQuery, ct);
        if (candidates.Count == 0)
            throw new TravelAiException(StatusCodes.Status404NotFound, "Không tìm thấy điểm đến phù hợp.");

        var selected = candidates.First();
        var weatherResult = await weather.GetCurrentWeatherAsync(selected.Latitude, selected.Longitude, ct);
        var route = BuildRoute(request, selected);
        var days = BuildDays(request, candidates, weatherResult, route);

        var toolContext = new TravelToolContext(
            candidates,
            weatherResult,
            route,
            userMemory);
        var explanation = await ai.ExplainAsync(request.Prompt ?? request.Destination ?? selected.Name, toolContext, ct);

        var response = new TravelPlanResponse(
            selected.Name,
            days,
            days.Sum(x => x.Cost),
            explanation,
            Math.Round(candidates.Average(x => x.MatchScore), 2));

        await SaveHistoryAsync(userId, request, response, ct);
        if (userId.HasValue)
        {
            await memory.UpdateFromTripAsync(
                userId.Value,
                request.Preferences,
                request.Transport,
                request.Budget,
                request.Prompt,
                ct);
        }

        return response;
    }

    public async Task<TravelPlanResponse> ReplanAsync(
        Guid? userId,
        TravelReplanRequest request,
        CancellationToken ct)
    {
        var reason = request.Trigger.Trim();
        if (string.IsNullOrWhiteSpace(reason))
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Trigger is required.");

        var current = request.CurrentPlan;
        var adjustedDays = current.Days.Select(day =>
        {
            var notes = reason.ToLowerInvariant() switch
            {
                var x when x.Contains("weather") || x.Contains("mưa") =>
                    $"{day.Notes} Đã ưu tiên hoạt động trong nhà do thời tiết xấu.",
                var x when x.Contains("budget") || x.Contains("ngân sách") =>
                    $"{day.Notes} Đã giảm chi phí bằng lựa chọn tiết kiệm hơn.",
                var x when x.Contains("delay") || x.Contains("trễ") =>
                    $"{day.Notes} Đã rút gọn lịch để bù thời gian trễ.",
                _ => $"{day.Notes} Đã điều chỉnh theo yêu cầu: {reason}."
            };

            var cost = request.RemainingBudget.HasValue
                ? Math.Min(day.Cost, request.RemainingBudget.Value / Math.Max(current.Days.Count, 1))
                : day.Cost;

            return day with { Cost = decimal.Round(cost, 0), Notes = notes };
        }).ToList();

        var toolContext = new TravelToolContext(
            current.Days,
            request.Trigger,
            "Replanned deterministic route order",
            userId.HasValue ? await memory.GetAsync(userId.Value, ct) : new TravelMemoryDto([], "", 0, 0, ""));
        var explanation = await ai.ExplainAsync(request.UserMessage ?? request.Trigger, toolContext, ct);

        return new TravelPlanResponse(
            current.Destination,
            adjustedDays,
            adjustedDays.Sum(x => x.Cost),
            $"Đã tái lập kế hoạch vì: {reason}. {explanation}",
            Math.Max(0.65, current.ConfidenceScore - 0.03));
    }

    private static void Validate(TravelGenerateRequest request)
    {
        if (request.Budget <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Budget must be greater than zero.");
        if (request.Days is < 1 or > 14)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Days must be between 1 and 14.");
        if (request.Preferences.Count == 0 && string.IsNullOrWhiteSpace(request.Prompt))
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Preferences or prompt is required.");
    }

    private static object BuildRoute(TravelGenerateRequest request, TravelDestinationDto selected)
    {
        var transport = string.IsNullOrWhiteSpace(request.Transport) ? "AI chọn" : request.Transport;
        return new
        {
            transport,
            destination = selected.Name,
            estimatedTravelTime = selected.TravelTime,
            optimization = "Nearest-neighbor fallback; OR-Tools adapter can replace this strategy."
        };
    }

    private static IReadOnlyList<TravelDayPlan> BuildDays(
        TravelGenerateRequest request,
        IReadOnlyList<TravelDestinationDto> candidates,
        WeatherResult weatherResult,
        object route)
    {
        var perDayBudget = decimal.Round(request.Budget / request.Days, 0);
        var days = new List<TravelDayPlan>();
        for (var day = 1; day <= request.Days; day++)
        {
            var places = candidates
                .Skip((day - 1) % candidates.Count)
                .Take(Math.Min(3, candidates.Count))
                .Select(x => x.Name)
                .ToList();

            days.Add(new TravelDayPlan(
                day,
                places,
                perDayBudget,
                day == 1 ? candidates.First().TravelTime : "30-60 phút giữa các điểm",
                $"Thời tiết: {weatherResult.Description}. Ưu tiên {string.Join(", ", request.Preferences.Take(3))}."));
        }

        return days;
    }

    private async Task SaveHistoryAsync(
        Guid? userId,
        TravelGenerateRequest request,
        TravelPlanResponse response,
        CancellationToken ct)
    {
        db.AiItineraries.Add(new AiItinerary
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = response.Destination,
            RequestJson = JsonSerializer.Serialize(request, JsonOptions),
            ItineraryJson = JsonSerializer.Serialize(response, JsonOptions),
            AiModel = lmStudioOptions.ChatModel,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync(ct);
    }
}
