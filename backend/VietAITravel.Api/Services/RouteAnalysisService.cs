using System.Text.Json;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Services;

public sealed class GoogleMapsOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://maps.googleapis.com";
}

public sealed class RouteAnalysisService(
    GoogleMapsOptions googleMapsOptions,
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

        var legs = new List<RouteLegResponse>();
        var current = request.Departure;

        for (var i = 0; i < request.Destinations.Count; i++)
        {
            var next = request.Destinations[i];
            var estimate = await TryGetGoogleDistanceAsync(current, next, ct)
                ?? EstimateDistance(current, next);
            var mode = RecommendMode(estimate.DistanceKm, current.Region, next.Region);

            legs.Add(new RouteLegResponse(
                i + 1,
                current.Name,
                next,
                Math.Round(estimate.DistanceKm, 1),
                Math.Round(DurationForModeHours(estimate.DistanceKm, mode), 1),
                mode,
                Reason(estimate.DistanceKm, current.Region, next.Region),
                estimate.IsGoogleEstimate));

            current = next;
        }

        var totalDistance = legs.Sum(x => x.DistanceKm);
        var optimizedHours = legs.Sum(x => x.DurationHours);

        return new AnalyzeRouteResponse(
            request.Departure,
            request.Destinations,
            legs,
            Math.Round(totalDistance, 1),
            Math.Round(optimizedHours, 1),
            legs.Any(x => x.RecommendedMode == "flight"));
    }

    private async Task<RouteDistance?> TryGetGoogleDistanceAsync(
        RoutePlaceDto from,
        RoutePlaceDto to,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(googleMapsOptions.ApiKey))
            return null;

        try
        {
            var path = $"{googleMapsOptions.BaseUrl.TrimEnd('/')}/maps/api/distancematrix/json" +
                       $"?origins={from.Latitude.ToString(System.Globalization.CultureInfo.InvariantCulture)},{from.Longitude.ToString(System.Globalization.CultureInfo.InvariantCulture)}" +
                       $"&destinations={to.Latitude.ToString(System.Globalization.CultureInfo.InvariantCulture)},{to.Longitude.ToString(System.Globalization.CultureInfo.InvariantCulture)}" +
                       "&mode=driving&units=metric" +
                       $"&key={Uri.EscapeDataString(googleMapsOptions.ApiKey)}";

            using var response = await GoogleClient.GetAsync(path, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Google Distance Matrix failed: {StatusCode} {Body}", response.StatusCode, body);
                return null;
            }

            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;
            if (root.GetProperty("status").GetString() != "OK")
            {
                logger.LogWarning("Google Distance Matrix status was not OK: {Body}", body);
                return null;
            }

            var element = root
                .GetProperty("rows")[0]
                .GetProperty("elements")[0];
            if (element.GetProperty("status").GetString() != "OK")
                return null;

            var meters = element.GetProperty("distance").GetProperty("value").GetDouble();
            return new RouteDistance(meters / 1000, true);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Google Distance Matrix request failed, using fallback distance");
            return null;
        }
    }

    private static RouteDistance EstimateDistance(RoutePlaceDto from, RoutePlaceDto to)
    {
        const double earthRadiusKm = 6371;
        var dLat = ToRadians(to.Latitude - from.Latitude);
        var dLon = ToRadians(to.Longitude - from.Longitude);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(from.Latitude)) *
                Math.Cos(ToRadians(to.Latitude)) *
                Math.Sin(dLon / 2) *
                Math.Sin(dLon / 2);
        var distance = earthRadiusKm * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return new RouteDistance(distance, false);
    }

    private static double ToRadians(double degree) => degree * Math.PI / 180;

    private static string RecommendMode(double distanceKm, string fromRegion, string toRegion)
    {
        if (distanceKm < 150 && fromRegion == toRegion) return "motorbike";
        if (distanceKm < 150) return "car";
        if (distanceKm <= 500) return "train";
        return "flight";
    }

    private static double DurationForModeHours(double distanceKm, string mode)
    {
        return mode switch
        {
            "motorbike" => distanceKm / 45,
            "car" => distanceKm / 65,
            "train" => distanceKm / 55,
            "flight" => 2.5 + distanceKm / 650,
            _ => distanceKm / 60
        };
    }

    private static string Reason(double distanceKm, string fromRegion, string toRegion)
    {
        if (distanceKm < 150) return "Chặng ngắn, linh hoạt đi xe máy hoặc ô tô.";
        if (distanceKm <= 500) return "Chặng trung bình, ưu tiên ô tô khách hoặc tàu hỏa.";
        if (!string.Equals(fromRegion, toRegion, StringComparison.OrdinalIgnoreCase))
            return "Di chuyển liên miền, máy bay tiết kiệm thời gian.";
        return "Khoảng cách dài, nên ưu tiên máy bay nếu ngân sách phù hợp.";
    }

    private sealed record RouteDistance(double DistanceKm, bool IsGoogleEstimate);
}
