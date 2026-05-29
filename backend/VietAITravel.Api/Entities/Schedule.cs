namespace VietAITravel.Api.Entities;

public class Schedule
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Title { get; set; } = null!;
    public int TotalDays { get; set; } = 1;
    public decimal BudgetInput { get; set; }
    public string? PreferenceInput { get; set; }
    public decimal? UserLatitude { get; set; }
    public decimal? UserLongitude { get; set; }
    public string? UserLocationName { get; set; }
    public decimal? CurrentTemperature { get; set; }
    public string? CurrentWeatherDescription { get; set; }
    public string? MongoAiLogId { get; set; }
    public string? AiModelUsed { get; set; }
    public string? EmbeddingModelUsed { get; set; }
    public bool IsPublic { get; set; }
    public DateTime GeneratedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<ScheduleDestination> ScheduleDestinations { get; set; } = new List<ScheduleDestination>();
}
