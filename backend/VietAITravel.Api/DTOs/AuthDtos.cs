namespace VietAITravel.Api.DTOs;

public record RegisterRequest(string Username, string? Email, string Password, string FullName, string? Phone = null);
public record BeginRegisterRequest(string Username, string? Email, string Password, string FullName, string? Phone = null);
public record BeginRegisterResponse(Guid VerificationId, DateTime ExpiresAt, string? DevCode);
public record VerifyRegisterRequest(Guid VerificationId, string Code);
public record LoginRequest(string Username, string Password);
public record RefreshRequest(string RefreshToken);
public record ResetPasswordRequest(string UsernameOrEmail, string NewPassword);
public record UpdateProfileRequest(string Username, string Email, string FullName, string? Bio, string? Phone, string? AvatarUrl);
public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, UserDto User);
public record UserDto(Guid Id, string Username, string Email, string FullName, string Role, string? Bio, string? Phone, string? AvatarUrl);
