using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Services.TravelCompanion;

public sealed class OpenTripMapOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://api.opentripmap.com";
}

public sealed class DestinationDiscoveryService(
    HttpClient http,
    AppDbContext db,
    OpenTripMapOptions options,
    WeatherService weatherService,
    ILogger<DestinationDiscoveryService> logger)
{
    public async Task<IReadOnlyList<TravelDestinationDto>> SearchAsync(
        TravelDestinationQuery query,
        CancellationToken ct)
    {
        var limit = Math.Clamp(query.Limit, 1, 10);
        if (!string.IsNullOrWhiteSpace(options.ApiKey) &&
            query.Latitude.HasValue &&
            query.Longitude.HasValue)
        {
            var remote = await TryOpenTripMapAsync(query, limit, ct);
            if (remote.Count > 0) return remote;
        }

        return await LocalFallbackAsync(query, limit, ct);
    }

    private async Task<IReadOnlyList<TravelDestinationDto>> TryOpenTripMapAsync(
        TravelDestinationQuery query,
        int limit,
        CancellationToken ct)
    {
        try
        {
            var radius = 50000;
            var url = $"{options.BaseUrl.TrimEnd('/')}/0.1/en/places/radius" +
                      $"?radius={radius}&lon={query.Longitude}&lat={query.Latitude}" +
                      $"&limit={limit}&format=json&apikey={Uri.EscapeDataString(options.ApiKey)}";

            var items = await http.GetFromJsonAsync<List<OpenTripMapPlace>>(url, ct) ?? [];
            var weather = await weatherService.GetCurrentWeatherAsync(query.Latitude!.Value, query.Longitude!.Value, ct);
            return items
                .Where(x => !string.IsNullOrWhiteSpace(x.Name))
                .Select((x, index) => new TravelDestinationDto(
                    x.Xid ?? $"opentripmap-{index}",
                    x.Name!,
                    x.Kinds ?? "place",
                    x.Point?.Lat ?? query.Latitude.Value,
                    x.Point?.Lon ?? query.Longitude.Value,
                    Score(x.Name!, x.Kinds, query.Preferences),
                    300000 + index * 100000,
                    weather.Description,
                    $"{20 + index * 10} phút",
                    $"Phù hợp với {string.Join(", ", query.Preferences ?? [])}; có dữ liệu thực tế từ OpenTripMap."))
                .OrderByDescending(x => x.MatchScore)
                .Take(limit)
                .ToList();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "OpenTripMap failed, using local destinations");
            return [];
        }
    }

    private async Task<IReadOnlyList<TravelDestinationDto>> LocalFallbackAsync(
        TravelDestinationQuery query,
        int limit,
        CancellationToken ct)
    {
        var dbQuery = db.Destinations.AsNoTracking().Where(x => x.IsActive);
        if (!string.IsNullOrWhiteSpace(query.Query))
        {
            var q = query.Query.ToLower();
            dbQuery = dbQuery.Where(x =>
                x.Name.ToLower().Contains(q) ||
                x.Province.ToLower().Contains(q) ||
                x.Category.ToLower().Contains(q));
        }

        var items = await dbQuery.Take(30).ToListAsync(ct);
        var weather = query.Latitude.HasValue && query.Longitude.HasValue
            ? await weatherService.GetCurrentWeatherAsync(query.Latitude.Value, query.Longitude.Value, ct)
            : new WeatherResult(26, "Thời tiết ổn định", null, null);

        return items
            .Select(x => new TravelDestinationDto(
                x.Id.ToString(),
                x.Name,
                x.Category,
                (double)x.Latitude,
                (double)x.Longitude,
                Score($"{x.Name} {x.Category} {x.TravelStyle}", x.Category, query.Preferences),
                x.EstimatedCost,
                weather.Description,
                "Ước tính sau khi tối ưu tuyến",
                x.AiRecommendationNote ?? $"Phù hợp với {string.Join(", ", query.Preferences ?? [])}."))
            .OrderByDescending(x => x.MatchScore)
            .Take(limit)
            .ToList();
    }

    private static double Score(string text, string? kinds, IReadOnlyList<string>? preferences)
    {
        if (preferences == null || preferences.Count == 0) return 0.72;
        var haystack = $"{text} {kinds}".ToLowerInvariant();
        var hits = preferences.Count(x => haystack.Contains(x.ToLowerInvariant()));
        return Math.Round(Math.Clamp(0.65 + hits * 0.1, 0.65, 0.96), 2);
    }

    private sealed class OpenTripMapPlace
    {
        [JsonPropertyName("xid")]
        public string? Xid { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("kinds")]
        public string? Kinds { get; set; }

        [JsonPropertyName("point")]
        public OpenTripMapPoint? Point { get; set; }
    }

    private sealed class OpenTripMapPoint
    {
        [JsonPropertyName("lat")]
        public double Lat { get; set; }

        [JsonPropertyName("lon")]
        public double Lon { get; set; }
    }
}
