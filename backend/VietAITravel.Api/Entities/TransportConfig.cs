namespace VietAITravel.Api.Entities;

public sealed class TransportConfig
{
    public Guid Id { get; set; }
    public string Key { get; set; } = "";
    public string Value { get; set; } = "";
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
