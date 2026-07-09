using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VietAITravel.Api.Data;
using VietAITravel.Api.DTOs;
using VietAITravel.Api.Entities;
namespace VietAITravel.Api.Services;
public sealed partial class RouteAnalysisService {
    private async Task<RouteDistance?> TryGetGoogleDistanceAsync(
        RoutePlaceDto from,
        RoutePlaceDto to,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(googleMapsOptions.ApiKey))
            return null;

        try
        {
            var path = $"{googleMapsOptions.BaseUrl.TrimEnd('/')}/maps/api/distancematrix/json" +
                       $"?origins={from.Latitude.ToString(System.Globalization.CultureInfo.InvariantCulture)},{from.Longitude.ToString(System.Globalization.CultureInfo.InvariantCulture)}" +
                       $"&destinations={to.Latitude.ToString(System.Globalization.CultureInfo.InvariantCulture)},{to.Longitude.ToString(System.Globalization.CultureInfo.InvariantCulture)}" +
                       "&mode=driving&units=metric" +
                       $"&key={Uri.EscapeDataString(googleMapsOptions.ApiKey)}";

            using var response = await GoogleClient.GetAsync(path, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Google Distance Matrix failed: {StatusCode} {Body}", response.StatusCode, body);
                return null;
            }

            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;
            if (root.GetProperty("status").GetString() != "OK")
            {
                logger.LogWarning("Google Distance Matrix status was not OK: {Body}", body);
                return null;
            }

            var element = root
                .GetProperty("rows")[0]
                .GetProperty("elements")[0];
            if (element.GetProperty("status").GetString() != "OK")
                return null;

            var meters = element.GetProperty("distance").GetProperty("value").GetDouble();
            return new RouteDistance(meters / 1000, true);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Google Distance Matrix request failed, using fallback distance");
            return null;
        }
    }
    private async Task<Dictionary<string, double>?> EstimateCostsWithGroqAsync(double distanceKm, string fromName, string toName, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(groqOptions.ApiKey)) return null;

        var prompt = $"Estimate realistic transport costs in VND for traveling {distanceKm:F1}km from {fromName} to {toName} in Vietnam. Return ONLY a valid JSON object with keys: car, coach, train, flight, motorbike, ferry. The values must be integer VND representing the cost per person. If a mode is impossible, set its value to 0. Do not output any markdown or explanation.";

        var payload = new
        {
            model = groqOptions.ChatModel ?? "llama3-8b-8192",
            messages = new object[] { new { role = "user", content = prompt } },
            temperature = 0.1
        };

        var client = httpClientFactory.CreateClient("groq");
        client.BaseAddress = new Uri(groqOptions.BaseUrl.TrimEnd('/') + "/");
        var key = groqOptions.ApiKey.Split(',').FirstOrDefault()?.Trim();
        if (string.IsNullOrEmpty(key)) return null;
        
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", key);

        try
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
            timeout.CancelAfter(TimeSpan.FromSeconds(8));
            using var response = await client.PostAsJsonAsync("chat/completions", payload, new JsonSerializerOptions(JsonSerializerDefaults.Web), timeout.Token);
            if (response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(timeout.Token);
                using var doc = JsonDocument.Parse(body);
                var content = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
                if (!string.IsNullOrWhiteSpace(content))
                {
                    content = content.Trim();
                    if (content.StartsWith("```json")) content = content.Substring(7);
                    if (content.StartsWith("```")) content = content.Substring(3);
                    if (content.EndsWith("```")) content = content.Substring(0, content.Length - 3);
                    
                    var dict = JsonSerializer.Deserialize<Dictionary<string, double>>(content.Trim(), new JsonSerializerOptions(JsonSerializerDefaults.Web));
                    return dict;
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to estimate cost with Groq for {From} to {To}", fromName, toName);
        }
        return null;
    }
}
