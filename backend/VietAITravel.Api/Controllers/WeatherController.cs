using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VietAITravel.Api.Services;

namespace VietAITravel.Api.Controllers;

[ApiController]
[Route("api/weather")]
[AllowAnonymous]
public class WeatherController(WeatherService weather) : ControllerBase
{
    [HttpGet("current")]
    public async Task<ActionResult> Current(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        CancellationToken ct)
    {
        var result = await weather.GetCurrentWeatherAsync(latitude, longitude, ct);
        return Ok(new
        {
            temperatureC = result.TemperatureC,
            description = result.Description,
            humidity = result.Humidity,
            windSpeedKmh = result.WindSpeedKmh
        });
    }
}
