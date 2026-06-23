using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using VietAITravel.Api.DTOs;

namespace VietAITravel.Api.Services;

public sealed class TravelAiException(int statusCode, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

public sealed class OpenAiOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://api.openai.com/v1";
    public string VisionModel { get; set; } = "gpt-4o-mini";
}

public sealed class TravelChatService(
    IHttpClientFactory httpClientFactory,
    OllamaOptions ollamaOptions,
    OpenAiOptions openAiOptions,
    ILogger<TravelChatService> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<ChatEnvelopeResponse> ChatAsync(ChatRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Message is required.");

        var messages = new object[]
        {
            new
            {
                role = "system",
                content = "Ban la tro ly du lich Viet Nam. Chi tra loi cac cau hoi ve du lich, lich trinh, diem den, kinh nghiem, thoi tiet va ngan sach. Neu cau hoi ngoai chu de, hay lich su tu choi ngan gon."
            },
            new { role = "user", content = request.Message }
        };

        var response = await CallOllamaAsync(messages, jsonFormat: false, ct);
        return new ChatEnvelopeResponse(response, null);
    }

    public async Task<ChatEnvelopeResponse> ChatWithImageAsync(string message, IFormFile image, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(message))
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Message is required.");
        if (image.Length <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Image file is empty.");
        if (string.IsNullOrWhiteSpace(openAiOptions.ApiKey))
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "OpenAI API key is not configured.");

        await using var stream = image.OpenReadStream();
        using var memory = new MemoryStream();
        await stream.CopyToAsync(memory, ct);
        var base64 = Convert.ToBase64String(memory.ToArray());
        var contentType = string.IsNullOrWhiteSpace(image.ContentType) ? "image/jpeg" : image.ContentType;

        var payload = new
        {
            model = openAiOptions.VisionModel,
            messages = new object[]
            {
                new
                {
                    role = "system",
                    content = "Ban la tro ly du lich. Hay doc anh lich trinh neu co va danh gia tinh hop ly ve thoi gian di chuyen, ngan sach, lich nghi, diem den va rui ro. Tra loi bang tieng Viet ngan gon, ro y."
                },
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = message },
                        new
                        {
                            type = "image_url",
                            image_url = new { url = $"data:{contentType};base64,{base64}" }
                        }
                    }
                }
            },
            temperature = 0.3
        };

        var client = httpClientFactory.CreateClient("openai");
        client.BaseAddress = new Uri(openAiOptions.BaseUrl);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", openAiOptions.ApiKey);

        try
        {
            using var response = await client.PostAsJsonAsync("/v1/chat/completions", payload, JsonOptions, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("OpenAI request failed: {StatusCode} {Body}", response.StatusCode, body);
                throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "OpenAI request failed. Check API key, quota, or image input.");
            }

            return new ChatEnvelopeResponse(ReadOpenAiContent(body), null);
        }
        catch (TravelAiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "OpenAI vision request failed");
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Cannot connect to OpenAI.");
        }
    }

    public async Task<ChatEnvelopeResponse> GenerateItineraryAsync(GenerateItineraryRequest request, CancellationToken ct)
    {
        if (request.Destinations.Count == 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "At least one destination is required.");
        if (request.PeopleCount <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "People count must be greater than zero.");
        if (request.BudgetPerPerson <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Budget per person must be greater than zero.");

        var prompt = """
            Tao lich trinh du lich bang tieng Viet dua tren du lieu nguoi dung.
            Chi tra ve JSON hop le, khong them markdown.
            Schema bat buoc:
            {
              "title": "string",
              "summary": "string",
              "days": [
                {
                  "day": 1,
                  "date": "yyyy-MM-dd",
                  "activities": [
                    {
                      "time": "08:00",
                      "destination": "string",
                      "activity": "string",
                      "transport": "string",
                      "estimatedCost": 0,
                      "note": "string"
                    }
                  ]
                }
              ],
              "costBreakdown": {
                "transport": 0,
                "food": 0,
                "accommodation": 0,
                "activities": 0,
                "total": 0,
                "perPerson": 0
              },
              "warnings": ["string"]
            }
            """;

        var userData = JsonSerializer.Serialize(request, JsonOptions);
        var messages = new object[]
        {
            new
            {
                role = "system",
                content = "Ban la AI lap lich trinh du lich. Luon tra ve JSON hop le theo schema, uu tien lich trinh de demo trong Flutter."
            },
            new { role = "user", content = $"{prompt}\nDu lieu form:\n{userData}" }
        };

        var json = await CallOllamaAsync(messages, jsonFormat: true, ct);
        var itinerary = JsonSerializer.Deserialize<object>(json, JsonOptions);
        return new ChatEnvelopeResponse("Da tao lich trinh.", itinerary);
    }

    private async Task<string> CallOllamaAsync(object[] messages, bool jsonFormat, CancellationToken ct)
    {
        var client = httpClientFactory.CreateClient("ollama-chat");
        client.BaseAddress = new Uri(ollamaOptions.BaseUrl);

        var payload = new Dictionary<string, object?>
        {
            ["model"] = ollamaOptions.ChatModel,
            ["messages"] = messages,
            ["stream"] = false
        };
        if (jsonFormat)
            payload["format"] = "json";

        try
        {
            using var response = await client.PostAsJsonAsync("/api/chat", payload, JsonOptions, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Ollama request failed: {StatusCode} {Body}", response.StatusCode, body);
                throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Ollama is not available. Check if Ollama is running.");
            }

            return ReadOllamaContent(body);
        }
        catch (TravelAiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Ollama request failed");
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Cannot connect to Ollama.");
        }
    }

    private static string ReadOllamaContent(string body)
    {
        using var doc = JsonDocument.Parse(body);
        if (doc.RootElement.TryGetProperty("message", out var message) &&
            message.TryGetProperty("content", out var content))
            return content.GetString() ?? "";
        return "";
    }

    private static string ReadOpenAiContent(string body)
    {
        using var doc = JsonDocument.Parse(body);
        var choices = doc.RootElement.GetProperty("choices");
        if (choices.GetArrayLength() == 0)
            return "";

        return choices[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? "";
    }
}
