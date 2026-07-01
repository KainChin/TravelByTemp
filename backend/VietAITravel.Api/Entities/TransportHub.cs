namespace VietAITravel.Api.Entities;

public sealed class TransportHub
{
    public Guid Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string Type { get; set; } = "";
    public string Province { get; set; } = "";
    public string Region { get; set; } = "";
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<TransportRoute> OriginRoutes { get; set; } = [];
    public ICollection<TransportRoute> DestinationRoutes { get; set; } = [];
}
