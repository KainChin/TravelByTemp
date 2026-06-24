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

public record GenerateItineraryRequest(
    IReadOnlyList<TripDestinationInput> Destinations,
    DateTime DepartureDate,
    DateTime ReturnDate,
    int PeopleCount,
    decimal BudgetPerPerson,
    string? DeparturePoint);

public record TripDestinationInput(
    string Id,
    string Name,
    string? Region,
    string? FromLabel);
