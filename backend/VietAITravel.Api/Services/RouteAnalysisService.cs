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

public sealed class RouteAnalysisService(
    AppDbContext db,
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

    private async Task<List<TransportOptionResponse>> BuildTransportOptionsAsync(
        RoutePlaceDto from,
        RoutePlaceDto to,
        double distanceKm,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        var fromAirport = await NearestHubAsync(from, "airport", transportRules.AirportSearchRadiusKm, ct);
        var toAirport = await NearestHubAsync(to, "airport", transportRules.AirportSearchRadiusKm, ct);
        var fromRail = await NearestHubAsync(from, "train_station", transportRules.RailSearchRadiusKm, ct);
        var toRail = await NearestHubAsync(to, "train_station", transportRules.RailSearchRadiusKm, ct);
        var fromPort = await NearestHubAsync(from, "ferry_port", transportRules.FerryPortSearchRadiusKm, ct);
        var toPort = await NearestHubAsync(to, "ferry_port", transportRules.FerryPortSearchRadiusKm, ct);

        var isCrossing = IsIsland(from.Name) != IsIsland(to.Name);
        var roadAvailable = !isCrossing;
        var roadReason = isCrossing ? "Không thể đi đường bộ trực tiếp ra đảo (phải dùng kết hợp Xe & Phà hoặc Máy bay)." : "Road transport is available for this leg.";

        var options = new List<TransportOptionResponse>
        {
            new("car", roadAvailable, roadReason, DurationForModeHours(distanceKm, "car"), CostForMode(distanceKm, "car")),
            new("motorbike", roadAvailable && distanceKm <= 180, roadAvailable ? (distanceKm <= 180 ? "Suitable for a short road leg." : "Not recommended for a long road leg.") : roadReason, DurationForModeHours(distanceKm, "motorbike"), CostForMode(distanceKm, "motorbike")),
            new("coach", roadAvailable && distanceKm >= 40, roadAvailable ? (distanceKm >= 40 ? "Coach is suitable for intercity road travel." : "Leg is too short for coach to be practical.") : roadReason, DurationForModeHours(distanceKm, "coach"), CostForMode(distanceKm, "coach"))
        };

        var trainRoute = fromRail is null || toRail is null
            ? null
            : await FindRouteAsync(fromRail.Id, toRail.Id, "train", ct);
        options.Add(trainRoute is null || isCrossing
            ? new("train", false, isCrossing ? roadReason : "Train is unavailable because no active rail hubs/routes match both endpoints.", DurationForModeHours(distanceKm, "train"), CostForMode(distanceKm, "train"))
            : new("train", true, $"Train route available via {fromRail!.Name} -> {toRail!.Name}.", trainRoute.EstimatedDurationHours, (double)trainRoute.EstimatedCostVnd));

        var flightOption = await BuildFlightOptionAsync(from, to, distanceKm, fromAirport, toAirport, transportRules, ct);
        options.Add(flightOption);

        var ferryRoute = fromPort is null || toPort is null
            ? null
            : await FindRouteAsync(fromPort.Id, toPort.Id, "ferry", ct);
            
        if (fromPort is null || toPort is null || ferryRoute is null)
        {
            options.Add(new("ferry", false, "Ferry is unavailable because no active ferry hubs/routes match both endpoints.", DurationForModeHours(distanceKm, "ferry"), CostForMode(distanceKm, "ferry")));
        }
        else
        {
            var roadToPortKm = EstimateDistance(from, ToPlace(fromPort)).DistanceKm;
            var portToDestKm = EstimateDistance(ToPlace(toPort), to).DistanceKm;

            var roadMode = roadToPortKm > 40 ? "coach" : "car";
            var destRoadMode = portToDestKm > 40 ? "coach" : "car";

            var roadDuration = DurationForModeHours(roadToPortKm, roadMode);
            var roadCost = CostForMode(roadToPortKm, roadMode);

            var destDuration = DurationForModeHours(portToDestKm, destRoadMode);
            var destCost = CostForMode(portToDestKm, destRoadMode);

            var totalDuration = roadDuration + ferryRoute.EstimatedDurationHours + destDuration;
            var totalCost = roadCost + (double)ferryRoute.EstimatedCostVnd + destCost;

            var reason = $"Tuyến phà qua {fromPort.Name} -> {toPort.Name}. Đã cộng chi phí đi {roadMode} ra bến tàu.";
            
            var segments = new List<string>
            {
                $"{from.Name} -> {fromPort.Name} ({roadMode})",
                $"{fromPort.Name} -> {toPort.Name} (ferry)",
                $"{toPort.Name} -> {to.Name} ({destRoadMode})"
            };

            options.Add(new("ferry", true, reason, totalDuration, totalCost, Segments: segments));
        }

        return options;
    }

    private async Task<TransportOptionResponse> BuildFlightOptionAsync(
        RoutePlaceDto from,
        RoutePlaceDto to,
        double distanceKm,
        TransportHub? fromAirport,
        TransportHub? toAirport,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        if (fromAirport is null || toAirport is null)
        {
            return new(
                "flight",
                false,
                "Flight is unavailable because origin or destination has no active airport inside the configured search radius.",
                FlightDurationHours(distanceKm, 0, 0),
                FlightFareEstimateVnd(distanceKm),
                Segments: [$"{from.Name} -> airport lookup failed", "flight unavailable", $"airport lookup failed -> {to.Name}"]);
        }

        var airportDistance = EstimateDistance(ToPlace(fromAirport), ToPlace(toAirport)).DistanceKm;
        var airportRoute = await FindRouteAsync(fromAirport.Id, toAirport.Id, "flight", ct);
        var originTransferKm = EstimateDistance(from, ToPlace(fromAirport)).DistanceKm;
        var destinationTransferKm = EstimateDistance(ToPlace(toAirport), to).DistanceKm;
        var duration = FlightDurationHours(
            airportDistance,
            DurationForModeHours(originTransferKm, "car"),
            DurationForModeHours(destinationTransferKm, "car"));
        var cost = CostForMode(originTransferKm, "car") +
                   (double)(airportRoute?.EstimatedCostVnd ?? (decimal)FlightFareEstimateVnd(airportDistance)) +
                   CostForMode(destinationTransferKm, "car");

        if (distanceKm < transportRules.ShortFlightDistanceKm)
        {
            return new(
                "flight",
                true,
                "Khong khuyen nghi: chang ngan, nhung hai dau co san bay phu hop.",
                duration,
                cost,
                Segments: [$"{from.Name} -> {fromAirport.Name}", $"{fromAirport.Name} -> {toAirport.Name}", $"{toAirport.Name} -> {to.Name}"]);
        }

        var reason = distanceKm < transportRules.RecommendedFlightDistanceKm
            ? "Khong khuyen nghi: chang chua du dai de uu tien may bay, nhung hai dau co san bay phu hop."
            : $"Flight is available via {fromAirport.Name} -> {toAirport.Name}.";

        return new(
            "flight",
            true,
            reason,
            duration,
            cost,
            Segments: [$"{from.Name} -> {fromAirport.Name}", $"{fromAirport.Name} -> {toAirport.Name}", $"{toAirport.Name} -> {to.Name}"]);
    }

    private string ChooseRecommendedMode(
        IReadOnlyCollection<TransportOptionResponse> options,
        double distanceKm,
        RoutePlaceDto from,
        RoutePlaceDto to,
        TransportConfigValues transportRules)
    {
        var isCrossing = IsIsland(from.Name) != IsIsland(to.Name);

        if (distanceKm > transportRules.RecommendedFlightDistanceKm && options.Any(x => x.Mode == "flight" && x.IsAvailable)) return "flight";
        
        if (isCrossing && options.Any(x => x.Mode == "ferry" && x.IsAvailable)) return "ferry";

        if (distanceKm is >= 150 and <= 700 && options.Any(x => x.Mode == "train" && x.IsAvailable)) return "train";
        
        if (distanceKm < 150 && string.Equals(from.Region, to.Region, StringComparison.OrdinalIgnoreCase) && options.Any(x => x.Mode == "motorbike" && x.IsAvailable)) return "motorbike";
        
        if (distanceKm < 150 && options.Any(x => x.Mode == "car" && x.IsAvailable)) return "car";
        
        if (options.Any(x => x.Mode == "coach" && x.IsAvailable)) return "coach";

        return options.FirstOrDefault(x => x.IsAvailable)?.Mode ?? "coach";
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

    private static List<TransportOptionResponse> MarkRecommended(
        IEnumerable<TransportOptionResponse> options,
        string recommendedMode,
        RoutePlaceDto from,
        RoutePlaceDto to)
    {
        return options
            .Select(option =>
            {
                var isRecommended = option.Mode == recommendedMode;
                return option with
                {
                    IsRecommended = isRecommended,
                    Segments = option.Segments ?? [$"{from.Name} -> {to.Name}"],
                    AiScore = ScoreOption(option, isRecommended),
                    Pros = option.Pros ?? ProsForMode(option.Mode),
                    Cons = option.Cons ?? ConsForMode(option.Mode, option.IsAvailable)
                };
            })
            .OrderByDescending(x => x.IsRecommended)
            .ThenByDescending(x => x.IsAvailable)
            .ThenByDescending(x => x.AiScore)
            .ToList();
    }

    private static double ScoreOption(TransportOptionResponse option, bool isRecommended)
    {
        if (!option.IsAvailable) return 0;
        var baseScore = option.Mode switch
        {
            "flight" => 0.86,
            "train" => 0.78,
            "car" => 0.72,
            "coach" => 0.68,
            "motorbike" => 0.62,
            "ferry" => 0.58,
            _ => 0.5
        };
        return Math.Round(Math.Min(1, baseScore + (isRecommended ? 0.1 : 0)), 2);
    }

    private static List<string> ProsForMode(string mode) =>
        mode switch
        {
            "flight" => ["Fast for long distance", "Multi-modal airport transfer is explicit"],
            "train" => ["Stable schedule", "Comfortable for medium distance"],
            "car" => ["Door-to-door flexibility", "Good for short legs"],
            "coach" => ["Lower cost", "Available on many road routes"],
            "motorbike" => ["Flexible for short local legs", "Low cost"],
            "ferry" => ["Required for water/island segments", "Direct hub-based route"],
            _ => []
        };

    private static List<string> ConsForMode(string mode, bool isAvailable)
    {
        if (!isAvailable) return ["Unavailable from current backend hub/route data"];
        return mode switch
        {
            "flight" => ["Needs airport transfers and waiting time"],
            "train" => ["Requires suitable railway hubs"],
            "car" => ["Cost increases with distance"],
            "coach" => ["Can be affected by road traffic"],
            "motorbike" => ["Not suitable for long distance"],
            "ferry" => ["Depends on ferry/speedboat schedule"],
            _ => []
        };
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

    private static RoutePlaceDto ToPlace(TransportHub hub) =>
        new(hub.Code, hub.Name, hub.Region, hub.Latitude, hub.Longitude);

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

    private static double DurationForModeHours(double distanceKm, string mode)
    {
        return mode switch
        {
            "motorbike" => distanceKm / 45,
            "car" => distanceKm / 65,
            "coach" => distanceKm / 60,
            "train" => distanceKm / 55,
            "ferry" => 1.0 + distanceKm / 35,
            "flight" => FlightDurationHours(distanceKm, 0, 0),
            _ => distanceKm / 60
        };
    }

    private static double FlightDurationHours(double flightDistanceKm, double originTransferHours, double destinationTransferHours) =>
        originTransferHours + 1.5 + flightDistanceKm / 650 + 0.5 + destinationTransferHours;

    private static double CostForMode(double distanceKm, string mode)
    {
        return mode switch
        {
            "motorbike" => Math.Max(25000, distanceKm * 900),
            "car" => Math.Max(90000, distanceKm * 11500),
            "coach" => Math.Max(120000, distanceKm * 850),
            "train" => Math.Max(160000, distanceKm * 950),
            "ferry" => Math.Max(185000, distanceKm * 1800),
            "flight" => FlightFareEstimateVnd(distanceKm),
            _ => Math.Max(120000, distanceKm * 1000)
        };
    }

    private static double FlightFareEstimateVnd(double distanceKm)
    {
        if (distanceKm < 300) return 1200000;
        if (distanceKm < 700) return 1800000;
        if (distanceKm < 1200) return 2500000;
        return 3500000;
    }

    private static bool SamePlace(RoutePlaceDto a, RoutePlaceDto b) =>
        string.Equals(a.Id, b.Id, StringComparison.OrdinalIgnoreCase) ||
        EstimateDistance(a, b).DistanceKm < 8;

    private sealed record RouteDistance(double DistanceKm, bool IsGoogleEstimate);

    private sealed record TransportConfigValues(
        double AirportSearchRadiusKm,
        double RecommendedFlightDistanceKm,
        double ShortFlightDistanceKm,
        double RailSearchRadiusKm,
        double FerryPortSearchRadiusKm);
}
