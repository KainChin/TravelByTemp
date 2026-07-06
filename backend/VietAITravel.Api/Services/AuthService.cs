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
    private const string RegisterPurpose = "register";

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        var username = request.Username.Trim();
        var email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        var fullName = request.FullName.Trim();
        var phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();

        if (string.IsNullOrWhiteSpace(username))
            throw new ArgumentException("Username is required.");
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.");
        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            throw new ArgumentException("Password must be at least 6 characters.");

        if (phone is { Length: > 30 })
            throw new ArgumentException("Phone must be 30 characters or less.");

        if (email == null && phone == null)
            throw new ArgumentException("Email or phone is required.");

        if (await db.Users.AnyAsync(u => u.Username == username || (email != null && u.Email == email) || (phone != null && u.Phone == phone), ct))
            throw new InvalidOperationException("Username hoặc email đã tồn tại.");

        var role = await db.Roles.FirstAsync(r => r.Name == RoleNames.Traveler, ct);
        var user = new User
        {
            Id = Guid.NewGuid(),
            RoleId = role.Id,
            Username = username,
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            FullName = fullName,
            Phone = phone,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return await IssueTokensAsync(user, ct);
    }

    public async Task<BeginRegisterResponse> BeginRegisterAsync(BeginRegisterRequest request, CancellationToken ct = default)
    {
        var username = request.Username.Trim();
        var email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
        var fullName = request.FullName.Trim();
        var phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();

        if (string.IsNullOrWhiteSpace(username))
            throw new ArgumentException("Username is required.");
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.");
        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            throw new ArgumentException("Password must be at least 6 characters.");
        if (phone is { Length: > 30 })
            throw new ArgumentException("Phone must be 30 characters or less.");
        if (email == null && phone == null)
            throw new ArgumentException("Email or phone is required.");

        if (await db.Users.AnyAsync(u => u.Username == username || (email != null && u.Email == email) || (phone != null && u.Phone == phone), ct))
            throw new InvalidOperationException("Username, email hoặc số điện thoại đã tồn tại.");

        var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(10);
        var verification = new AuthVerificationCode
        {
            Id = Guid.NewGuid(),
            Purpose = RegisterPurpose,
            Username = username,
            Email = email,
            Phone = phone,
            FullName = fullName,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            ExpiresAt = expiresAt,
            CreatedAt = DateTime.UtcNow
        };

        db.AuthVerificationCodes.Add(verification);
        await db.SaveChangesAsync(ct);

        return new BeginRegisterResponse(verification.Id, expiresAt, code);
    }

    public async Task<AuthResponse> VerifyRegisterAsync(VerifyRegisterRequest request, CancellationToken ct = default)
    {
        var code = request.Code.Trim();
        if (string.IsNullOrWhiteSpace(code))
            throw new ArgumentException("Verification code is required.");

        var verification = await db.AuthVerificationCodes
            .FirstOrDefaultAsync(x => x.Id == request.VerificationId && x.Purpose == RegisterPurpose, ct)
            ?? throw new KeyNotFoundException("Verification request not found.");

        if (verification.ConsumedAt != null)
            throw new InvalidOperationException("Verification code was already used.");
        if (verification.ExpiresAt < DateTime.UtcNow)
            throw new InvalidOperationException("Verification code expired.");
        if (verification.Attempts >= 5)
            throw new InvalidOperationException("Too many invalid verification attempts.");

        if (!BCrypt.Net.BCrypt.Verify(code, verification.CodeHash))
        {
            verification.Attempts++;
            await db.SaveChangesAsync(ct);
            throw new UnauthorizedAccessException("Verification code is incorrect.");
        }

        if (await db.Users.AnyAsync(
                u => u.Username == verification.Username ||
                     (verification.Email != null && u.Email == verification.Email) ||
                     (verification.Phone != null && u.Phone == verification.Phone),
                ct))
            throw new InvalidOperationException("Username, email hoặc số điện thoại đã tồn tại.");

        var role = await db.Roles.FirstAsync(r => r.Name == RoleNames.Traveler, ct);
        var user = new User
        {
            Id = Guid.NewGuid(),
            RoleId = role.Id,
            Username = verification.Username,
            Email = verification.Email,
            Phone = verification.Phone,
            PasswordHash = verification.PasswordHash,
            FullName = verification.FullName,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        verification.ConsumedAt = DateTime.UtcNow;
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var login = request.Username.Trim();
        if (string.IsNullOrWhiteSpace(login))
            throw new ArgumentException("Username, email or phone is required.");
        var user = await db.Users.Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == login || u.Email == login || u.Phone == login, ct)
            ?? throw new UnauthorizedAccessException("Sai tên đăng nhập hoặc mật khẩu.");

        if (!user.IsActive || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Sai tên đăng nhập hoặc mật khẩu.");

        return await IssueTokensAsync(user, ct);
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request, CancellationToken ct = default)
    {
        var usernameOrEmail = request.UsernameOrEmail.Trim();
        if (string.IsNullOrWhiteSpace(usernameOrEmail))
            throw new ArgumentException("Username, email or phone is required.");
        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
            throw new ArgumentException("Password must be at least 6 characters.");

        var user = await db.Users
            .FirstOrDefaultAsync(
                u => u.IsActive && (u.Username == usernameOrEmail || u.Email == usernameOrEmail || u.Phone == usernameOrEmail),
                ct)
            ?? throw new KeyNotFoundException("Không tìm thấy tài khoản.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;

        await db.RefreshTokens
            .Where(t => t.UserId == user.Id && !t.IsRevoked)
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(t => t.IsRevoked, true),
                ct);

        await db.SaveChangesAsync(ct);
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

    public async Task<UserDto> GetProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Users.Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Id == userId && u.IsActive, ct)
            ?? throw new KeyNotFoundException("User not found.");

        return ToDto(user);
    }

    public async Task<UserDto> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken ct = default)
    {
        var username = request.Username.Trim();
        var email = request.Email.Trim();
        var fullName = request.FullName.Trim();
        var bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim();
        var phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();
        var avatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl) ? null : request.AvatarUrl.Trim();

        if (string.IsNullOrWhiteSpace(username))
            throw new ArgumentException("Username is required.");
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.");
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name is required.");
        if (bio is { Length: > 300 })
            throw new ArgumentException("Bio must be 300 characters or less.");
        if (phone is { Length: > 30 })
            throw new ArgumentException("Phone must be 30 characters or less.");
        if (avatarUrl is { Length: > 500 })
            throw new ArgumentException("Avatar URL must be 500 characters or less.");

        var user = await db.Users.Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Id == userId && u.IsActive, ct)
            ?? throw new KeyNotFoundException("User not found.");

        if (await db.Users.AnyAsync(u => u.Id != userId && u.Username == username, ct))
            throw new InvalidOperationException("Username already exists.");
        if (await db.Users.AnyAsync(u => u.Id != userId && u.Email == email, ct))
            throw new InvalidOperationException("Email already exists.");

        user.Username = username;
        user.Email = email;
        user.FullName = fullName;
        user.Bio = bio;
        user.Phone = phone;
        user.AvatarUrl = avatarUrl;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return ToDto(user);
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
            new Claim(ClaimTypes.Email, user.Email ?? ""),
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
        new(user.Id, user.Username, user.Email ?? "", user.FullName, user.Role.Name, user.Bio, user.Phone, user.AvatarUrl);
}
