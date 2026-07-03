using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VietAITravel.Api.Constants;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/content/media")]
[Authorize(Roles = RoleNames.TravelManager + "," + RoleNames.Admin)]
public class ContentMediaController(IWebHostEnvironment env, ILogger<ContentMediaController> logger) : ControllerBase
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
        { ".jpg", ".jpeg", ".png", ".webp", ".gif" };

    private const long MaxBytes = 5 * 1024 * 1024;

    [HttpPost("upload")]
    [RequestSizeLimit(MaxBytes)]
    public async Task<ActionResult<MediaUploadResponse>> Upload(IFormFile file, CancellationToken ct)
    {
        if (file.Length == 0)
            return BadRequest("File rỗng.");

        if (file.Length > MaxBytes)
            return BadRequest("File tối đa 5MB.");

        var ext = Path.GetExtension(file.FileName);
        if (string.IsNullOrWhiteSpace(ext) || !AllowedExtensions.Contains(ext))
            return BadRequest("Chỉ hỗ trợ ảnh JPG, PNG, WEBP, GIF.");

        var uploadsDir = Path.Combine(env.ContentRootPath, "wwwroot", "uploads");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid():N}{ext.ToLowerInvariant()}";
        var path = Path.Combine(uploadsDir, fileName);

        await using (var stream = System.IO.File.Create(path))
            await file.CopyToAsync(stream, ct);

        var url = $"/uploads/{fileName}";
        logger.LogInformation("Uploaded media {File} ({Size} bytes)", fileName, file.Length);
        return Ok(new MediaUploadResponse(url, fileName, file.Length));
    }
}
