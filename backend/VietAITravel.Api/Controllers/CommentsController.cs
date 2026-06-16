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
[Route("api")]
public class CommentsController(AppDbContext db) : ControllerBase
{
    [HttpGet("destinations/{destinationId:guid}/comments")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<CommentDto>>> ListByDestination(Guid destinationId, CancellationToken ct)
    {
        var exists = await db.Destinations.AsNoTracking()
            .AnyAsync(d => d.Id == destinationId && d.IsActive, ct);
        if (!exists)
            throw new KeyNotFoundException("Destination not found.");

        var comments = await db.Comments.AsNoTracking()
            .Where(c => c.DestinationId == destinationId && c.IsApproved)
            .Include(c => c.User)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(ct);

        return Ok(comments.Select(Map));
    }

    [HttpPost("destinations/{destinationId:guid}/comments")]
    [Authorize(Roles = RoleNames.Traveler + "," + RoleNames.Admin)]
    public async Task<ActionResult<CommentDto>> Create(
        Guid destinationId,
        CreateCommentRequest request,
        CancellationToken ct)
    {
        ValidateRating(request.Rating);

        var destinationExists = await db.Destinations.AsNoTracking()
            .AnyAsync(d => d.Id == destinationId && d.IsActive, ct);
        if (!destinationExists)
            throw new KeyNotFoundException("Destination not found.");

        var userId = GetUserId();
        if (await db.Comments.AnyAsync(c => c.UserId == userId && c.DestinationId == destinationId, ct))
            throw new InvalidOperationException("You have already commented on this destination.");

        var comment = new Comment
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DestinationId = destinationId,
            Rating = request.Rating,
            Content = request.Content,
            IsApproved = false,
            CreatedAt = DateTime.UtcNow
        };

        db.Comments.Add(comment);
        await db.SaveChangesAsync(ct);

        await db.Entry(comment).Reference(c => c.User).LoadAsync(ct);
        return Created($"/api/comments/{comment.Id}", Map(comment));
    }

    [HttpPut("comments/{id:guid}")]
    [Authorize(Roles = RoleNames.Traveler + "," + RoleNames.Admin)]
    public async Task<ActionResult<CommentDto>> Update(Guid id, UpdateCommentRequest request, CancellationToken ct)
    {
        var comment = await db.Comments
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new KeyNotFoundException("Comment not found.");

        var userId = GetUserId();
        if (comment.UserId != userId && !User.IsInRole(RoleNames.Admin))
            return Forbid();

        if (request.Rating.HasValue)
        {
            ValidateRating(request.Rating.Value);
            comment.Rating = request.Rating.Value;
        }
        if (request.Content is not null)
            comment.Content = request.Content;

        comment.IsApproved = false;
        comment.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return Ok(Map(comment));
    }

    [HttpDelete("comments/{id:guid}")]
    [Authorize(Roles = RoleNames.Traveler + "," + RoleNames.Admin)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var comment = await db.Comments.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Comment not found.");

        var userId = GetUserId();
        if (comment.UserId != userId && !User.IsInRole(RoleNames.Admin))
            return Forbid();

        db.Comments.Remove(comment);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Guid GetUserId() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static void ValidateRating(int rating)
    {
        if (rating is < 1 or > 5)
            throw new ArgumentException("Rating must be between 1 and 5.");
    }

    private static CommentDto Map(Comment comment) =>
        new(
            comment.Id,
            comment.DestinationId,
            comment.UserId,
            comment.User.Username,
            comment.User.FullName,
            comment.Rating,
            comment.Content,
            comment.IsApproved,
            comment.CreatedAt,
            comment.UpdatedAt);
}
