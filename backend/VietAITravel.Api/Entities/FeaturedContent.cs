namespace VietAITravel.Api.Entities;

public class FeaturedContent
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Subtitle { get; set; }
    public string? ImageUrl { get; set; }
    public string? LinkUrl { get; set; }
    public string ContentType { get; set; } = "article";
    public Guid? ReferenceId { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
}
