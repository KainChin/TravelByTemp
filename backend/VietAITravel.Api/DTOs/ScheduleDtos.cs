namespace VietAITravel.Api.DTOs;

public record ScheduleSummaryDto(
    Guid Id,
    string Title,
    int TotalDays,
    decimal BudgetInput,
    string? PreferenceInput,
    string? UserLocationName,
    decimal? CurrentTemperature,
    string? CurrentWeatherDescription,
    DateTime GeneratedAt);

public record ScheduleDetailDto(
    Guid Id,
    Guid UserId,
    string Title,
    int TotalDays,
    decimal BudgetInput,
    string? PreferenceInput,
    decimal? UserLatitude,
    decimal? UserLongitude,
    string? UserLocationName,
    decimal? CurrentTemperature,
    string? CurrentWeatherDescription,
    string? AiModelUsed,
    string? EmbeddingModelUsed,
    bool IsPublic,
    DateTime GeneratedAt,
    DateTime? UpdatedAt,
    IReadOnlyList<ScheduleDestinationDto> Destinations);

public record ScheduleDestinationDto(
    Guid Id,
    Guid DestinationId,
    string DestinationName,
    string DestinationSlug,
    string Province,
    string Region,
    string Category,
    decimal EstimatedCost,
    string CostUnit,
    string? ImageUrl,
    int DayNumber,
    int OrderInDay,
    string? Note,
    string? EstimatedTime,
    string? AiReason,
    string? WeatherFitNote);

public record CreateScheduleRequest(
    string Title,
    int TotalDays,
    decimal BudgetInput,
    string? PreferenceInput,
    decimal? UserLatitude,
    decimal? UserLongitude,
    string? UserLocationName);

public record UpdateScheduleDaysRequest(int TotalDays);

public record AddScheduleActivityRequest(
    Guid DestinationId,
    int DayNumber,
    int? OrderInDay,
    string? EstimatedTime,
    string? Note,
    string? AiReason,
    string? WeatherFitNote);

public record UpdateScheduleActivityRequest(
    Guid? DestinationId,
    int? DayNumber,
    int? OrderInDay,
    string? EstimatedTime,
    string? Note,
    string? AiReason,
    string? WeatherFitNote);
