using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Services;
using VietAITravel.Api.Services.TravelCompanion;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/travel")]
[Authorize]
public sealed class TravelController(
    TravelPlannerService planner,
    DestinationDiscoveryService destinations,
    WeatherService weather,
    TravelMemoryService memory,
    AppDbContext db) : ControllerBase
{
    [HttpPost("generate")]
    public async Task<ActionResult<TravelPlanResponse>> Generate(
        TravelGenerateRequest request,
        CancellationToken ct)
    {
        return Ok(await planner.GenerateAsync(GetUserIdOrNull(), request, ct));
    }

    [HttpPost("replan")]
    public async Task<ActionResult<TravelPlanResponse>> Replan(
        TravelReplanRequest request,
        CancellationToken ct)
    {
        return Ok(await planner.ReplanAsync(GetUserIdOrNull(), request, ct));
    }

    [HttpGet("destinations")]
    [AllowAnonymous]
    public async Task<ActionResult<IReadOnlyList<TravelDestinationDto>>> GetDestinations(
        [FromQuery] string? query,
        [FromQuery] string[] preferences,
        [FromQuery] double? latitude,
        [FromQuery] double? longitude,
        [FromQuery] int limit,
        CancellationToken ct)
    {
        return Ok(await destinations.SearchAsync(
            new TravelDestinationQuery(query, preferences, latitude, longitude, limit <= 0 ? 5 : limit),
            ct));
    }

    [HttpGet("weather")]
    [AllowAnonymous]
    public async Task<ActionResult<TravelWeatherDto>> GetWeather(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        CancellationToken ct)
    {
        var result = await weather.GetCurrentWeatherAsync(latitude, longitude, ct);
        var warning = result.Description.Contains("mưa", StringComparison.OrdinalIgnoreCase) ||
                      result.Description.Contains("bão", StringComparison.OrdinalIgnoreCase);
        return Ok(new TravelWeatherDto(
            result.TemperatureC,
            result.Description,
            warning,
            warning ? "Có rủi ro thời tiết, nên chuẩn bị phương án trong nhà." : ""));
    }

    [HttpGet("history")]
    public async Task<ActionResult<IReadOnlyList<TravelHistoryItemDto>>> History(CancellationToken ct)
    {
        var userId = GetUserIdOrNull();
        var rows = await db.AiItineraries.AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(20)
            .ToListAsync(ct);

        return Ok(rows.Select(x => new TravelHistoryItemDto(
            x.Id,
            x.Title,
            x.CreatedAt,
            TryDeserializeJson(x.ItineraryJson))).ToList());
    }

    [HttpGet("memory")]
    public async Task<ActionResult<TravelMemoryDto>> Memory(CancellationToken ct)
    {
        var userId = GetUserIdOrNull();
        if (!userId.HasValue) return Unauthorized();
        return Ok(await memory.GetAsync(userId.Value, ct));
    }

    private Guid? GetUserIdOrNull()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(value, out var userId) ? userId : null;
    }

    private static object? TryDeserializeJson(string json)
    {
        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<object>(json);
        }
        catch
        {
            return null;
        }
    }
}
