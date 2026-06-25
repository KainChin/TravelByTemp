namespace VietAITravel.Api.DTOs;

public sealed record RoutePlaceDto(
    string Id,
    string Name,
    string Region,
    double Latitude,
    double Longitude);

public sealed record AnalyzeRouteRequest(
    RoutePlaceDto Departure,
    List<RoutePlaceDto> Destinations,
    int? PeopleCount = null,
    decimal? BudgetPerPerson = null);

public sealed record RouteLegResponse(
    int Order,
    string FromName,
    RoutePlaceDto To,
    double DistanceKm,
    double DurationHours,
    string RecommendedMode,
    string Reason,
    bool IsGoogleEstimate);

public sealed record AnalyzeRouteResponse(
    RoutePlaceDto Departure,
    List<RoutePlaceDto> Destinations,
    List<RouteLegResponse> Legs,
    double TotalDistanceKm,
    double OptimizedHours,
    bool HasFlightLeg,
    Guid? RouteId = null);
