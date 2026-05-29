namespace VietAITravel.Api.Entities;

public class ScheduleDestination
{
    public Guid Id { get; set; }
    public Guid ScheduleId { get; set; }
    public Guid DestinationId { get; set; }
    public int DayNumber { get; set; }
    public int OrderInDay { get; set; } = 1;
    public string? Note { get; set; }
    public TimeOnly? EstimatedTime { get; set; }
    public string? AiReason { get; set; }
    public string? WeatherFitNote { get; set; }

    public Schedule Schedule { get; set; } = null!;
    public Destination Destination { get; set; } = null!;
}
