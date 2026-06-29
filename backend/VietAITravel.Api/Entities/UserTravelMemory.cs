namespace VietAITravel.Api.Entities;

public class UserTravelMemory
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string PreferredStylesJson { get; set; } = "[]";
    public string PreferredTransport { get; set; } = "";
    public decimal AverageBudget { get; set; }
    public int TripCount { get; set; }
    public string Notes { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
