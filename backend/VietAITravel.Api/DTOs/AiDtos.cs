namespace VietAITravel.Api.DTOs;

public record AiRecommendRequest(
    double Latitude,
    double Longitude,
    string? LocationName,
    decimal BudgetInput,
    int TotalDays,
    string PreferenceInput,
    int TopK = 5);

public record AiRecommendResponse(
    Guid ScheduleId,
    string MongoLogId,
    string Title,
    string Summary,
    decimal CurrentTemperature,
    string CurrentWeatherDescription,
    IReadOnlyList<RecommendedDestinationDto> RecommendedDestinations,
    IReadOnlyList<DailyPlanDto> DailyPlan);

public record RecommendedDestinationDto(
    Guid DestinationId, string Name, string Reason, string WeatherFit, decimal EstimatedCost);

public record DailyPlanDto(int Day, IReadOnlyList<DailyPlanItemDto> Items);

public record DailyPlanItemDto(
    Guid DestinationId, string Time, string Activity, string? Note);

public record AiScheduleJson(
    string title,
    string summary,
    List<AiRecommendedDestination> recommendedDestinations,
    List<AiDailyPlan> dailyPlan);

public record AiRecommendedDestination(
    string destinationId, string name, string reason, string weatherFit, decimal estimatedCost);

public record AiDailyPlan(int day, List<AiDailyPlanItem> items);

public record AiDailyPlanItem(string destinationId, string time, string activity, string? note);
