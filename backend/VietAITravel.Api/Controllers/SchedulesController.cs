using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/schedules")]
[Authorize]
public class SchedulesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ScheduleSummaryDto>>> MySchedules(CancellationToken ct)
    {
        var userId = GetUserId();
        var list = await db.Schedules.AsNoTracking()
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.GeneratedAt)
            .Select(s => new ScheduleSummaryDto(
                s.Id,
                s.Title,
                s.TotalDays,
                s.BudgetInput,
                s.PreferenceInput,
                s.UserLocationName,
                s.CurrentTemperature,
                s.CurrentWeatherDescription,
                s.GeneratedAt))
            .ToListAsync(ct);
        return Ok(list);
    }

    [HttpPost]
    public async Task<ActionResult<ScheduleDetailDto>> Create(CreateScheduleRequest request, CancellationToken ct)
    {
        ValidateScheduleRequest(request);

        var schedule = new Schedule
        {
            Id = Guid.NewGuid(),
            UserId = GetUserId(),
            Title = request.Title.Trim(),
            TotalDays = request.TotalDays,
            BudgetInput = request.BudgetInput,
            PreferenceInput = request.PreferenceInput,
            UserLatitude = request.UserLatitude,
            UserLongitude = request.UserLongitude,
            UserLocationName = request.UserLocationName,
            GeneratedAt = DateTime.UtcNow
        };

        db.Schedules.Add(schedule);
        await db.SaveChangesAsync(ct);

        return Created($"/api/schedules/{schedule.Id}", MapDetail(schedule));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ScheduleDetailDto>> Get(Guid id, CancellationToken ct)
    {
        var schedule = await db.Schedules.AsNoTracking()
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        return Ok(MapDetail(schedule));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var schedule = await db.Schedules
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        db.Schedules.Remove(schedule);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPatch("{id:guid}/days")]
    public async Task<ActionResult<ScheduleDetailDto>> UpdateDays(
        Guid id,
        UpdateScheduleDaysRequest request,
        CancellationToken ct)
    {
        if (request.TotalDays is < 1 or > 14)
            throw new ArgumentException("Total days must be between 1 and 14.");

        var schedule = await db.Schedules
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        var maxActivityDay = schedule.ScheduleDestinations.Count == 0
            ? 0
            : schedule.ScheduleDestinations.Max(sd => sd.DayNumber);
        if (request.TotalDays < maxActivityDay)
            throw new InvalidOperationException($"Total days cannot be lower than existing activity day {maxActivityDay}.");

        schedule.TotalDays = request.TotalDays;
        schedule.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return Ok(MapDetail(schedule));
    }

    [HttpPost("{id:guid}/activities")]
    public async Task<ActionResult<ScheduleDetailDto>> AddActivity(
        Guid id,
        AddScheduleActivityRequest request,
        CancellationToken ct)
    {
        var schedule = await db.Schedules
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        ValidateActivityDay(request.DayNumber, schedule.TotalDays);
        await EnsureDestinationExistsAsync(request.DestinationId, ct);

        var order = request.OrderInDay ?? NextOrder(schedule, request.DayNumber);
        ValidateOrder(order);
        EnsureOrderAvailable(schedule, request.DayNumber, order);

        db.ScheduleDestinations.Add(new ScheduleDestination
        {
            Id = Guid.NewGuid(),
            ScheduleId = schedule.Id,
            DestinationId = request.DestinationId,
            DayNumber = request.DayNumber,
            OrderInDay = order,
            EstimatedTime = ParseTime(request.EstimatedTime),
            Note = request.Note,
            AiReason = request.AiReason,
            WeatherFitNote = request.WeatherFitNote
        });
        schedule.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);

        return Created($"/api/schedules/{id}", MapDetail(await LoadScheduleForDetailAsync(id, ct)));
    }

    [HttpPut("{scheduleId:guid}/activities/{activityId:guid}")]
    public async Task<ActionResult<ScheduleDetailDto>> UpdateActivity(
        Guid scheduleId,
        Guid activityId,
        UpdateScheduleActivityRequest request,
        CancellationToken ct)
    {
        var schedule = await db.Schedules
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == scheduleId, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        var activity = schedule.ScheduleDestinations.FirstOrDefault(sd => sd.Id == activityId)
            ?? throw new KeyNotFoundException("Activity not found.");

        if (request.DestinationId.HasValue)
        {
            await EnsureDestinationExistsAsync(request.DestinationId.Value, ct);
            activity.DestinationId = request.DestinationId.Value;
        }

        var newDay = request.DayNumber ?? activity.DayNumber;
        var newOrder = request.OrderInDay ?? activity.OrderInDay;
        ValidateActivityDay(newDay, schedule.TotalDays);
        ValidateOrder(newOrder);
        EnsureOrderAvailable(schedule, newDay, newOrder, activity.Id);

        activity.DayNumber = newDay;
        activity.OrderInDay = newOrder;
        if (request.EstimatedTime is not null) activity.EstimatedTime = ParseTime(request.EstimatedTime);
        if (request.Note is not null) activity.Note = request.Note;
        if (request.AiReason is not null) activity.AiReason = request.AiReason;
        if (request.WeatherFitNote is not null) activity.WeatherFitNote = request.WeatherFitNote;
        schedule.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);

        return Ok(MapDetail(await LoadScheduleForDetailAsync(scheduleId, ct)));
    }

    [HttpDelete("{scheduleId:guid}/activities/{activityId:guid}")]
    public async Task<ActionResult<ScheduleDetailDto>> DeleteActivity(
        Guid scheduleId,
        Guid activityId,
        CancellationToken ct)
    {
        var schedule = await db.Schedules
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == scheduleId, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

        if (!CanAccess(schedule))
            return Forbid();

        var activity = schedule.ScheduleDestinations.FirstOrDefault(sd => sd.Id == activityId)
            ?? throw new KeyNotFoundException("Activity not found.");

        db.ScheduleDestinations.Remove(activity);
        schedule.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return Ok(MapDetail(await LoadScheduleForDetailAsync(scheduleId, ct)));
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private bool CanAccess(Schedule schedule) =>
        schedule.UserId == GetUserId() || User.IsInRole(RoleNames.Admin);

    private static void ValidateScheduleRequest(CreateScheduleRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
            throw new ArgumentException("Title is required.");

        if (request.TotalDays is < 1 or > 14)
            throw new ArgumentException("Total days must be between 1 and 14.");

        if (request.BudgetInput < 0)
            throw new ArgumentException("Budget input must be greater than or equal to 0.");

        if (request.UserLatitude is < -90 or > 90)
            throw new ArgumentException("User latitude must be between -90 and 90.");

        if (request.UserLongitude is < -180 or > 180)
            throw new ArgumentException("User longitude must be between -180 and 180.");
    }

    private static void ValidateActivityDay(int dayNumber, int totalDays)
    {
        if (dayNumber < 1 || dayNumber > totalDays)
            throw new ArgumentException($"Day number must be between 1 and {totalDays}.");
    }

    private static void ValidateOrder(int orderInDay)
    {
        if (orderInDay < 1)
            throw new ArgumentException("Order in day must be greater than or equal to 1.");
    }

    private async Task EnsureDestinationExistsAsync(Guid destinationId, CancellationToken ct)
    {
        var exists = await db.Destinations.AsNoTracking()
            .AnyAsync(d => d.Id == destinationId && d.IsActive, ct);
        if (!exists)
            throw new KeyNotFoundException("Destination not found.");
    }

    private static int NextOrder(Schedule schedule, int dayNumber) =>
        schedule.ScheduleDestinations
            .Where(sd => sd.DayNumber == dayNumber)
            .Select(sd => sd.OrderInDay)
            .DefaultIfEmpty(0)
            .Max() + 1;

    private static void EnsureOrderAvailable(
        Schedule schedule,
        int dayNumber,
        int orderInDay,
        Guid? ignoredActivityId = null)
    {
        var exists = schedule.ScheduleDestinations.Any(sd =>
            sd.DayNumber == dayNumber &&
            sd.OrderInDay == orderInDay &&
            sd.Id != ignoredActivityId);
        if (exists)
            throw new InvalidOperationException("Another activity already uses this day and order.");
    }

    private static TimeOnly? ParseTime(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        if (!TimeOnly.TryParse(value, out var time))
            throw new ArgumentException("Estimated time must use HH:mm format.");

        return time;
    }

    private async Task<Schedule> LoadScheduleForDetailAsync(Guid id, CancellationToken ct) =>
        await db.Schedules.AsNoTracking()
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
            ?? throw new KeyNotFoundException("Schedule not found.");

    private static ScheduleDetailDto MapDetail(Schedule schedule) =>
        new(
            schedule.Id,
            schedule.UserId,
            schedule.Title,
            schedule.TotalDays,
            schedule.BudgetInput,
            schedule.PreferenceInput,
            schedule.UserLatitude,
            schedule.UserLongitude,
            schedule.UserLocationName,
            schedule.CurrentTemperature,
            schedule.CurrentWeatherDescription,
            schedule.AiModelUsed,
            schedule.EmbeddingModelUsed,
            schedule.IsPublic,
            schedule.GeneratedAt,
            schedule.UpdatedAt,
            schedule.ScheduleDestinations
                .OrderBy(sd => sd.DayNumber)
                .ThenBy(sd => sd.OrderInDay)
                .Select(MapDestination)
                .ToList());

    private static ScheduleDestinationDto MapDestination(ScheduleDestination sd) =>
        new(
            sd.Id,
            sd.DestinationId,
            sd.Destination.Name,
            sd.Destination.Slug,
            sd.Destination.Province,
            sd.Destination.Region,
            sd.Destination.Category,
            sd.Destination.EstimatedCost,
            sd.Destination.CostUnit,
            sd.Destination.ImageUrl,
            sd.DayNumber,
            sd.OrderInDay,
            sd.Note,
            sd.EstimatedTime?.ToString("HH:mm"),
            sd.AiReason,
            sd.WeatherFitNote);
}
