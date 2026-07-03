using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Data;

public static class ContentSeeder
{
    public static async Task SeedAsync(AppDbContext db, ILogger logger)
    {
        var manager = await db.Users.Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == "manager");
        if (manager == null)
        {
            logger.LogWarning("Manager user not found, skipping content seed.");
            return;
        }

        manager.FullName = "Content Manager";

        var destinations = await db.Destinations
            .Where(d => d.IsActive)
            .OrderBy(d => d.Name)
            .Take(10)
            .ToListAsync();

        var daNang = destinations.FirstOrDefault(d => d.Slug == "da-nang");
        var phuQuoc = destinations.FirstOrDefault(d => d.Slug == "phu-quoc");
        var hoiAn = destinations.FirstOrDefault(d => d.Slug == "pho-co-hoi-an");
        var daLat = destinations.FirstOrDefault(d => d.Slug == "thanh-pho-da-lat");
        var haLong = destinations.FirstOrDefault(d => d.Slug == "vinh-ha-long");

        var now = DateTime.UtcNow;
        var seededArticles = 0;

        if (!await db.ContentArticles.AnyAsync())
        {
            var articles = new List<ContentArticle>
            {
                MakeArticle(manager.Id, "Khám phá Đà Nẵng: 10 điểm đến không thể bỏ qua",
                    "kham-pha-da-nang-10-diem-den", "article", "destination", "published",
                    "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400",
                    daNang?.Id, now.AddDays(-2)),
                MakeArticle(manager.Id, "Kinh nghiệm du lịch Phú Quốc 3 ngày 2 đêm tiết kiệm",
                    "kinh-nghiem-phu-quoc-3-ngay", "article", "experience", "published",
                    "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400",
                    phuQuoc?.Id, now.AddDays(-5)),
                MakeArticle(manager.Id, "Hội An lung linh đèn lồng: Lịch trình 2 ngày hoàn hảo",
                    "hoi-an-den-long-2-ngay", "article", "destination", "pending",
                    "https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400",
                    hoiAn?.Id, now.AddDays(-1)),
                MakeArticle(manager.Id, "Đà Lạt mùa hoa: Gợi ý homestay và quán cafe view đẹp",
                    "da-lat-mua-hoa-homestay", "article", "experience", "draft",
                    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400",
                    daLat?.Id, now.AddHours(-12)),
                MakeArticle(manager.Id, "Vịnh Hạ Long được UNESCO công nhận di sản lần thứ hai",
                    "vinh-ha-long-unesco-2026", "news", "news", "published",
                    "https://images.unsplash.com/photo-1528181304800-259b08848526?w=400",
                    haLong?.Id, now.AddDays(-3)),
            };

            for (var i = 5; i < 245; i++)
            {
                var dest = destinations[i % destinations.Count];
                var status = i % 7 == 0 ? "pending" : i % 11 == 0 ? "draft" : "published";
                var type = i % 4 == 0 ? "news" : "article";
                var category = type == "news" ? "news" : i % 3 == 0 ? "experience" : "destination";
                articles.Add(MakeArticle(manager.Id,
                    $"Bài viết du lịch #{i + 1}: {dest.Name}",
                    $"bai-viet-du-lich-{i + 1}", type, category, status,
                    dest.ImageUrl, dest.Id, now.AddDays(-i)));
            }

            db.ContentArticles.AddRange(articles);
            seededArticles = articles.Count;

            if (!await db.ContentActivityLogs.AnyAsync())
            {
                db.ContentActivityLogs.AddRange(
                    Log(manager.Id, "publish_article", "Đăng bài viết mới \"Khám phá Đà Nẵng: 10 điểm đến không thể bỏ qua\"", now.AddMinutes(-10)),
                    Log(manager.Id, "update_destination", "Cập nhật thông tin địa điểm \"Phú Quốc\"", now.AddHours(-1)),
                    Log(manager.Id, "create_article", "Tạo bài viết \"Hội An lung linh đèn lồng\" chờ duyệt", now.AddHours(-2)),
                    Log(manager.Id, "publish_article", "Xuất bản tin tức \"Vịnh Hạ Long được UNESCO công nhận\"", now.AddHours(-5)),
                    Log(manager.Id, "update_destination", "Thêm ảnh mới cho địa điểm \"Đà Lạt\"", now.AddHours(-8)),
                    Log(manager.Id, "create_article", "Tạo bản nháp \"Đà Lạt mùa hoa\"", now.AddDays(-1)));
            }
        }

        if (!await db.Banners.AnyAsync())
        {
            db.Banners.AddRange(
                new Banner { Id = Guid.NewGuid(), Title = "Khám phá miền Trung", ImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800", SortOrder = 1, CreatedAt = now },
                new Banner { Id = Guid.NewGuid(), Title = "Phú Quốc - Thiên đường biển đảo", ImageUrl = "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800", SortOrder = 2, CreatedAt = now });
        }

        if (!await db.GalleryImages.AnyAsync())
        {
            db.GalleryImages.AddRange(
                new GalleryImage { Id = Guid.NewGuid(), Title = "Bãi biển Mỹ Khê", ImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600", DestinationId = daNang?.Id, SortOrder = 1, CreatedAt = now },
                new GalleryImage { Id = Guid.NewGuid(), Title = "Hoàng hôn Phú Quốc", ImageUrl = "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600", DestinationId = phuQuoc?.Id, SortOrder = 2, CreatedAt = now },
                new GalleryImage { Id = Guid.NewGuid(), Title = "Phố cổ Hội An", ImageUrl = "https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600", DestinationId = hoiAn?.Id, SortOrder = 3, CreatedAt = now });
        }

        if (!await db.FeaturedContents.AnyAsync())
        {
            db.FeaturedContents.AddRange(
                new FeaturedContent { Id = Guid.NewGuid(), Title = "Top 10 điểm đến mùa hè", Subtitle = "Gợi ý từ AI Travel", ImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800", ContentType = "article", SortOrder = 1, IsActive = true, CreatedAt = now },
                new FeaturedContent { Id = Guid.NewGuid(), Title = "Ẩm thực miền Trung", Subtitle = "Hành trình vị giác", ImageUrl = "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800", ContentType = "article", SortOrder = 2, IsActive = true, CreatedAt = now });
        }

        await db.SaveChangesAsync();
        logger.LogInformation("Content seed completed: {Count} new articles.", seededArticles);
    }

    private static ContentArticle MakeArticle(
        Guid authorId, string title, string slug, string type, string category, string status,
        string? thumb, Guid? destId, DateTime createdAt) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Slug = slug,
            Summary = $"Tóm tắt nội dung cho {title}",
            Content = $"<p>Nội dung chi tiết cho bài viết: {title}</p>",
            ArticleType = type,
            Category = category,
            Status = status,
            AuthorId = authorId,
            ThumbnailUrl = thumb,
            DestinationId = destId,
            CreatedAt = createdAt,
            PublishedAt = status == "published" ? createdAt : null
        };

    private static ContentActivityLog Log(Guid userId, string action, string desc, DateTime at) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ActionType = action,
            Description = desc,
            EntityType = "content",
            CreatedAt = at
        };
}
