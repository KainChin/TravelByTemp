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
[Route("api/content")]
[Authorize(Roles = RoleNames.TravelManager + "," + RoleNames.Admin)]
public class ContentAssetsController(AppDbContext db, ContentActivityService activity) : ControllerBase
{
    // ── Banners ──

    [HttpGet("banners")]
    public async Task<ActionResult<IReadOnlyList<BannerDto>>> Banners(CancellationToken ct)
    {
        var items = await db.Banners.AsNoTracking()
            .OrderBy(b => b.SortOrder)
            .ThenByDescending(b => b.CreatedAt)
            .Select(b => new BannerDto(b.Id, b.Title, b.ImageUrl, b.LinkUrl, b.SortOrder, b.IsActive, b.Region, b.CreatedAt))
            .ToListAsync(ct);
        return Ok(items);
    }

    [HttpPost("banners")]
    public async Task<ActionResult<BannerDto>> CreateBanner(CreateBannerRequest request, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var banner = new Banner
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            ImageUrl = request.ImageUrl,
            LinkUrl = request.LinkUrl,
            SortOrder = request.SortOrder,
            IsActive = request.IsActive,
            Region = request.Region,
            CreatedAt = now
        };
        db.Banners.Add(banner);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "create_banner", $"Thêm banner \"{banner.Title}\"", "banner", banner.Id, ct);
        return Created($"/api/content/banners/{banner.Id}", MapBanner(banner));
    }

    [HttpPut("banners/{id:guid}")]
    public async Task<ActionResult<BannerDto>> UpdateBanner(Guid id, UpdateBannerRequest request, CancellationToken ct)
    {
        var banner = await db.Banners.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy banner.");

        if (!string.IsNullOrWhiteSpace(request.Title)) banner.Title = request.Title;
        if (!string.IsNullOrWhiteSpace(request.ImageUrl)) banner.ImageUrl = request.ImageUrl;
        if (request.LinkUrl is not null) banner.LinkUrl = request.LinkUrl;
        if (request.SortOrder.HasValue) banner.SortOrder = request.SortOrder.Value;
        if (request.IsActive.HasValue) banner.IsActive = request.IsActive.Value;
        if (!string.IsNullOrWhiteSpace(request.Region)) banner.Region = request.Region;
        banner.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "update_banner", $"Cập nhật banner \"{banner.Title}\"", "banner", banner.Id, ct);
        return Ok(MapBanner(banner));
    }

    [HttpDelete("banners/{id:guid}")]
    public async Task<IActionResult> DeleteBanner(Guid id, CancellationToken ct)
    {
        var banner = await db.Banners.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy banner.");
        var title = banner.Title;
        db.Banners.Remove(banner);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "delete_banner", $"Xóa banner \"{title}\"", "banner", id, ct);
        return NoContent();
    }

    // ── Gallery ──

    [HttpGet("gallery")]
    public async Task<ActionResult<IReadOnlyList<GalleryImageDto>>> Gallery(CancellationToken ct)
    {
        var items = await db.GalleryImages.AsNoTracking()
            .Include(g => g.Destination)
            .OrderBy(g => g.SortOrder)
            .ThenByDescending(g => g.CreatedAt)
            .Select(g => new GalleryImageDto(
                g.Id, g.Title, g.ImageUrl, g.DestinationId,
                g.Destination != null ? g.Destination.Name : null,
                g.SortOrder, g.CreatedAt))
            .ToListAsync(ct);
        return Ok(items);
    }

    [HttpPost("gallery")]
    public async Task<ActionResult<GalleryImageDto>> CreateGallery(CreateGalleryImageRequest request, CancellationToken ct)
    {
        var image = new GalleryImage
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            ImageUrl = request.ImageUrl,
            DestinationId = request.DestinationId,
            SortOrder = request.SortOrder,
            CreatedAt = DateTime.UtcNow
        };
        db.GalleryImages.Add(image);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "create_gallery", $"Thêm ảnh \"{image.Title}\"", "gallery", image.Id, ct);

        var destName = request.DestinationId.HasValue
            ? await db.Destinations.Where(d => d.Id == request.DestinationId).Select(d => d.Name).FirstOrDefaultAsync(ct)
            : null;

        return Created($"/api/content/gallery/{image.Id}",
            new GalleryImageDto(image.Id, image.Title, image.ImageUrl, image.DestinationId, destName, image.SortOrder, image.CreatedAt));
    }

    [HttpPut("gallery/{id:guid}")]
    public async Task<ActionResult<GalleryImageDto>> UpdateGallery(Guid id, UpdateGalleryImageRequest request, CancellationToken ct)
    {
        var image = await db.GalleryImages.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy ảnh.");

        if (!string.IsNullOrWhiteSpace(request.Title)) image.Title = request.Title;
        if (!string.IsNullOrWhiteSpace(request.ImageUrl)) image.ImageUrl = request.ImageUrl;
        image.DestinationId = request.DestinationId;
        if (request.SortOrder.HasValue) image.SortOrder = request.SortOrder.Value;

        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "update_gallery", $"Cập nhật ảnh \"{image.Title}\"", "gallery", image.Id, ct);

        var destName = image.DestinationId.HasValue
            ? await db.Destinations.Where(d => d.Id == image.DestinationId).Select(d => d.Name).FirstOrDefaultAsync(ct)
            : null;

        return Ok(new GalleryImageDto(image.Id, image.Title, image.ImageUrl, image.DestinationId, destName, image.SortOrder, image.CreatedAt));
    }

    [HttpDelete("gallery/{id:guid}")]
    public async Task<IActionResult> DeleteGallery(Guid id, CancellationToken ct)
    {
        var image = await db.GalleryImages.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy ảnh.");
        var title = image.Title;
        db.GalleryImages.Remove(image);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "delete_gallery", $"Xóa ảnh \"{title}\"", "gallery", id, ct);
        return NoContent();
    }

    // ── Featured ──

    [HttpGet("featured")]
    public async Task<ActionResult<IReadOnlyList<FeaturedContentDto>>> Featured(CancellationToken ct)
    {
        var items = await db.FeaturedContents.AsNoTracking()
            .OrderBy(f => f.SortOrder)
            .ThenByDescending(f => f.CreatedAt)
            .Select(f => new FeaturedContentDto(
                f.Id, f.Title, f.Subtitle, f.ImageUrl, f.LinkUrl,
                f.ContentType, f.IsActive, f.SortOrder, f.CreatedAt))
            .ToListAsync(ct);
        return Ok(items);
    }

    [HttpPost("featured")]
    public async Task<ActionResult<FeaturedContentDto>> CreateFeatured(CreateFeaturedContentRequest request, CancellationToken ct)
    {
        var item = new FeaturedContent
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Subtitle = request.Subtitle,
            ImageUrl = request.ImageUrl,
            LinkUrl = request.LinkUrl,
            ContentType = request.ContentType,
            IsActive = request.IsActive,
            SortOrder = request.SortOrder,
            CreatedAt = DateTime.UtcNow
        };
        db.FeaturedContents.Add(item);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "create_featured", $"Thêm nội dung nổi bật \"{item.Title}\"", "featured", item.Id, ct);
        return Created($"/api/content/featured/{item.Id}", MapFeatured(item));
    }

    [HttpPut("featured/{id:guid}")]
    public async Task<ActionResult<FeaturedContentDto>> UpdateFeatured(Guid id, UpdateFeaturedContentRequest request, CancellationToken ct)
    {
        var item = await db.FeaturedContents.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy nội dung nổi bật.");

        if (!string.IsNullOrWhiteSpace(request.Title)) item.Title = request.Title;
        if (request.Subtitle is not null) item.Subtitle = request.Subtitle;
        if (request.ImageUrl is not null) item.ImageUrl = request.ImageUrl;
        if (request.LinkUrl is not null) item.LinkUrl = request.LinkUrl;
        if (!string.IsNullOrWhiteSpace(request.ContentType)) item.ContentType = request.ContentType;
        if (request.IsActive.HasValue) item.IsActive = request.IsActive.Value;
        if (request.SortOrder.HasValue) item.SortOrder = request.SortOrder.Value;

        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "update_featured", $"Cập nhật nội dung nổi bật \"{item.Title}\"", "featured", item.Id, ct);
        return Ok(MapFeatured(item));
    }

    [HttpDelete("featured/{id:guid}")]
    public async Task<IActionResult> DeleteFeatured(Guid id, CancellationToken ct)
    {
        var item = await db.FeaturedContents.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy nội dung nổi bật.");
        var title = item.Title;
        db.FeaturedContents.Remove(item);
        await db.SaveChangesAsync(ct);
        await activity.LogAsync(GetUserId(), "delete_featured", $"Xóa nội dung nổi bật \"{title}\"", "featured", id, ct);
        return NoContent();
    }

    // ── Destinations (admin read) ──

    [HttpGet("destinations")]
    public async Task<ActionResult<IReadOnlyList<AdminDestinationDto>>> Destinations(
        [FromQuery] string? region,
        [FromQuery] string? category,
        CancellationToken ct)
    {
        var query = db.Destinations.AsNoTracking().Where(d => d.IsActive);
        if (!string.IsNullOrWhiteSpace(region)) query = query.Where(d => d.Region == region);
        if (!string.IsNullOrWhiteSpace(category)) query = query.Where(d => d.Category == category);

        var articleCounts = await GetArticleCountsAsync(ct);
        var list = await query.OrderBy(d => d.Name).ToListAsync(ct);
        var result = list.Select(d => new AdminDestinationDto(
            d.Id, d.Name, d.Province, d.Region, d.Category,
            d.ImageUrl, d.EstimatedCost, articleCounts.GetValueOrDefault(d.Id, 0))).ToList();
        return Ok(result);
    }

    [HttpGet("destinations/inactive")]
    public async Task<ActionResult<IReadOnlyList<AdminDestinationDto>>> InactiveDestinations(CancellationToken ct)
    {
        var articleCounts = await GetArticleCountsAsync(ct);
        var list = await db.Destinations.AsNoTracking()
            .Where(d => !d.IsActive)
            .OrderByDescending(d => d.UpdatedAt)
            .ThenBy(d => d.Name)
            .ToListAsync(ct);
        var result = list.Select(d => new AdminDestinationDto(
            d.Id, d.Name, d.Province, d.Region, d.Category,
            d.ImageUrl, d.EstimatedCost, articleCounts.GetValueOrDefault(d.Id, 0))).ToList();
        return Ok(result);
    }

    [HttpGet("destinations/{id:guid}")]
    public async Task<ActionResult<AdminDestinationDetailDto>> GetDestination(Guid id, CancellationToken ct)
    {
        var d = await db.Destinations.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, ct)
            ?? throw new KeyNotFoundException("Không tìm thấy địa điểm.");

        var articleCounts = await GetArticleCountsAsync(ct);
        return Ok(new AdminDestinationDetailDto(
            d.Id, d.Name, d.Slug, d.Description, d.Province, d.Region,
            d.Latitude, d.Longitude, d.Category, d.EstimatedCost,
            d.ImageUrl, d.IsActive, articleCounts.GetValueOrDefault(d.Id, 0)));
    }

    private async Task<Dictionary<Guid, int>> GetArticleCountsAsync(CancellationToken ct) =>
        await db.ContentArticles.AsNoTracking()
            .Where(a => a.DestinationId != null && a.Status == "published")
            .GroupBy(a => a.DestinationId!.Value)
            .Select(g => new { Id = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Id, x => x.Count, ct);

    private static BannerDto MapBanner(Banner b) =>
        new(b.Id, b.Title, b.ImageUrl, b.LinkUrl, b.SortOrder, b.IsActive, b.Region, b.CreatedAt);

    private static FeaturedContentDto MapFeatured(FeaturedContent f) =>
        new(f.Id, f.Title, f.Subtitle, f.ImageUrl, f.LinkUrl, f.ContentType, f.IsActive, f.SortOrder, f.CreatedAt);

    private Guid GetUserId()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(id!);
    }
}
