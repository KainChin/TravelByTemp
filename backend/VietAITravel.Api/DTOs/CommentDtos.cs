namespace VietAITravel.Api.DTOs;

public record CommentDto(
    Guid Id,
    Guid DestinationId,
    Guid UserId,
    string Username,
    string FullName,
    int Rating,
    string? Content,
    bool IsApproved,
    DateTime CreatedAt,
    DateTime? UpdatedAt);

public record CreateCommentRequest(int Rating, string? Content);

public record UpdateCommentRequest(int? Rating, string? Content);

public record PendingCommentDto(
    Guid Id,
    Guid DestinationId,
    string DestinationName,
    Guid UserId,
    string Username,
    string FullName,
    int Rating,
    string? Content,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
