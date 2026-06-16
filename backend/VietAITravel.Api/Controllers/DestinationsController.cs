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
        var ratings = await GetRatingsAsync(list.Select(d => d.Id), ct);

        return Ok(list.Select(d => Map(d, ratings.GetValueOrDefault(d.Id))));
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<DestinationDto>> Get(Guid id, CancellationToken ct)
    {
        var d = await db.Destinations.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.IsActive, ct);
        if (d == null) return NotFound();

        var ratings = await GetRatingsAsync([d.Id], ct);
        return Ok(Map(d, ratings.GetValueOrDefault(d.Id)));
    }

    private async Task<Dictionary<Guid, DestinationRating>> GetRatingsAsync(IEnumerable<Guid> destinationIds, CancellationToken ct)
    {
        var ids = destinationIds.ToArray();
        if (ids.Length == 0) return [];

        var ratings = await db.Comments.AsNoTracking()
            .Where(c => ids.Contains(c.DestinationId) && c.IsApproved)
            .GroupBy(c => c.DestinationId)
            .Select(g => new DestinationRating(
                g.Key,
                g.Average(c => c.Rating),
                g.LongCount()))
            .ToListAsync(ct);

        return ratings.ToDictionary(r => r.DestinationId);
    }

    private static DestinationDto Map(Entities.Destination d, DestinationRating? rating = null) =>
        new(d.Id, d.Name, d.Slug, d.Description, d.Province, d.Region, d.Category,
            d.EstimatedCost, d.CostUnit, d.ImageUrl,
            rating?.AverageRating ?? 0,
            rating?.TotalReviews ?? 0);

    private sealed record DestinationRating(Guid DestinationId, double AverageRating, long TotalReviews);
}
