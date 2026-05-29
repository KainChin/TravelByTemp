using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/schedules")]
[Authorize]
public class SchedulesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult> MySchedules(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var list = await db.Schedules.AsNoTracking()
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.GeneratedAt)
            .Select(s => new { s.Id, s.Title, s.TotalDays, s.BudgetInput, s.GeneratedAt, s.CurrentTemperature })
            .ToListAsync(ct);
        return Ok(list);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> Get(Guid id, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var schedule = await db.Schedules.AsNoTracking()
            .Include(s => s.ScheduleDestinations).ThenInclude(sd => sd.Destination)
            .FirstOrDefaultAsync(s => s.Id == id && s.UserId == userId, ct);
        return schedule == null ? NotFound() : Ok(schedule);
    }
}
