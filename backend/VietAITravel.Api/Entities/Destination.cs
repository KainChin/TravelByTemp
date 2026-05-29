using Pgvector;

namespace VietAITravel.Api.Entities;

public class Destination
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string Province { get; set; } = null!;
    public string Region { get; set; } = null!;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string Category { get; set; } = null!;
    public decimal EstimatedCost { get; set; }
    public string CostUnit { get; set; } = "VND/person";
    public string? OpeningHours { get; set; }
    public string? ImageUrl { get; set; }
    public string? BestTimeToVisit { get; set; }
    public string? SuitableWeather { get; set; }
    public string? TravelStyle { get; set; }
    public string? AiRecommendationNote { get; set; }
    public string? EmbeddingText { get; set; }
    public Vector? Embedding { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
