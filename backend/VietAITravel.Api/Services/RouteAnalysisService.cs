using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services;

public sealed class GoogleMapsOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://maps.googleapis.com";
}

public sealed partial class RouteAnalysisService(
    AppDbContext db,
    GoogleMapsOptions googleMapsOptions,
    VietAITravel.Api.Services.GroqOptions groqOptions,
    IHttpClientFactory httpClientFactory,
    ILogger<RouteAnalysisService> logger)
{
    private static readonly HttpClient GoogleClient = new()
    {
        Timeout = TimeSpan.FromSeconds(20)
    };


    public async Task<AnalyzeRouteResponse> AnalyzeAsync(AnalyzeRouteRequest request, CancellationToken ct)
    {
        if (request.Destinations.Count == 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "At least one destination is required.");

        var transportRules = await LoadTransportConfigAsync(ct);
        var legs = new List<RouteLegResponse>();
        var current = request.Departure;
        var order = 1;

        foreach (var next in request.Destinations)
        {
            var expanded = await BuildFeasibleLegsAsync(order, current, next, transportRules, ct);
            legs.AddRange(expanded);
            order += expanded.Count;
            current = next;
        }

        return new AnalyzeRouteResponse(
            request.Departure,
            request.Destinations,
            legs,
            Math.Round(legs.Sum(x => x.DistanceKm), 1),
            Math.Round(legs.Sum(x => x.DurationHours), 1),
            legs.Any(x => x.RecommendedMode == "flight"));
    }

    private async Task<List<RouteLegResponse>> BuildFeasibleLegsAsync(
        int orderStart,
        RoutePlaceDto from,
        RoutePlaceDto to,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        return [await BuildAutoLegAsync(orderStart, from, to, transportRules, ct)];
    }

    private Task<RouteLegResponse> BuildGroundLegAsync(
        int order,
        RoutePlaceDto from,
        RoutePlaceDto to,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        return BuildAutoLegAsync(order, from, to, transportRules, ct, groundOnly: true);
    }

    private async Task<RouteLegResponse> BuildAutoLegAsync(
        int order,
        RoutePlaceDto from,
        RoutePlaceDto to,
        TransportConfigValues transportRules,
        CancellationToken ct,
        bool groundOnly = false)
    {
        var estimate = await TryGetGoogleDistanceAsync(from, to, ct)
            ?? EstimateDistance(from, to);
        var options = await BuildTransportOptionsAsync(from, to, estimate.DistanceKm, transportRules, ct);
        if (groundOnly)
        {
            options = options.Where(x => x.Mode is not "flight" and not "ferry").ToList();
        }

        var recommended = ChooseRecommendedMode(options, estimate.DistanceKm, from, to, transportRules);
        var selected = options.FirstOrDefault(x => x.Mode == recommended) ??
                       options.First(x => x.IsAvailable);
        options = MarkRecommended(options, selected.Mode, from, to);

        return new RouteLegResponse(
            order,
            from.Name,
            to,
            Math.Round(estimate.DistanceKm, 1),
            Math.Round(selected.DurationHours, 1),
            selected.Mode,
            selected.Reason,
            estimate.IsGoogleEstimate,
            Math.Round(selected.EstimatedCostVnd, 0),
            options);
    }

    private async Task<RouteLegResponse> BuildManualLegAsync(
        int order,
        RoutePlaceDto from,
        RoutePlaceDto to,
        string mode,
        string reason,
        double durationHours,
        double estimatedCostVnd,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        var estimate = EstimateDistance(from, to);
        var options = await BuildTransportOptionsAsync(from, to, estimate.DistanceKm, transportRules, ct);
        if (options.All(x => x.Mode != mode))
        {
            options.Add(new TransportOptionResponse(mode, true, reason, durationHours, estimatedCostVnd));
        }
        options = MarkRecommended(options, mode, from, to);

        return new RouteLegResponse(
            order,
            from.Name,
            to,
            Math.Round(estimate.DistanceKm, 1),
            Math.Round(durationHours, 1),
            mode,
            reason,
            false,
            Math.Round(estimatedCostVnd, 0),
            options);
    }

    private static bool IsIsland(string placeName)
    {
        var lower = placeName.ToLowerInvariant();
        return lower.Contains("phú quốc") || lower.Contains("phu quoc") ||
               lower.Contains("côn đảo") || lower.Contains("con dao") ||
               lower.Contains("nam du") ||
               lower.Contains("lý sơn") || lower.Contains("ly son") ||
               lower.Contains("phú quý") || lower.Contains("phu quy") ||
               lower.Contains("cô tô") || lower.Contains("co to") ||
               lower.Contains("cát bà") || lower.Contains("cat ba");
    }


    private async Task<TransportHub?> NearestHubAsync(
        RoutePlaceDto place,
        string type,
        double radiusKm,
        CancellationToken ct)
    {
        var hubs = await db.TransportHubs
            .AsNoTracking()
            .Where(x => x.IsActive && x.Type == type)
            .ToListAsync(ct);

        return hubs
            .Select(hub => new { Hub = hub, Distance = EstimateDistance(place, ToPlace(hub)).DistanceKm })
            .Where(x => x.Distance <= radiusKm)
            .OrderBy(x => x.Distance)
            .Select(x => x.Hub)
            .FirstOrDefault();
    }

    private Task<TransportRoute?> FindRouteAsync(
        Guid originHubId,
        Guid destinationHubId,
        string transportType,
        CancellationToken ct)
    {
        return db.TransportRoutes
            .AsNoTracking()
            .Where(x => x.IsActive &&
                        x.TransportType == transportType &&
                        ((x.OriginHubId == originHubId && x.DestinationHubId == destinationHubId) ||
                         (x.OriginHubId == destinationHubId && x.DestinationHubId == originHubId)))
            .OrderBy(x => x.EstimatedDurationHours)
            .FirstOrDefaultAsync(ct);
    }

    private async Task<TransportConfigValues> LoadTransportConfigAsync(CancellationToken ct)
    {
        var values = await db.TransportConfigs
            .AsNoTracking()
            .Where(x => x.IsActive)
            .ToDictionaryAsync(x => x.Key, x => x.Value, StringComparer.OrdinalIgnoreCase, ct);

        return new TransportConfigValues(
            ReadRequiredDouble(values, "airportSearchRadiusKm"),
            ReadRequiredDouble(values, "recommendedFlightDistanceKm"),
            ReadRequiredDouble(values, "shortFlightDistanceKm"),
            ReadRequiredDouble(values, "railSearchRadiusKm"),
            ReadRequiredDouble(values, "ferryPortSearchRadiusKm"));
    }

    private static double ReadRequiredDouble(IReadOnlyDictionary<string, string> values, string key)
    {
        if (values.TryGetValue(key, out var raw) &&
            double.TryParse(raw, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var value))
        {
            return value;
        }

        throw new TravelAiException(StatusCodes.Status500InternalServerError, $"Missing or invalid transport config: {key}");
    }

    private sealed record RouteDistance(double DistanceKm, bool IsGoogleEstimate);

    private sealed record TransportConfigValues(
        double AirportSearchRadiusKm,
        double RecommendedFlightDistanceKm,
        double ShortFlightDistanceKm,
        double RailSearchRadiusKm,
        double FerryPortSearchRadiusKm);
}
