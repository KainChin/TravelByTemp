namespace VietAITravel.Api.DTOs;

public record DestinationDto(
    Guid Id, string Name, string Slug, string Description, string Province, string Region,
    string Category, decimal EstimatedCost, string CostUnit, string? ImageUrl,
    double? AverageRating = null, long? TotalReviews = null);

public record CreateDestinationRequest(
    string Name, string Slug, string Description, string Province, string Region,
    decimal Latitude, decimal Longitude, string Category, decimal EstimatedCost,
    string? OpeningHours, string? ImageUrl, string? BestTimeToVisit,
    string? SuitableWeather, string? TravelStyle, string? AiRecommendationNote,
    string? EmbeddingText);

public record UpdateDestinationRequest(
    string? Name, string? Slug, string? Description, string? Province, string? Region,
    decimal? Latitude, decimal? Longitude, string? Category, decimal? EstimatedCost,
    string? CostUnit, string? OpeningHours, string? ImageUrl, string? BestTimeToVisit,
    string? SuitableWeather, string? TravelStyle, string? AiRecommendationNote,
    bool? IsActive, string? EmbeddingText);
