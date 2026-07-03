namespace VietAITravel.Api.Entities;

public class GalleryImage
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string ImageUrl { get; set; } = null!;
    public Guid? DestinationId { get; set; }
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }

    public Destination? Destination { get; set; }
}
