namespace VietAITravel.Api.Entities;

public class Comment
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid DestinationId { get; set; }
    public int Rating { get; set; }
    public string? Content { get; set; }
    public bool IsApproved { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Destination Destination { get; set; } = null!;
}
