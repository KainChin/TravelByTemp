using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/banners")]
[AllowAnonymous]
public class BannersController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<BannerDto>>> List([FromQuery] string? region, CancellationToken ct)
    {
        var query = db.Banners.AsNoTracking().Where(b => b.IsActive);
        
        if (!string.IsNullOrWhiteSpace(region))
        {
            var r = region.Trim().ToLower();
            query = query.Where(b => b.Region.ToLower() == r);
        }

        var list = await query
            .OrderBy(b => b.SortOrder)
            .ThenByDescending(b => b.CreatedAt)
            .Select(b => new BannerDto(b.Id, b.Title, b.ImageUrl, b.LinkUrl, b.SortOrder, b.IsActive, b.Region, b.CreatedAt))
            .ToListAsync(ct);

        return Ok(list);
    }
}
