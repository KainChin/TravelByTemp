namespace VietAITravel.Api.DTOs;

public record ChatRequest(string Message);

public record ChatEnvelopeResponse(string Response, object? Itinerary, Guid? ItineraryId = null);

public record AiItineraryHistoryResponse(string Response, IReadOnlyList<AiItineraryHistoryItem> Items);

public record AiItineraryHistoryItem(
    Guid Id,
    string? Title,
    string? AiModel,
    DateTime CreatedAt,
    object? Itinerary);

public record SaveItineraryRequest(Guid? ItineraryId, string? Title, object Itinerary);

public record GenerateItineraryRequest(
    IReadOnlyList<TripDestinationInput> Destinations,
    DateTime DepartureDate,
    DateTime ReturnDate,
    int PeopleCount,
    decimal BudgetPerPerson,
    string? DeparturePoint,
    string? TravelGroup,
    IReadOnlyList<string>? Interests,
    string? SpecialRequest,
    IReadOnlyList<TripRouteLegInput>? RouteLegs);

public record TripDestinationInput(
    string Id,
    string Name,
    string? Region,
    string? FromLabel,
    DateTime? StartDate,
    DateTime? EndDate,
    double? Latitude,
    double? Longitude);

public record TripRouteLegInput(
    int Order,
    string? FromName,
    string? ToName,
    string? Mode,
    double DistanceKm,
    double DurationHours,
    decimal EstimatedCostVnd,
    string? Reason);
