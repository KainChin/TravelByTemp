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
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        return Ok(await ai.RecommendAsync(userId, request, ct));
    }
}
