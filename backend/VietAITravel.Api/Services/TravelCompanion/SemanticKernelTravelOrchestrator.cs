using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace VietAITravel.Api.Services.TravelCompanion;

public sealed record TravelToolContext(
    object Destinations,
    object Weather,
    object Route,
    object Memory);

public sealed class SemanticKernelTravelOrchestrator(
    IHttpClientFactory httpClientFactory,
    LmStudioOptions options,
    ILogger<SemanticKernelTravelOrchestrator> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<string> ExplainAsync(
        string userGoal,
        TravelToolContext toolContext,
        CancellationToken ct)
    {
        var systemPrompt = """
            Ban la AI Travel Companion. Hay giai thich ngan gon bang tieng Viet.
            Ban phai dua tren du lieu tool context: destinations, weather, route, memory.
            Khong noi chung chung. Tap trung vao ly do chon lich trinh, ngan sach, thoi tiet va tuyen duong.
            """;

        var payload = new
        {
            model = options.ChatModel,
            messages = new object[]
            {
                new { role = "system", content = systemPrompt },
                new
                {
                    role = "user",
                    content = JsonSerializer.Serialize(new
                    {
                        goal = userGoal,
                        tools = toolContext
                    }, JsonOptions)
                }
            },
            temperature = 0.25,
            stream = false
        };

        var client = httpClientFactory.CreateClient("lm-studio");
        client.BaseAddress = new Uri(options.BaseUrl.TrimEnd('/') + "/");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", options.ApiKey);

        try
        {
            using var response = await client.PostAsJsonAsync("chat/completions", payload, JsonOptions, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("LM Studio failed: {StatusCode} {Body}", response.StatusCode, body);
                return "AI đã kết hợp sở thích, thời tiết, ngân sách và tuyến đường để tạo lịch trình phù hợp nhất.";
            }

            using var doc = JsonDocument.Parse(body);
            var choices = doc.RootElement.GetProperty("choices");
            if (choices.GetArrayLength() == 0) return "";
            return choices[0].GetProperty("message").GetProperty("content").GetString() ?? "";
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "LM Studio unavailable, using deterministic explanation");
            return "AI đang chạy ở chế độ dự phòng: hệ thống vẫn dùng dữ liệu điểm đến, thời tiết, ngân sách và tuyến đường để lập kế hoạch.";
        }
    }
}
