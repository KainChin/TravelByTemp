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

    private static readonly string[] AirportNames =
    [
        "ha noi", "ho chi minh", "tp.hcm", "da nang", "hue", "nha trang",
        "da lat", "phu quoc", "con dao", "quy nhon", "can tho", "vinh"
    ];

    private static readonly string[] RailNames =
    [
        "ha noi", "vinh", "hue", "da nang", "nha trang", "quy nhon", "ho chi minh", "tp.hcm"
    ];

    public async Task<AnalyzeRouteResponse> AnalyzeAsync(AnalyzeRouteRequest request, CancellationToken ct)
    {
        if (request.Destinations.Count == 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "At least one destination is required.");

        var legs = new List<RouteLegResponse>();
        var current = request.Departure;
        var order = 1;

        foreach (var next in request.Destinations)
        {
            var expanded = await BuildFeasibleLegsAsync(order, current, next, request.BudgetPerPerson, ct);
            legs.AddRange(expanded);
            order += expanded.Count;
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

    private async Task<List<RouteLegResponse>> BuildFeasibleLegsAsync(
        int orderStart,
        RoutePlaceDto from,
        RoutePlaceDto to,
        decimal? budgetPerPerson,
        CancellationToken ct)
    {
        var fromIsland = IsIsland(from);
        var toIsland = IsIsland(to);

        if (!fromIsland && toIsland)
        {
            if (HasDirectIslandFlight(from, to))
            {
                return
                [
                    BuildManualLeg(
                        orderStart,
                        from,
                        to,
                        "flight",
                        "Hai điểm có tuyến bay phù hợp, máy bay là phương án khả thi và nhanh nhất.")
                ];
            }

            if (PrefersFastIslandRoute(budgetPerPerson) && HasAirport(to))
            {
                var airport = NearestAirportForIslandRoute(from, to);
                return
                [
                    await BuildAutoLegAsync(orderStart, from, airport, ct),
                    BuildManualLeg(
                        orderStart + 1,
                        airport,
                        to,
                        "flight",
                        "Điểm đến là đảo, đi qua sân bay gần nhất rồi bay để tiết kiệm thời gian.")
                ];
            }

            var port = MainlandPortForIsland(to);
            return
            [
                await BuildAutoLegAsync(orderStart, from, port, ct),
                BuildManualLeg(
                    orderStart + 1,
                    port,
                    to,
                    "ferry",
                    "Điểm đến là đảo, cần đi phà hoặc tàu cao tốc từ cảng đất liền.")
            ];
        }

        if (fromIsland && !toIsland)
        {
            if (HasDirectIslandFlight(to, from))
            {
                return
                [
                    BuildManualLeg(
                        orderStart,
                        from,
                        to,
                        "flight",
                        "Hai điểm có tuyến bay phù hợp, máy bay là phương án khả thi và nhanh nhất.")
                ];
            }

            if (PrefersFastIslandRoute(budgetPerPerson) && HasAirport(from))
            {
                var airport = NearestAirportForIslandRoute(to, from);
                return
                [
                    BuildManualLeg(
                        orderStart,
                        from,
                        airport,
                        "flight",
                        "Rời đảo bằng máy bay để tiết kiệm thời gian."),
                    await BuildAutoLegAsync(orderStart + 1, airport, to, ct)
                ];
            }

            var port = MainlandPortForIsland(from);
            return
            [
                BuildManualLeg(
                    orderStart,
                    from,
                    port,
                    "ferry",
                    "Rời đảo bằng phà hoặc tàu cao tốc về cảng đất liền."),
                await BuildAutoLegAsync(orderStart + 1, port, to, ct)
            ];
        }

        return [await BuildAutoLegAsync(orderStart, from, to, ct)];
    }

    private async Task<RouteLegResponse> BuildAutoLegAsync(
        int order,
        RoutePlaceDto from,
        RoutePlaceDto to,
        CancellationToken ct)
    {
        var estimate = await TryGetGoogleDistanceAsync(from, to, ct)
            ?? EstimateDistance(from, to);
        var mode = RecommendMode(estimate.DistanceKm, from, to);

        return new RouteLegResponse(
            order,
            from.Name,
            to,
            Math.Round(estimate.DistanceKm, 1),
            Math.Round(DurationForModeHours(estimate.DistanceKm, mode), 1),
            mode,
            Reason(mode),
            estimate.IsGoogleEstimate);
    }

    private static RouteLegResponse BuildManualLeg(
        int order,
        RoutePlaceDto from,
        RoutePlaceDto to,
        string mode,
        string reason)
    {
        var estimate = EstimateDistance(from, to);
        return new RouteLegResponse(
            order,
            from.Name,
            to,
            Math.Round(estimate.DistanceKm, 1),
            Math.Round(DurationForModeHours(estimate.DistanceKm, mode), 1),
            mode,
            reason,
            false);
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

    private static string RecommendMode(double distanceKm, RoutePlaceDto from, RoutePlaceDto to)
    {
        if (HasAirport(from) && HasAirport(to) && distanceKm > 500) return "flight";
        if ((IsAirportPlace(from) || IsAirportPlace(to)) && distanceKm < 150) return "car";
        if (distanceKm < 150 && string.Equals(from.Region, to.Region, StringComparison.OrdinalIgnoreCase)) return "motorbike";
        if (distanceKm < 150) return "car";
        if (HasRail(from) && HasRail(to) && distanceKm <= 700) return "train";
        return "coach";
    }

    private static double DurationForModeHours(double distanceKm, string mode)
    {
        return mode switch
        {
            "motorbike" => distanceKm / 45,
            "car" => distanceKm / 65,
            "coach" => distanceKm / 60,
            "train" => distanceKm / 55,
            "ferry" => 1.0 + distanceKm / 35,
            "flight" => 2.5 + distanceKm / 650,
            _ => distanceKm / 60
        };
    }

    private static string Reason(string mode)
    {
        return mode switch
        {
            "motorbike" => "Chặng ngắn cùng vùng, xe máy linh hoạt và tiết kiệm.",
            "car" => "Chặng ngắn, ô tô/taxi thuận tiện và có đường bộ trực tiếp.",
            "coach" => "Có kết nối đường bộ, xe khách phù hợp chi phí và không cần sân bay.",
            "train" => "Hai điểm có kết nối đường sắt, tàu hỏa ổn định cho chặng trung bình.",
            "ferry" => "Điểm đến hoặc điểm đi là đảo, cần phà hoặc tàu cao tốc.",
            "flight" => "Hai điểm có sân bay, máy bay tiết kiệm thời gian cho chặng dài.",
            _ => "Không có tuyến trực tiếp. Đề xuất phương án thay thế gần nhất."
        };
    }

    private static bool IsIsland(RoutePlaceDto place)
    {
        var value = Normalize(place.Name);
        return value.Contains("phu quoc") ||
               value.Contains("con dao") ||
               place.Id.Contains("phu_quoc", StringComparison.OrdinalIgnoreCase) ||
               place.Id.Contains("con_dao", StringComparison.OrdinalIgnoreCase);
    }

    private static bool HasDirectIslandFlight(RoutePlaceDto mainland, RoutePlaceDto island)
    {
        var from = Normalize(mainland.Name);
        var to = Normalize(island.Name);
        if (to.Contains("phu quoc"))
        {
            return from.Contains("ho chi minh") ||
                   from.Contains("tp.hcm") ||
                   from.Contains("ha noi") ||
                   from.Contains("da nang");
        }

        if (to.Contains("con dao"))
        {
            return from.Contains("ho chi minh") || from.Contains("tp.hcm");
        }

        return false;
    }

    private static bool PrefersFastIslandRoute(decimal? budgetPerPerson) =>
        budgetPerPerson.HasValue && budgetPerPerson.Value >= 3_000_000m;

    private static RoutePlaceDto NearestAirportForIslandRoute(RoutePlaceDto from, RoutePlaceDto island)
    {
        var name = Normalize(from.Name);
        if (HasDirectIslandFlight(from, island))
        {
            return from;
        }

        if (name.Contains("ha noi") || Normalize(from.Region).Contains("bac"))
        {
            return new("noi_bai_airport", "Sân bay Nội Bài", "Miền Bắc", 21.2187, 105.8042);
        }

        if (name.Contains("da nang") || Normalize(from.Region).Contains("trung"))
        {
            return new("da_nang_airport", "Sân bay Đà Nẵng", "Miền Trung", 16.0439, 108.1994);
        }

        return new("tan_son_nhat_airport", "Sân bay Tân Sơn Nhất", "Miền Nam", 10.8188, 106.6519);
    }

    private static bool HasAirport(RoutePlaceDto place) =>
        AirportNames.Any(x => Normalize(place.Name).Contains(x)) ||
        Normalize(place.Name).Contains("san bay");

    private static bool IsAirportPlace(RoutePlaceDto place) =>
        Normalize(place.Name).Contains("san bay") ||
        place.Id.Contains("airport", StringComparison.OrdinalIgnoreCase);

    private static bool HasRail(RoutePlaceDto place) =>
        RailNames.Any(x => Normalize(place.Name).Contains(x));

    private static RoutePlaceDto MainlandPortForIsland(RoutePlaceDto island)
    {
        var value = Normalize(island.Name);
        if (value.Contains("con dao") || island.Id.Contains("con_dao", StringComparison.OrdinalIgnoreCase))
        {
            return new("tran_de_port", "Cảng Trần Đề", "Miền Tây", 9.4969, 106.2089);
        }

        return new("ha_tien_port", "Cảng Hà Tiên", "Miền Tây", 10.3833, 104.4833);
    }

    private static string Normalize(string value)
    {
        var normalized = value.ToLowerInvariant();
        var replacements = new Dictionary<char, char>
        {
            ['à'] = 'a', ['á'] = 'a', ['ạ'] = 'a', ['ả'] = 'a', ['ã'] = 'a',
            ['â'] = 'a', ['ầ'] = 'a', ['ấ'] = 'a', ['ậ'] = 'a', ['ẩ'] = 'a', ['ẫ'] = 'a',
            ['ă'] = 'a', ['ằ'] = 'a', ['ắ'] = 'a', ['ặ'] = 'a', ['ẳ'] = 'a', ['ẵ'] = 'a',
            ['è'] = 'e', ['é'] = 'e', ['ẹ'] = 'e', ['ẻ'] = 'e', ['ẽ'] = 'e',
            ['ê'] = 'e', ['ề'] = 'e', ['ế'] = 'e', ['ệ'] = 'e', ['ể'] = 'e', ['ễ'] = 'e',
            ['ì'] = 'i', ['í'] = 'i', ['ị'] = 'i', ['ỉ'] = 'i', ['ĩ'] = 'i',
            ['ò'] = 'o', ['ó'] = 'o', ['ọ'] = 'o', ['ỏ'] = 'o', ['õ'] = 'o',
            ['ô'] = 'o', ['ồ'] = 'o', ['ố'] = 'o', ['ộ'] = 'o', ['ổ'] = 'o', ['ỗ'] = 'o',
            ['ơ'] = 'o', ['ờ'] = 'o', ['ớ'] = 'o', ['ợ'] = 'o', ['ở'] = 'o', ['ỡ'] = 'o',
            ['ù'] = 'u', ['ú'] = 'u', ['ụ'] = 'u', ['ủ'] = 'u', ['ũ'] = 'u',
            ['ư'] = 'u', ['ừ'] = 'u', ['ứ'] = 'u', ['ự'] = 'u', ['ử'] = 'u', ['ữ'] = 'u',
            ['ỳ'] = 'y', ['ý'] = 'y', ['ỵ'] = 'y', ['ỷ'] = 'y', ['ỹ'] = 'y',
            ['đ'] = 'd'
        };
        return new string(normalized.Select(c => replacements.GetValueOrDefault(c, c)).ToArray());
    }

    private sealed record RouteDistance(double DistanceKm, bool IsGoogleEstimate);
}
