namespace VietAITravel.Api.Entities;

public class AiItinerary
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string? Title { get; set; }
    public string RequestJson { get; set; } = null!;
    public string ItineraryJson { get; set; } = null!;
    public string? AiModel { get; set; }
    public DateTime CreatedAt { get; set; }

    public User? User { get; set; }
}
