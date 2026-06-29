namespace VietAITravel.Api.DTOs;

public sealed record TravelGenerateRequest(
    string? Destination,
    string? Prompt,
    IReadOnlyList<string> Preferences,
    decimal Budget,
    int Days,
    string Transport,
    double? Latitude = null,
    double? Longitude = null);

public sealed record TravelReplanRequest(
    TravelPlanResponse CurrentPlan,
    string Trigger,
    string? UserMessage,
    decimal? RemainingBudget = null,
    double? Latitude = null,
    double? Longitude = null);

public sealed record TravelDestinationQuery(
    string? Query,
    IReadOnlyList<string>? Preferences,
    double? Latitude,
    double? Longitude,
    int Limit = 5);

public sealed record TravelPlanResponse(
    string Destination,
    IReadOnlyList<TravelDayPlan> Days,
    decimal TotalCost,
    string AiExplanation,
    double ConfidenceScore);

public sealed record TravelDayPlan(
    int Day,
    IReadOnlyList<string> Places,
    decimal Cost,
    string TravelTime,
    string Notes);

public sealed record TravelDestinationDto(
    string Id,
    string Name,
    string Category,
    double Latitude,
    double Longitude,
    double MatchScore,
    decimal EstimatedBudget,
    string Weather,
    string TravelTime,
    string AiReason);

public sealed record TravelWeatherDto(
    double TemperatureC,
    string Description,
    bool HasWarning,
    string Warning);

public sealed record TravelHistoryItemDto(
    Guid Id,
    string? Title,
    DateTime CreatedAt,
    object? Itinerary);

public sealed record TravelMemoryDto(
    IReadOnlyList<string> PreferredStyles,
    string PreferredTransport,
    decimal AverageBudget,
    int TripCount,
    string Notes);
