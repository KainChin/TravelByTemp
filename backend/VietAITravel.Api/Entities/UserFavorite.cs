namespace VietAITravel.Api.Entities;

public class UserFavorite
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid DestinationId { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public Destination Destination { get; set; } = null!;
}
