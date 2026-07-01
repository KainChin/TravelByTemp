namespace VietAITravel.Api.Entities;

public sealed class TransportRoute
{
    public Guid Id { get; set; }
    public Guid OriginHubId { get; set; }
    public Guid DestinationHubId { get; set; }
    public string TransportType { get; set; } = "";
    public double EstimatedDurationHours { get; set; }
    public decimal EstimatedCostVnd { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public TransportHub OriginHub { get; set; } = null!;
    public TransportHub DestinationHub { get; set; } = null!;
}
