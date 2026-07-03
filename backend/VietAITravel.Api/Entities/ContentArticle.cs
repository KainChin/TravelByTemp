namespace VietAITravel.Api.Entities;

public class ContentArticle
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string? Summary { get; set; }
    public string Content { get; set; } = "";
    public string ArticleType { get; set; } = "article";
    public string Category { get; set; } = "destination";
    public string Status { get; set; } = "draft";
    public Guid AuthorId { get; set; }
    public string? ThumbnailUrl { get; set; }
    public Guid? DestinationId { get; set; }
    public long ViewCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? PublishedAt { get; set; }

    public User Author { get; set; } = null!;
    public Destination? Destination { get; set; }
}
