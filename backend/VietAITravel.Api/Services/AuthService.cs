using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Services;

public class JwtOptions
{
    public string SecretKey { get; set; } = "";
    public string Issuer { get; set; } = "VietAITravel";
    public string Audience { get; set; } = "VietAITravelUsers";
    public int ExpiryMinutes { get; set; } = 60;
}

public class AuthService(AppDbContext db, JwtOptions jwt)
{
    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        if (await db.Users.AnyAsync(u => u.Username == request.Username || u.Email == request.Email, ct))
            throw new InvalidOperationException("Username hoặc email đã tồn tại.");

        var role = await db.Roles.FirstAsync(r => r.Name == RoleNames.Traveler, ct);
        var user = new User
        {
            Id = Guid.NewGuid(),
            RoleId = role.Id,
            Username = request.Username,
            Email = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            FullName = request.FullName,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var user = await db.Users.Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == request.Username, ct)
            ?? throw new UnauthorizedAccessException("Sai tên đăng nhập hoặc mật khẩu.");

        if (!user.IsActive || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Sai tên đăng nhập hoặc mật khẩu.");

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> RefreshAsync(string refreshToken, CancellationToken ct = default)
    {
        var stored = await db.RefreshTokens.Include(t => t.User).ThenInclude(u => u.Role)
            .FirstOrDefaultAsync(t => t.Token == refreshToken && !t.IsRevoked, ct)
            ?? throw new UnauthorizedAccessException("Refresh token không hợp lệ.");

        if (stored.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedAccessException("Refresh token đã hết hạn.");

        stored.IsRevoked = true;
        await db.SaveChangesAsync(ct);
        return await IssueTokensAsync(stored.User, ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, CancellationToken ct)
    {
        var expires = DateTime.UtcNow.AddMinutes(jwt.ExpiryMinutes);
        var accessToken = GenerateJwt(user, expires);
        var refresh = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Token = refresh,
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync(ct);

        return new AuthResponse(accessToken, refresh, expires, ToDto(user));
    }

    private string GenerateJwt(User user, DateTime expires)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SecretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role.Name)
        };

        var token = new JwtSecurityToken(
            issuer: jwt.Issuer,
            audience: jwt.Audience,
            claims: claims,
            expires: expires,
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public static UserDto ToDto(User user) =>
        new(user.Id, user.Username, user.Email, user.FullName, user.Role.Name);
}
