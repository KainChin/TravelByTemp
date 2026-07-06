namespace VietAITravel.Api.Entities;

public class Banner
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string ImageUrl { get; set; } = null!;
    public string? LinkUrl { get; set; }
    public int SortOrder { get; set; }
    public string Region { get; set; } = "North";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
