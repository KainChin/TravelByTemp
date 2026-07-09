using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
namespace VietAITravel.Api.Services;
public sealed partial class RouteAnalysisService {
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

}
