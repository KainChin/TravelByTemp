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
        [FromQuery] double? latitude,
        [FromQuery] double? longitude,
        [FromQuery] double? radiusKm,
        CancellationToken ct)
    {
        ValidateLocationFilter(latitude, longitude, radiusKm);

        var query = db.Destinations.AsNoTracking().Where(d => d.IsActive);
        if (!string.IsNullOrEmpty(region)) query = query.Where(d => d.Region == region);
        if (!string.IsNullOrEmpty(category)) query = query.Where(d => d.Category == category);
        if (maxBudget.HasValue) query = query.Where(d => d.EstimatedCost <= maxBudget);

        var list = await query.ToListAsync(ct);
        var distanceById = new Dictionary<Guid, double>();
        if (latitude.HasValue && longitude.HasValue)
        {
            distanceById = list.ToDictionary(
                d => d.Id,
                d => DistanceKm(latitude.Value, longitude.Value, (double)d.Latitude, (double)d.Longitude));

            if (radiusKm.HasValue)
                list = list.Where(d => distanceById[d.Id] <= radiusKm.Value).ToList();

            list = list.OrderBy(d => distanceById[d.Id]).ThenBy(d => d.Name).ToList();
        }
        else
        {
            list = list.OrderBy(d => d.Name).ToList();
        }

        var ratings = await GetRatingsAsync(list.Select(d => d.Id), ct);

        return Ok(list.Select(d => Map(
            d,
            ratings.GetValueOrDefault(d.Id),
            distanceById.TryGetValue(d.Id, out var distanceKm) ? distanceKm : null)));
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

    private static DestinationDto Map(Entities.Destination d, DestinationRating? rating = null, double? distanceKm = null) =>
        new(d.Id, d.Name, d.Slug, d.Description, d.Province, d.Region,
            d.Latitude, d.Longitude, d.Category,
            d.EstimatedCost, d.CostUnit, d.ImageUrl,
            distanceKm,
            rating?.AverageRating ?? 0,
            rating?.TotalReviews ?? 0);

    private static void ValidateLocationFilter(double? latitude, double? longitude, double? radiusKm)
    {
        if (latitude is < -90 or > 90)
            throw new ArgumentException("Latitude must be between -90 and 90.");

        if (longitude is < -180 or > 180)
            throw new ArgumentException("Longitude must be between -180 and 180.");

        if (radiusKm is <= 0)
            throw new ArgumentException("Radius must be greater than 0.");

        if (radiusKm.HasValue && (!latitude.HasValue || !longitude.HasValue))
            throw new ArgumentException("Latitude and longitude are required when radiusKm is provided.");
    }

    private static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusKm = 6371;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a =
            Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
            Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
            Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return earthRadiusKm * c;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;

    private sealed record DestinationRating(Guid DestinationId, double AverageRating, long TotalReviews);
}
