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
[Route("api/favorites")]
[Authorize(Roles = RoleNames.Traveler + "," + RoleNames.Admin)]
public class FavoritesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<FavoriteDestinationDto>>> MyFavorites(CancellationToken ct)
    {
        var userId = GetUserId();
        var favorites = await db.UserFavorites.AsNoTracking()
            .Include(f => f.Destination)
            .Where(f => f.UserId == userId && f.Destination.IsActive)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync(ct);

        return Ok(favorites.Select(Map));
    }

    [HttpPost("{destinationId:guid}")]
    public async Task<ActionResult<FavoriteDestinationDto>> Add(Guid destinationId, CancellationToken ct)
    {
        var destination = await db.Destinations.AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == destinationId && d.IsActive, ct)
            ?? throw new KeyNotFoundException("Destination not found.");

        var userId = GetUserId();
        var existing = await db.UserFavorites.AsNoTracking()
            .Include(f => f.Destination)
            .FirstOrDefaultAsync(f => f.UserId == userId && f.DestinationId == destinationId, ct);

        if (existing is not null)
            return Ok(Map(existing));

        var favorite = new UserFavorite
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DestinationId = destinationId,
            CreatedAt = DateTime.UtcNow
        };

        db.UserFavorites.Add(favorite);
        await db.SaveChangesAsync(ct);

        favorite.Destination = destination;
        return Created($"/api/favorites/{destinationId}", Map(favorite));
    }

    [HttpDelete("{destinationId:guid}")]
    public async Task<IActionResult> Delete(Guid destinationId, CancellationToken ct)
    {
        var userId = GetUserId();
        var favorite = await db.UserFavorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.DestinationId == destinationId, ct);

        if (favorite is null)
            return NoContent();

        db.UserFavorites.Remove(favorite);
        await db.SaveChangesAsync(ct);

        return NoContent();
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static FavoriteDestinationDto Map(UserFavorite favorite) =>
        new(favorite.Id, favorite.CreatedAt, MapDestination(favorite.Destination));

    private static DestinationDto MapDestination(Destination d) =>
        new(d.Id, d.Name, d.Slug, d.Description, d.Province, d.Region,
            d.Latitude, d.Longitude, d.Category,
            d.EstimatedCost, d.CostUnit, d.ImageUrl);
}
