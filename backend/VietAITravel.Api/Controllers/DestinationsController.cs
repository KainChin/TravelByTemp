using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/destinations")]
public class DestinationsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<DestinationDto>>> List(
        [FromQuery] string? region,
        [FromQuery] string? category,
        [FromQuery] decimal? maxBudget,
        CancellationToken ct)
    {
        var query = db.Destinations.AsNoTracking().Where(d => d.IsActive);
        if (!string.IsNullOrEmpty(region)) query = query.Where(d => d.Region == region);
        if (!string.IsNullOrEmpty(category)) query = query.Where(d => d.Category == category);
        if (maxBudget.HasValue) query = query.Where(d => d.EstimatedCost <= maxBudget);

        var list = await query.OrderBy(d => d.Name).ToListAsync(ct);
        return Ok(list.Select(Map));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<DestinationDto>> Get(Guid id, CancellationToken ct)
    {
        var d = await db.Destinations.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.IsActive, ct);
        return d == null ? NotFound() : Ok(Map(d));
    }

    private static DestinationDto Map(Entities.Destination d) =>
        new(d.Id, d.Name, d.Slug, d.Description, d.Province, d.Region, d.Category,
            d.EstimatedCost, d.CostUnit, d.ImageUrl);
}
