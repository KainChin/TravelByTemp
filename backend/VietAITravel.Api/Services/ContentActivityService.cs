using VietAITravel.Api.Data;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services;

public class ContentActivityService(AppDbContext db)
{
    public async Task LogAsync(
        Guid userId,
        string actionType,
        string description,
        string? entityType = null,
        Guid? entityId = null,
        CancellationToken ct = default)
    {
        db.ContentActivityLogs.Add(new ContentActivityLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ActionType = actionType,
            Description = description,
            EntityType = entityType,
            EntityId = entityId,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync(ct);
    }
}

public static class ContentLabels
{
    public static string CategoryLabel(string category) => category switch
    {
        "destination" => "Địa điểm",
        "experience" => "Kinh nghiệm",
        "news" => "Tin tức",
        _ => category
    };

    public static string StatusLabel(string status) => status switch
    {
        "published" => "Đã xuất bản",
        "pending" => "Chờ duyệt",
        "draft" => "Bản nháp",
        _ => status
    };
}
