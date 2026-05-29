using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Constants;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = RoleNames.Admin)]
public class AdminController(AppDbContext db) : ControllerBase
{
    [HttpGet("users")]
    public async Task<ActionResult> ListUsers(CancellationToken ct)
    {
        var users = await db.Users.AsNoTracking()
            .Include(u => u.Role)
            .Select(u => new
            {
                u.Id,
                u.Username,
                u.Email,
                u.FullName,
                Role = u.Role.Name,
                u.IsActive,
                u.CreatedAt
            })
            .ToListAsync(ct);
        return Ok(users);
    }

    [HttpPatch("users/{id:guid}/toggle-active")]
    public async Task<IActionResult> ToggleUser(Guid id, CancellationToken ct)
    {
        var user = await db.Users.FindAsync([id], ct);
        if (user == null) return NotFound();
        user.IsActive = !user.IsActive;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpGet("health")]
    [AllowAnonymous]
    public IActionResult Health() => Ok(new { status = "ok", service = "VietAI Travel API" });
}
