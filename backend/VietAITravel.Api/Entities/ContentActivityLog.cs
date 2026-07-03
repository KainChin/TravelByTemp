namespace VietAITravel.Api.Entities;

public class ContentActivityLog
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ActionType { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string? EntityType { get; set; }
    public Guid? EntityId { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
