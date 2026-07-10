namespace VietAITravel.Api.DTOs;

public record DashboardStatDto(string Key, string Label, long Count, double ChangePercent, string IconColor);

public record DashboardStatsResponse(IReadOnlyList<DashboardStatDto> Stats);

public record ArticleAuthorDto(Guid Id, string FullName, string? AvatarUrl);

public record ArticleListItemDto(
    Guid Id,
    string Title,
    string Slug,
    string Category,
    string CategoryLabel,
    string Status,
    string StatusLabel,
    string? ThumbnailUrl,
    ArticleAuthorDto Author,
    DateTime CreatedAt,
    DateTime? PublishedAt);

public record PaginatedArticlesResponse(
    IReadOnlyList<ArticleListItemDto> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);

public record PaginatedActivityLogsResponse(
    IReadOnlyList<ActivityLogDto> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);

public record PopularDestinationDto(
    Guid Id,
    string Name,
    string? ImageUrl,
    long ViewCount,
    int ArticleCount);

public record ActivityLogDto(
    Guid Id,
    string ActionType,
    string Description,
    string UserName,
    string? UserAvatarUrl,
    DateTime CreatedAt);

public record PermissionDto(string Key, string Label, bool Granted);

public record DashboardPermissionsResponse(string Role, bool CanPublish, IReadOnlyList<PermissionDto> Permissions);

public record SearchResultDto(
    string EntityType,
    Guid Id,
    string Title,
    string? Subtitle,
    string? ImageUrl);

public record SearchResponse(IReadOnlyList<SearchResultDto> Results);

public record InboxSummaryDto(int PendingArticles, int PendingComments);

public record BannerDto(
    Guid Id, string Title, string ImageUrl, string? LinkUrl,
    int SortOrder, bool IsActive, string Region, DateTime CreatedAt);

public record GalleryImageDto(
    Guid Id, string Title, string ImageUrl, Guid? DestinationId, string? DestinationName,
    int SortOrder, DateTime CreatedAt);

public record FeaturedContentDto(
    Guid Id, string Title, string? Subtitle, string? ImageUrl, string? LinkUrl,
    string ContentType, bool IsActive, int SortOrder, DateTime CreatedAt);

public record AdminDestinationDto(
    Guid Id, string Name, string Province, string Region, string Category,
    string? ImageUrl, decimal EstimatedCost, int ArticleCount);

public record AdminDestinationDetailDto(
    Guid Id, string Name, string Slug, string Description, string Province, string Region,
    decimal Latitude, decimal Longitude, string Category, decimal EstimatedCost,
    string? ImageUrl, bool IsActive, int ArticleCount);

public record CreateBannerRequest(
    string Title, string ImageUrl, string? LinkUrl, int SortOrder, bool IsActive, string Region);

public record UpdateBannerRequest(
    string? Title, string? ImageUrl, string? LinkUrl, int? SortOrder, bool? IsActive, string? Region);

public record CreateGalleryImageRequest(
    string Title, string ImageUrl, Guid? DestinationId, int SortOrder);

public record UpdateGalleryImageRequest(
    string? Title, string? ImageUrl, Guid? DestinationId, int? SortOrder);

public record CreateFeaturedContentRequest(
    string Title, string? Subtitle, string? ImageUrl, string? LinkUrl,
    string ContentType, bool IsActive, int SortOrder);

public record UpdateFeaturedContentRequest(
    string? Title, string? Subtitle, string? ImageUrl, string? LinkUrl,
    string? ContentType, bool? IsActive, int? SortOrder);

public record MediaUploadResponse(string Url, string FileName, long SizeBytes);

public record CreateArticleRequest(
    string Title,
    string Slug,
    string? Summary,
    string Content,
    string ArticleType,
    string Category,
    string Status,
    string? ThumbnailUrl,
    Guid? DestinationId);

public record UpdateArticleRequest(
    string? Title,
    string? Slug,
    string? Summary,
    string? Content,
    string? ArticleType,
    string? Category,
    string? Status,
    string? ThumbnailUrl,
    Guid? DestinationId);

public record ArticleDetailDto(
    Guid Id,
    string Title,
    string Slug,
    string? Summary,
    string Content,
    string ArticleType,
    string Category,
    string Status,
    string? ThumbnailUrl,
    Guid? DestinationId,
    long ViewCount,
    ArticleAuthorDto Author,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    DateTime? PublishedAt);

public record ChartStatDto(string Key, string Label, int Count);
public record DashboardChartStatsResponse(
    IReadOnlyList<ChartStatDto> Regions,
    IReadOnlyList<ChartStatDto> Categories,
    IReadOnlyList<ChartStatDto> Articles);
