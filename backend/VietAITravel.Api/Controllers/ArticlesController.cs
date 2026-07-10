using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/articles")]
[AllowAnonymous]
public class ArticlesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArticleListItemDto>>> List(
        [FromQuery] string? region,
        [FromQuery] string? category,
        [FromQuery] string? articleType,
        CancellationToken ct)
    {
        var query = db.ContentArticles.AsNoTracking()
            .Include(a => a.Author)
            .Include(a => a.Destination)
            .Where(a => a.Status == "published");

        if (!string.IsNullOrWhiteSpace(region))
        {
            query = query.Where(a => a.Destination != null && 
                                     a.Destination.Region.ToLower() == region.ToLower());
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            query = query.Where(a => a.Category.ToLower() == category.ToLower());
        }

        if (!string.IsNullOrWhiteSpace(articleType))
        {
            query = query.Where(a => a.ArticleType.ToLower() == articleType.ToLower());
        }

        query = query.OrderByDescending(a => a.PublishedAt ?? a.CreatedAt);

        var list = await query.ToListAsync(ct);

        return Ok(list.Select(MapListItem).ToList());
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ArticleDetailDto>> Get(Guid id, CancellationToken ct)
    {
        var article = await db.ContentArticles
            .Include(a => a.Author)
            .FirstOrDefaultAsync(a => a.Id == id && a.Status == "published", ct);

        if (article == null) return NotFound();

        article.ViewCount++;
        await db.SaveChangesAsync(ct);

        return Ok(MapDetail(article));
    }

    private static ArticleListItemDto MapListItem(ContentArticle a) =>
        new(
            a.Id, a.Title, a.Slug, a.Category,
            ContentLabels.CategoryLabel(a.Category),
            a.Status, ContentLabels.StatusLabel(a.Status),
            a.ThumbnailUrl,
            new ArticleAuthorDto(a.Author.Id, a.Author.FullName, a.Author.AvatarUrl),
            a.CreatedAt, a.PublishedAt);

    private static ArticleDetailDto MapDetail(ContentArticle a) =>
        new(
            a.Id, a.Title, a.Slug, a.Summary, a.Content,
            a.ArticleType, a.Category, a.Status, a.ThumbnailUrl,
            a.DestinationId, a.ViewCount,
            new ArticleAuthorDto(a.Author.Id, a.Author.FullName, a.Author.AvatarUrl),
            a.CreatedAt, a.UpdatedAt, a.PublishedAt);
}
