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
        var dto = new DestinationDto(dest.Id, dest.Name, dest.Slug, dest.Description, dest.Province, dest.Region,
            dest.Category, dest.EstimatedCost, dest.CostUnit, dest.ImageUrl);
        return Created($"/api/destinations/{dest.Id}", dto);
    }

    [HttpPost("destinations/{id:guid}/regenerate-embedding")]
    public async Task<IActionResult> RegenerateEmbedding(Guid id, CancellationToken ct)
    {
        await ai.UpdateDestinationEmbeddingAsync(id, ct);
        return NoContent();
    }

    [HttpGet("comments/pending")]
    public async Task<IActionResult> PendingComments(CancellationToken ct)
    {
        var comments = await db.Comments.AsNoTracking()
            .Where(c => !c.IsApproved)
            .Include(c => c.Destination)
            .Take(50)
            .ToListAsync(ct);
        return Ok(comments);
    }

    [HttpPatch("comments/{id:guid}/approve")]
    public async Task<IActionResult> ApproveComment(Guid id, CancellationToken ct)
    {
        var c = await db.Comments.FindAsync([id], ct);
        if (c == null) return NotFound();
        c.IsApproved = true;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
