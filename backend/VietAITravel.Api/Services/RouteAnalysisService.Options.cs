using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
namespace VietAITravel.Api.Services;
public sealed partial class RouteAnalysisService {
    private async Task<List<TransportOptionResponse>> BuildTransportOptionsAsync(
        RoutePlaceDto from,
        RoutePlaceDto to,
        double distanceKm,
        TransportConfigValues transportRules,
        CancellationToken ct)
    {
        var dynamicCosts = await EstimateCostsWithGroqAsync(distanceKm, from.Name, to.Name, ct);
        double GetCost(string m) => dynamicCosts != null && dynamicCosts.TryGetValue(m, out var c) && c > 0 ? c : CostForMode(distanceKm, m);

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
            new("car", roadAvailable, roadReason, DurationForModeHours(distanceKm, "car"), GetCost("car")),
            new("motorbike", roadAvailable && distanceKm <= 180, roadAvailable ? (distanceKm <= 180 ? "Suitable for a short road leg." : "Not recommended for a long road leg.") : roadReason, DurationForModeHours(distanceKm, "motorbike"), GetCost("motorbike")),
            new("coach", roadAvailable && distanceKm >= 40, roadAvailable ? (distanceKm >= 40 ? "Coach is suitable for intercity road travel." : "Leg is too short for coach to be practical.") : roadReason, DurationForModeHours(distanceKm, "coach"), GetCost("coach"))
        };

        var trainRoute = fromRail is null || toRail is null || fromRail.Id == toRail.Id
            ? null
            : await FindRouteAsync(fromRail.Id, toRail.Id, "train", ct);
        options.Add(trainRoute is null || isCrossing
            ? new("train", false, isCrossing ? roadReason : "Tàu hỏa không khả thi (không có ga phù hợp hoặc 2 điểm dùng chung 1 ga).", DurationForModeHours(distanceKm, "train"), GetCost("train"))
            : new("train", true, $"Có tuyến tàu hỏa qua {fromRail!.Name} -> {toRail!.Name}.", trainRoute.EstimatedDurationHours, (double)trainRoute.EstimatedCostVnd));

        var flightOption = await BuildFlightOptionAsync(from, to, distanceKm, fromAirport, toAirport, transportRules, GetCost("flight"), ct);
        options.Add(flightOption);

        var ferryRoute = fromPort is null || toPort is null || fromPort.Id == toPort.Id
            ? null
            : await FindRouteAsync(fromPort.Id, toPort.Id, "ferry", ct);
            
        if (fromPort is null || toPort is null || ferryRoute is null || fromPort.Id == toPort.Id)
        {
            options.Add(new("ferry", false, "Phà/tàu thủy không khả thi (không có bến phù hợp hoặc 2 điểm dùng chung bến).", DurationForModeHours(distanceKm, "ferry"), GetCost("ferry")));
        }
        else
        {
            var roadToPortKm = EstimateDistance(from, ToPlace(fromPort)).DistanceKm;
            var portToDestKm = EstimateDistance(ToPlace(toPort), to).DistanceKm;

            var roadMode = roadToPortKm > 40 ? "coach" : "car";
            var destRoadMode = portToDestKm > 40 ? "coach" : "car";

            var roadDuration = DurationForModeHours(roadToPortKm, roadMode);
            var roadCost = GetCost(roadMode);

            var destDuration = DurationForModeHours(portToDestKm, destRoadMode);
            var destCost = GetCost(destRoadMode);

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
        double estimatedFlightCost,
        CancellationToken ct)
    {
        if (fromAirport is null || toAirport is null || fromAirport.Id == toAirport.Id)
        {
            return new(
                "flight",
                false,
                "Máy bay không khả thi vì không có sân bay phù hợp hoặc 2 địa điểm dùng chung 1 sân bay.",
                FlightDurationHours(distanceKm, 0, 0),
                estimatedFlightCost,
                Segments: [$"{from.Name} -> Không có sân bay", "Không có chuyến bay", $"Không có sân bay -> {to.Name}"]);
        }

        var airportDistance = EstimateDistance(ToPlace(fromAirport), ToPlace(toAirport)).DistanceKm;
        var airportRoute = await FindRouteAsync(fromAirport.Id, toAirport.Id, "flight", ct);
        
        // Khong the bay neu khoang cach thuc te giua 2 san bay qua ngan (duoi 100km)
        if (airportDistance < 100)
        {
            return new(
                "flight",
                false,
                "Máy bay không khả thi vì khoảng cách giữa 2 sân bay quá gần.",
                FlightDurationHours(distanceKm, 0, 0),
                estimatedFlightCost,
                Segments: [$"{from.Name} -> {fromAirport.Name}", "Khoảng cách quá gần để bay", $"{toAirport.Name} -> {to.Name}"]);
        }

        var originTransferKm = EstimateDistance(from, ToPlace(fromAirport)).DistanceKm;
        var destinationTransferKm = EstimateDistance(ToPlace(toAirport), to).DistanceKm;
        var duration = FlightDurationHours(
            airportDistance,
            DurationForModeHours(originTransferKm, "car"),
            DurationForModeHours(destinationTransferKm, "car"));
        var cost = CostForMode(originTransferKm, "car") +
                   (double)(airportRoute?.EstimatedCostVnd ?? (decimal)estimatedFlightCost) +
                   CostForMode(destinationTransferKm, "car");

        if (distanceKm < transportRules.ShortFlightDistanceKm)
        {
            return new(
                "flight",
                false, // Set to false so it won't be recommended or chosen by default for short routes
                "Không khuyến nghị: Chặng quá ngắn, đi đường bộ sẽ nhanh và rẻ hơn.",
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
}
