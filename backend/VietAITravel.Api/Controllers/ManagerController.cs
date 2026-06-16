using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/manager")]
[Authorize(Roles = RoleNames.TravelManager + "," + RoleNames.Admin)]
public class ManagerController(
    AppDbContext db,
    AiRecommendationService ai,
    EmbeddingSeedService embeddingSeed) : ControllerBase
{
    [HttpPost("destinations/embed-all")]
    public async Task<IActionResult> EmbedAll(CancellationToken ct)
    {
        var count = await embeddingSeed.EmbedAllMissingAsync(ct);
        return Ok(new { embeddedCount = count });
    }

    [HttpPost("destinations")]
    public async Task<ActionResult<DestinationDto>> Create(CreateDestinationRequest request, CancellationToken ct)
    {
        if (await db.Destinations.AnyAsync(d => d.Slug == request.Slug, ct))
            throw new InvalidOperationException("Destination slug already exists.");

        var dest = new Destination
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Slug = request.Slug,
            Description = request.Description,
            Province = request.Province,
            Region = request.Region,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Category = request.Category,
            EstimatedCost = request.EstimatedCost,
            OpeningHours = request.OpeningHours,
            ImageUrl = request.ImageUrl,
            BestTimeToVisit = request.BestTimeToVisit,
            SuitableWeather = request.SuitableWeather,
            TravelStyle = request.TravelStyle,
            AiRecommendationNote = request.AiRecommendationNote,
            EmbeddingText = request.EmbeddingText ?? $"{request.Name} {request.Province} {request.Category}",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        db.Destinations.Add(dest);
        await db.SaveChangesAsync(ct);
        await ai.UpdateDestinationEmbeddingAsync(dest.Id, ct);
        return Created($"/api/destinations/{dest.Id}", Map(dest));
    }

    [HttpPut("destinations/{id:guid}")]
    public async Task<ActionResult<DestinationDto>> Update(Guid id, UpdateDestinationRequest request, CancellationToken ct)
    {
        var dest = await db.Destinations.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Destination not found.");

        if (!string.IsNullOrWhiteSpace(request.Slug) &&
            await db.Destinations.AnyAsync(d => d.Id != id && d.Slug == request.Slug, ct))
        {
            throw new InvalidOperationException("Destination slug already exists.");
        }

        var shouldRegenerateEmbedding = false;

        if (!string.IsNullOrWhiteSpace(request.Name) && dest.Name != request.Name)
        {
            dest.Name = request.Name;
            shouldRegenerateEmbedding = true;
        }
        if (!string.IsNullOrWhiteSpace(request.Slug)) dest.Slug = request.Slug;
        if (!string.IsNullOrWhiteSpace(request.Description) && dest.Description != request.Description)
        {
            dest.Description = request.Description;
            shouldRegenerateEmbedding = true;
        }
        if (!string.IsNullOrWhiteSpace(request.Province) && dest.Province != request.Province)
        {
            dest.Province = request.Province;
            shouldRegenerateEmbedding = true;
        }
        if (!string.IsNullOrWhiteSpace(request.Region) && dest.Region != request.Region)
        {
            dest.Region = request.Region;
            shouldRegenerateEmbedding = true;
        }
        if (request.Latitude.HasValue) dest.Latitude = request.Latitude.Value;
        if (request.Longitude.HasValue) dest.Longitude = request.Longitude.Value;
        if (!string.IsNullOrWhiteSpace(request.Category) && dest.Category != request.Category)
        {
            dest.Category = request.Category;
            shouldRegenerateEmbedding = true;
        }
        if (request.EstimatedCost.HasValue) dest.EstimatedCost = request.EstimatedCost.Value;
        if (!string.IsNullOrWhiteSpace(request.CostUnit)) dest.CostUnit = request.CostUnit;
        if (request.OpeningHours is not null) dest.OpeningHours = request.OpeningHours;
        if (request.ImageUrl is not null) dest.ImageUrl = request.ImageUrl;
        if (request.BestTimeToVisit is not null) dest.BestTimeToVisit = request.BestTimeToVisit;
        if (request.SuitableWeather is not null)
        {
            dest.SuitableWeather = request.SuitableWeather;
            shouldRegenerateEmbedding = true;
        }
        if (request.TravelStyle is not null)
        {
            dest.TravelStyle = request.TravelStyle;
            shouldRegenerateEmbedding = true;
        }
        if (request.AiRecommendationNote is not null)
        {
            dest.AiRecommendationNote = request.AiRecommendationNote;
            shouldRegenerateEmbedding = true;
        }
        if (request.IsActive.HasValue) dest.IsActive = request.IsActive.Value;
        if (request.EmbeddingText is not null)
        {
            dest.EmbeddingText = request.EmbeddingText;
            shouldRegenerateEmbedding = true;
        }

        dest.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        if (shouldRegenerateEmbedding)
            await ai.UpdateDestinationEmbeddingAsync(dest.Id, ct);

        return Ok(Map(dest));
    }

    [HttpDelete("destinations/{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var dest = await db.Destinations.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Destination not found.");

        dest.IsActive = false;
        dest.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("destinations/{id:guid}/regenerate-embedding")]
    public async Task<IActionResult> RegenerateEmbedding(Guid id, CancellationToken ct)
    {
        await ai.UpdateDestinationEmbeddingAsync(id, ct);
        return NoContent();
    }

    [HttpGet("comments/pending")]
    public async Task<ActionResult<IEnumerable<PendingCommentDto>>> PendingComments(CancellationToken ct)
    {
        var comments = await db.Comments.AsNoTracking()
            .Where(c => !c.IsApproved)
            .Include(c => c.Destination)
            .Include(c => c.User)
            .OrderBy(c => c.CreatedAt)
            .Take(50)
            .ToListAsync(ct);

        return Ok(comments.Select(c => new PendingCommentDto(
            c.Id,
            c.DestinationId,
            c.Destination.Name,
            c.UserId,
            c.User.Username,
            c.User.FullName,
            c.Rating,
            c.Content,
            c.CreatedAt,
            c.UpdatedAt)));
    }

    [HttpPatch("comments/{id:guid}/approve")]
    public async Task<IActionResult> ApproveComment(Guid id, CancellationToken ct)
    {
        var c = await db.Comments.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Comment not found.");
        c.IsApproved = true;
        c.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPatch("comments/{id:guid}/reject")]
    public async Task<IActionResult> RejectComment(Guid id, CancellationToken ct)
    {
        var c = await db.Comments.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Comment not found.");
        db.Comments.Remove(c);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private static DestinationDto Map(Destination dest) =>
        new(dest.Id, dest.Name, dest.Slug, dest.Description, dest.Province, dest.Region,
            dest.Category, dest.EstimatedCost, dest.CostUnit, dest.ImageUrl);
}
