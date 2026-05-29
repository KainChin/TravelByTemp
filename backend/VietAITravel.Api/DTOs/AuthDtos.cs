namespace VietAITravel.Api.DTOs;

public record RegisterRequest(string Username, string Email, string Password, string FullName);
public record LoginRequest(string Username, string Password);
public record RefreshRequest(string RefreshToken);
public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, UserDto User);
public record UserDto(Guid Id, string Username, string Email, string FullName, string Role);
