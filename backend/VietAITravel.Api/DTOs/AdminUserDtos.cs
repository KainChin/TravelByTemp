namespace VietAITravel.Api.DTOs;

public record AdminUserDto(
    Guid Id,
    string Username,
    string Email,
    string FullName,
    string Role,
    bool IsActive,
    DateTime CreatedAt);

public record CreateAdminUserRequest(
    string Username,
    string Email,
    string Password,
    string FullName,
    string Role);

public record UpdateAdminUserRoleRequest(string Role);

public record BulkPublishRequest(IReadOnlyList<Guid> Ids);
