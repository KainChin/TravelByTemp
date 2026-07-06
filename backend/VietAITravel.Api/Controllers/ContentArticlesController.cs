using System.Security.Claims;
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
[Route("api/content/articles")]
[Authorize(Roles = RoleNames.TravelManager + "," + RoleNames.Admin)]
public class ContentArticlesController(AppDbContext db, ContentActivityService activity) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PaginatedArticlesResponse>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null,
        [FromQuery] string? articleType = null,
        [FromQuery] string? category = null,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = db.ContentArticles.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(status)) query = query.Where(a => a.Status == status);
        if (!string.IsNullOrWhiteSpace(articleType)) query = query.Where(a => a.ArticleType == articleType);
        if (!string.IsNullOrWhiteSpace(category)) query = query.Where(a => a.Category == category);

        query = query.OrderByDescending(a => a.CreatedAt);

        var total = await query.CountAsync(ct);
        var items = await query
            .Include(a => a.Author)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return Ok(new PaginatedArticlesResponse(
            items.Select(MapListItem).ToList(),
            page, pageSize, total,
            total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize)));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ArticleDetailDto>> Get(Guid id, CancellationToken ct)
    {
        var article = await db.ContentArticles.AsNoTracking()
            .Include(a => a.Author)
            .FirstOrDefaultAsync(a => a.Id == id, ct);

        if (article == null) return NotFound();
        return Ok(MapDetail(article));
    }

    [HttpPost]
    public async Task<ActionResult<ArticleDetailDto>> Create(CreateArticleRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        if (await db.ContentArticles.AnyAsync(a => a.Slug == request.Slug, ct))
            throw new InvalidOperationException("Slug đã tồn tại.");

        var status = ContentAuthorization.NormalizeStatus(request.Status, User, "draft");
        var now = DateTime.UtcNow;
        var article = new ContentArticle
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Slug = request.Slug,
            Summary = request.Summary,
            Content = HtmlSanitizer.Sanitize(request.Content),
            ArticleType = request.ArticleType,
            Category = request.Category,
            Status = status,
            AuthorId = userId,
            ThumbnailUrl = request.ThumbnailUrl,
            DestinationId = request.DestinationId,
            CreatedAt = now,
            PublishedAt = status == "published" ? now : null
        };

        db.ContentArticles.Add(article);
        await db.SaveChangesAsync(ct);

        await activity.LogAsync(userId, "create_article",
            $"Đăng bài viết mới \"{article.Title}\"",
            "article", article.Id, ct);

        var created = await db.ContentArticles.AsNoTracking()
            .Include(a => a.Author)
            .FirstAsync(a => a.Id == article.Id, ct);

        return Created($"/api/content/articles/{article.Id}", MapDetail(created));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ArticleDetailDto>> Update(Guid id, UpdateArticleRequest request, CancellationToken ct)
    {
        var article = await db.ContentArticles
            .Include(a => a.Author)
            .FirstOrDefaultAsync(a => a.Id == id, ct)
            ?? throw new KeyNotFoundException("Không tìm thấy bài viết.");

        if (!string.IsNullOrWhiteSpace(request.Slug) && request.Slug != article.Slug &&
            await db.ContentArticles.AnyAsync(a => a.Id != id && a.Slug == request.Slug, ct))
            throw new InvalidOperationException("Slug đã tồn tại.");

        if (!string.IsNullOrWhiteSpace(request.Title)) article.Title = request.Title;
        if (!string.IsNullOrWhiteSpace(request.Slug)) article.Slug = request.Slug;
        if (request.Summary is not null) article.Summary = request.Summary;
        if (!string.IsNullOrWhiteSpace(request.Content)) article.Content = HtmlSanitizer.Sanitize(request.Content);
        if (!string.IsNullOrWhiteSpace(request.ArticleType)) article.ArticleType = request.ArticleType;
        if (!string.IsNullOrWhiteSpace(request.Category)) article.Category = request.Category;
        if (!string.IsNullOrWhiteSpace(request.Status))
        {
            var targetStatus = ContentAuthorization.NormalizeStatus(request.Status, User, article.Status);
            var wasPublished = article.Status == "published";
            article.Status = targetStatus;
            if (targetStatus == "published" && !wasPublished)
                article.PublishedAt = DateTime.UtcNow;
        }
        if (request.ThumbnailUrl is not null) article.ThumbnailUrl = request.ThumbnailUrl;
        if (request.DestinationId.HasValue) article.DestinationId = request.DestinationId;

        article.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        await activity.LogAsync(GetUserId(), "update_article",
            $"Cập nhật bài viết \"{article.Title}\"",
            "article", article.Id, ct);

        return Ok(MapDetail(article));
    }

    [HttpPatch("{id:guid}/publish")]
    public async Task<IActionResult> Publish(Guid id, CancellationToken ct)
    {
        ContentAuthorization.EnsureCanPublish(User);

        var article = await db.ContentArticles.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy bài viết.");

        article.Status = "published";
        article.PublishedAt = DateTime.UtcNow;
        article.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        await activity.LogAsync(GetUserId(), "publish_article",
            $"Xuất bản bài viết \"{article.Title}\"",
            "article", article.Id, ct);

        return NoContent();
    }

    [HttpPost("bulk-publish")]
    public async Task<IActionResult> BulkPublish(BulkPublishRequest request, CancellationToken ct)
    {
        ContentAuthorization.EnsureCanPublish(User);
        if (request.Ids.Count == 0) return NoContent();

        var articles = await db.ContentArticles.Where(a => request.Ids.Contains(a.Id)).ToListAsync(ct);
        var now = DateTime.UtcNow;
        foreach (var article in articles)
        {
            article.Status = "published";
            article.PublishedAt = now;
            article.UpdatedAt = now;
        }
        await db.SaveChangesAsync(ct);

        var userId = GetUserId();
        foreach (var article in articles)
            await activity.LogAsync(userId, "publish_article", $"Xuất bản bài viết \"{article.Title}\"", "article", article.Id, ct);

        return Ok(new { published = articles.Count });
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        var article = await db.ContentArticles.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy bài viết.");

        db.ContentArticles.Remove(article);
        await db.SaveChangesAsync(ct);

        await activity.LogAsync(GetUserId(), "delete_article",
            $"Xóa bài viết \"{article.Title}\"",
            "article", article.Id, ct);

        return NoContent();
    }

    private Guid GetUserId()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(id!);
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
