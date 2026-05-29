using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace VietAITravel.Api.Services;

public record WeatherResult(double TemperatureC, string Description, double? Humidity, double? WindSpeedKmh);

public class WeatherService(HttpClient http, ILogger<WeatherService> logger)
{
    public async Task<WeatherResult> GetCurrentWeatherAsync(double latitude, double longitude, CancellationToken ct = default)
    {
        var url =
            $"https://api.open-meteo.com/v1/forecast?latitude={latitude:F4}&longitude={longitude:F4}" +
            "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m";

        try
        {
            var response = await http.GetFromJsonAsync<OpenMeteoResponse>(url, ct);
            var current = response?.Current;
            if (current == null)
                return FallbackWeather(latitude);

            return new WeatherResult(
                current.Temperature2m,
                MapWeatherCode(current.WeatherCode),
                current.RelativeHumidity2m,
                current.WindSpeed10m);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Weather API failed, using fallback");
            return FallbackWeather(latitude);
        }
    }

    private static WeatherResult FallbackWeather(double latitude) =>
        latitude > 16
            ? new WeatherResult(30, "Trời nắng nhẹ", 70, 3.5)
            : new WeatherResult(22, "Thời tiết mát mẻ", 65, 2.0);

    private static string MapWeatherCode(int code) => code switch
    {
        0 => "Trời quang",
        1 or 2 or 3 => "Ít mây",
        45 or 48 => "Sương mù",
        >= 51 and <= 67 => "Mưa",
        >= 71 and <= 77 => "Tuyết",
        >= 80 and <= 82 => "Mưa rào",
        >= 95 => "Giông bão",
        _ => "Thời tiết ổn định"
    };

    private sealed class OpenMeteoResponse
    {
        [JsonPropertyName("current")]
        public CurrentWeather? Current { get; set; }
    }

    private sealed class CurrentWeather
    {
        [JsonPropertyName("temperature_2m")]
        public double Temperature2m { get; set; }

        [JsonPropertyName("relative_humidity_2m")]
        public double RelativeHumidity2m { get; set; }

        [JsonPropertyName("weather_code")]
        public int WeatherCode { get; set; }

        [JsonPropertyName("wind_speed_10m")]
        public double WindSpeed10m { get; set; }
    }
}
