using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/content/dashboard")]
[Authorize(Roles = RoleNames.TravelManager + "," + RoleNames.Admin)]
public class ContentDashboardController(AppDbContext db) : ControllerBase
{
    [HttpGet("stats")]
    public async Task<ActionResult<DashboardStatsResponse>> GetStats(CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var thisMonthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var lastMonthStart = thisMonthStart.AddMonths(-1);

        async Task<(long current, long previous)> CountWithTrend(
            Func<IQueryable<Entities.ContentArticle>, IQueryable<Entities.ContentArticle>> filter)
        {
            var q = filter(db.ContentArticles.AsNoTracking());
            var current = await q.CountAsync(a => a.CreatedAt >= thisMonthStart, ct);
            var previous = await q.CountAsync(a => a.CreatedAt >= lastMonthStart && a.CreatedAt < thisMonthStart, ct);
            return (current, previous);
        }

        var totalArticles = await db.ContentArticles.CountAsync(a => a.ArticleType == "article", ct);
        var totalNews = await db.ContentArticles.CountAsync(a => a.ArticleType == "news", ct);
        var totalDestinations = await db.Destinations.CountAsync(d => d.IsActive, ct);
        var pendingArticles = await db.ContentArticles.CountAsync(a => a.Status == "pending", ct);

        var (articlesCur, articlesPrev) = await CountWithTrend(q => q.Where(a => a.ArticleType == "article"));
        var (newsCur, newsPrev) = await CountWithTrend(q => q.Where(a => a.ArticleType == "news"));
        var (destCur, destPrev) = (
            await db.Destinations.CountAsync(d => d.IsActive && d.CreatedAt >= thisMonthStart, ct),
            await db.Destinations.CountAsync(d => d.IsActive && d.CreatedAt >= lastMonthStart && d.CreatedAt < thisMonthStart, ct));
        var (pendingCur, pendingPrev) = await CountWithTrend(q => q.Where(a => a.Status == "pending"));

        return Ok(new DashboardStatsResponse([
            new("totalArticles", "Tổng bài viết", totalArticles, CalcChange(articlesCur, articlesPrev), "green"),
            new("travelNews", "Tin tức du lịch", totalNews, CalcChange(newsCur, newsPrev), "blue"),
            new("destinations", "Địa điểm du lịch", totalDestinations, CalcChange(destCur, destPrev), "purple"),
            new("pending", "Bài chờ duyệt", pendingArticles, CalcChange(pendingCur, pendingPrev), "orange")
        ]));
    }

    [HttpGet("recent-articles")]
    public async Task<ActionResult<PaginatedArticlesResponse>> RecentArticles(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 3,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = db.ContentArticles.AsNoTracking()
            .Where(a => a.ArticleType == "article")
            .OrderByDescending(a => a.CreatedAt);

        var total = await query.CountAsync(ct);
        var rows = await query
            .Include(a => a.Author)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var items = rows.Select(MapListItem).ToList();

        return Ok(new PaginatedArticlesResponse(
            items, page, pageSize, total,
            total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize)));
    }

    [HttpGet("popular-destinations")]
    public async Task<ActionResult<IReadOnlyList<PopularDestinationDto>>> PopularDestinations(
        [FromQuery] int limit = 5,
        CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 20);

        var articleCounts = await db.ContentArticles.AsNoTracking()
            .Where(a => a.DestinationId != null && a.Status == "published")
            .GroupBy(a => a.DestinationId!.Value)
            .Select(g => new { DestinationId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.DestinationId, x => x.Count, ct);

        var destinations = await db.Destinations.AsNoTracking()
            .Where(d => d.IsActive)
            .Take(limit * 3)
            .ToListAsync(ct);

        var result = destinations
            .Select(d =>
            {
                var articles = articleCounts.GetValueOrDefault(d.Id, 0);
                return new PopularDestinationDto(
                    d.Id,
                    d.Name,
                    d.ImageUrl,
                    (articles + 1) * 12500L + articles * 800L,
                    articles);
            })
            .OrderByDescending(d => d.ViewCount)
            .ThenBy(d => d.Name)
            .Take(limit)
            .ToList();

        return Ok(result);
    }

    [HttpGet("recent-activity")]
    public async Task<ActionResult<IReadOnlyList<ActivityLogDto>>> RecentActivity(
        [FromQuery] int limit = 6,
        CancellationToken ct = default)
    {
        limit = Math.Clamp(limit, 1, 50);

        var logs = await db.ContentActivityLogs.AsNoTracking()
            .Include(l => l.User)
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit)
            .Select(l => new ActivityLogDto(
                l.Id,
                l.ActionType,
                l.Description,
                l.User.FullName,
                null,
                l.CreatedAt))
            .ToListAsync(ct);

        return Ok(logs);
    }

    [HttpGet("activity")]
    public async Task<ActionResult<PaginatedActivityLogsResponse>> ActivityLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = db.ContentActivityLogs.AsNoTracking().OrderByDescending(l => l.CreatedAt);
        var total = await query.CountAsync(ct);
        var totalPages = total == 0 ? 0 : (int)Math.Ceiling(total / (double)pageSize);

        var logs = await query
            .Include(l => l.User)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new ActivityLogDto(
                l.Id,
                l.ActionType,
                l.Description,
                l.User.FullName,
                null,
                l.CreatedAt))
            .ToListAsync(ct);

        return Ok(new PaginatedActivityLogsResponse(logs, page, pageSize, total, totalPages));
    }

    [HttpGet("permissions")]
    public ActionResult<DashboardPermissionsResponse> Permissions()
    {
        var role = User.FindFirstValue(ClaimTypes.Role) ?? RoleNames.TravelManager;
        var isAdmin = role == RoleNames.Admin;

        var permissions = new List<PermissionDto>
        {
            new("manage_destinations", "Quản lý địa điểm du lịch", true),
            new("manage_articles", "Quản lý bài viết", true),
            new("manage_news", "Quản lý tin tức du lịch", true),
            new("manage_banners", "Quản lý banner", true),
            new("manage_gallery", "Quản lý thư viện ảnh", true),
            new("manage_featured", "Quản lý nội dung nổi bật", true),
            new("approve_content", "Duyệt / xuất bản nội dung", isAdmin),
            new("manage_users", "Quản lý người dùng", isAdmin),
            new("moderate_comments", "Kiểm duyệt bình luận", true),
        };

        var displayRole = role == RoleNames.Admin ? "Admin" : "Content Manager";
        return Ok(new DashboardPermissionsResponse(displayRole, isAdmin, permissions));
    }

    [HttpGet("inbox")]
    public async Task<ActionResult<InboxSummaryDto>> Inbox(CancellationToken ct)
    {
        var pendingArticles = await db.ContentArticles.CountAsync(a => a.Status == "pending", ct);
        var pendingComments = await db.Comments.CountAsync(c => !c.IsApproved, ct);
        return Ok(new InboxSummaryDto(pendingArticles, pendingComments));
    }

    [HttpGet("search")]
    public async Task<ActionResult<SearchResponse>> Search(
        [FromQuery] string q,
        [FromQuery] int limit = 10,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new SearchResponse([]));

        limit = Math.Clamp(limit, 1, 30);
        var term = q.Trim().ToLower();

        var articles = await db.ContentArticles.AsNoTracking()
            .Where(a => a.Title.ToLower().Contains(term) || a.Summary != null && a.Summary.ToLower().Contains(term))
            .OrderByDescending(a => a.CreatedAt)
            .Take(limit)
            .Select(a => new SearchResultDto("article", a.Id, a.Title, a.Summary, a.ThumbnailUrl))
            .ToListAsync(ct);

        var destinations = await db.Destinations.AsNoTracking()
            .Where(d => d.IsActive && (d.Name.ToLower().Contains(term) || d.Province.ToLower().Contains(term)))
            .OrderByDescending(d => d.Name)
            .Take(limit)
            .Select(d => new SearchResultDto("destination", d.Id, d.Name, d.Province, d.ImageUrl))
            .ToListAsync(ct);

        var combined = articles.Concat(destinations).Take(limit).ToList();
        return Ok(new SearchResponse(combined));
    }

    private static double CalcChange(long current, long previous)
    {
        if (previous == 0) return current > 0 ? 100 : 0;
        return Math.Round((current - previous) / (double)previous * 100, 1);
    }

    private static ArticleListItemDto MapListItem(Entities.ContentArticle a) =>
        new(
            a.Id,
            a.Title,
            a.Slug,
            a.Category,
            ContentLabels.CategoryLabel(a.Category),
            a.Status,
            ContentLabels.StatusLabel(a.Status),
            a.ThumbnailUrl,
            new ArticleAuthorDto(a.Author.Id, a.Author.FullName, a.Author.AvatarUrl),
            a.CreatedAt,
            a.PublishedAt);
}
