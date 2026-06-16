using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VietAITravel.Api.Constants;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize(Roles = RoleNames.Traveler + "," + RoleNames.Admin)]
public class AiController(AiRecommendationService ai) : ControllerBase
{
    [HttpPost("recommend")]
    public async Task<ActionResult<AiRecommendResponse>> Recommend(AiRecommendRequest request, CancellationToken ct)
    {
        ValidateRequest(request);

        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        return Ok(await ai.RecommendAsync(userId, request, ct));
    }

    private static void ValidateRequest(AiRecommendRequest request)
    {
        if (request.Latitude is < -90 or > 90)
            throw new ArgumentException("Latitude must be between -90 and 90.");

        if (request.Longitude is < -180 or > 180)
            throw new ArgumentException("Longitude must be between -180 and 180.");

        if (request.BudgetInput <= 0)
            throw new ArgumentException("Budget input must be greater than 0.");

        if (request.TotalDays is < 1 or > 14)
            throw new ArgumentException("Total days must be between 1 and 14.");

        if (string.IsNullOrWhiteSpace(request.PreferenceInput))
            throw new ArgumentException("Preference input is required.");

        if (request.TopK is < 1 or > 20)
            throw new ArgumentException("TopK must be between 1 and 20.");
    }
}
