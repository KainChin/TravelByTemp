using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = RoleNames.Admin)]
public class AdminController(AppDbContext db) : ControllerBase
{
    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<AdminUserDto>>> ListUsers(CancellationToken ct)
    {
        var users = await db.Users.AsNoTracking()
            .Include(u => u.Role)
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new AdminUserDto(
                u.Id, u.Username, u.Email, u.FullName, u.Role.Name, u.IsActive, u.CreatedAt))
            .ToListAsync(ct);
        return Ok(users);
    }

    [HttpPost("users")]
    public async Task<ActionResult<AdminUserDto>> CreateUser(CreateAdminUserRequest request, CancellationToken ct)
    {
        if (await db.Users.AnyAsync(u => u.Username == request.Username || u.Email == request.Email, ct))
            throw new InvalidOperationException("Username hoặc email đã tồn tại.");

        var role = await db.Roles.FirstOrDefaultAsync(r => r.Name == request.Role, ct)
            ?? throw new InvalidOperationException("Role không hợp lệ.");

        if (role.Name == RoleNames.Traveler)
            throw new InvalidOperationException("Không thể tạo tài khoản Traveler qua admin CMS.");

        var user = new Entities.User
        {
            Id = Guid.NewGuid(),
            RoleId = role.Id,
            Username = request.Username.Trim(),
            Email = request.Email.Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            FullName = request.FullName.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return Created($"/api/admin/users/{user.Id}",
            new AdminUserDto(user.Id, user.Username, user.Email, user.FullName, role.Name, user.IsActive, user.CreatedAt));
    }

    [HttpPatch("users/{id:guid}/role")]
    public async Task<IActionResult> UpdateRole(Guid id, UpdateAdminUserRoleRequest request, CancellationToken ct)
    {
        var user = await db.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == id, ct)
            ?? throw new KeyNotFoundException("Không tìm thấy user.");

        var role = await db.Roles.FirstOrDefaultAsync(r => r.Name == request.Role, ct)
            ?? throw new InvalidOperationException("Role không hợp lệ.");

        user.RoleId = role.Id;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPatch("users/{id:guid}/toggle-active")]
    public async Task<IActionResult> ToggleUser(Guid id, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct)
            ?? throw new KeyNotFoundException("Không tìm thấy user.");
        user.IsActive = !user.IsActive;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpGet("health")]
    [AllowAnonymous]
    public IActionResult Health() => Ok(new { status = "ok", service = "VietAI Travel API", timestamp = DateTime.UtcNow });
}
