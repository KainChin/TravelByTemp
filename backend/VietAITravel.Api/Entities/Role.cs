namespace VietAITravel.Api.Entities;

public class Role
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
    public ICollection<User> Users { get; set; } = new List<User>();
}
