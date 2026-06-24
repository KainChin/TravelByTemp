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

public sealed class GeminiOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://generativelanguage.googleapis.com";
    public string VisionModel { get; set; } = "gemini-2.0-flash";
}

public sealed class GroqOptions
{
    public string ApiKey { get; set; } = "";
    public string BaseUrl { get; set; } = "https://api.groq.com/openai/v1";
    public string VisionModel { get; set; } = "meta-llama/llama-4-scout-17b-16e-instruct";
}

public sealed class TravelChatService(
    IHttpClientFactory httpClientFactory,
    OllamaOptions ollamaOptions,
    OpenAiOptions openAiOptions,
    GeminiOptions geminiOptions,
    GroqOptions groqOptions,
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
        if (string.IsNullOrWhiteSpace(groqOptions.ApiKey))
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Groq API key is not configured.");

        await using var stream = image.OpenReadStream();
        using var memory = new MemoryStream();
        await stream.CopyToAsync(memory, ct);
        var base64 = Convert.ToBase64String(memory.ToArray());
        var contentType = string.IsNullOrWhiteSpace(image.ContentType) || image.ContentType == "application/octet-stream"
            ? "image/jpeg"
            : image.ContentType;

        return await ChatImageWithGroqAsync(message, base64, contentType, ct);
    }

    private async Task<ChatEnvelopeResponse> ChatImageWithGroqAsync(string message, string base64, string contentType, CancellationToken ct)
    {
        var payload = new
        {
            model = groqOptions.VisionModel,
            messages = new object[]
            {
                new
                {
                    role = "system",
                    content = "Ban la tro ly du lich Viet Nam. Hay doc anh va tra loi bang tieng Viet. Neu anh co danh sach dia diem, quan cafe, nha hang hoac lich trinh, hay danh gia va goi y lich trinh hop ly ve thoi gian di chuyen, ngan sach, nghi ngoi va thu tu tham quan."
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
            temperature = 0.3,
            max_completion_tokens = 1024,
            stream = false
        };

        var client = httpClientFactory.CreateClient("groq");
        client.BaseAddress = new Uri(groqOptions.BaseUrl.TrimEnd('/') + "/");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", groqOptions.ApiKey);

        try
        {
            using var response = await client.PostAsJsonAsync("chat/completions", payload, JsonOptions, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Groq request failed: {StatusCode} {Body}", response.StatusCode, body);
                var messageText = response.StatusCode == System.Net.HttpStatusCode.TooManyRequests
                    ? "Groq rate limit or quota exceeded. Retry later or check Groq limits."
                    : "Groq request failed. Check API key, quota, model, or image input.";
                throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, messageText);
            }

            return new ChatEnvelopeResponse(ReadOpenAiContent(body), null);
        }
        catch (TravelAiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Groq vision request failed");
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Cannot connect to Groq.");
        }
    }

    private async Task<ChatEnvelopeResponse> ChatImageWithOpenAiAsync(string message, string base64, string contentType, CancellationToken ct)
    {
        var payload = new
        {
            model = openAiOptions.VisionModel,
            messages = new object[]
            {
                new
                {
                    role = "system",
                    content = "Ban la tro ly du lich Viet Nam. Hay doc anh va tra loi bang tieng Viet. Neu anh co danh sach dia diem, quan cafe, nha hang hoac lich trinh, hay danh gia va goi y lich trinh hop ly ve thoi gian di chuyen, ngan sach, nghi ngoi va thu tu tham quan."
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
                var messageText = response.StatusCode == System.Net.HttpStatusCode.TooManyRequests
                    ? "OpenAI quota exceeded. Check billing/quota or retry later."
                    : "OpenAI request failed. Check API key, quota, or image input.";
                throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, messageText);
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

    private async Task<string> ExtractTravelDataWithGeminiAsync(string base64, string contentType, CancellationToken ct)
    {
        const string prompt = """
            You are an expert travel data extraction system.

            Your task is to analyze the provided image (which may contain travel lists, cafes, restaurants, attractions, posters, or itineraries).

            Extract all meaningful travel-related information.

            IMPORTANT RULES:
            - Focus only on places, locations, cafes, restaurants, attractions.
            - Do NOT add explanations.
            - Do NOT hallucinate exact addresses or times if not visible.
            - If information is unclear, make best-effort inference but keep confidence low.
            - Keep original names as seen in image.

            OUTPUT FORMAT: STRICT JSON ONLY (no markdown, no text)

            Schema:
            {
              "city": string | null,
              "type": "coffee" | "food" | "attraction" | "mixed",
              "places": [
                {
                  "name": string,
                  "address": string | null,
                  "open_time": string | null,
                  "notes": string | null
                }
              ],
              "confidence": number
            }

            Now analyze the image and return JSON.
            """;

        var payload = new
        {
            contents = new object[]
            {
                new
                {
                    role = "user",
                    parts = new object[]
                    {
                        new { text = prompt },
                        new
                        {
                            inline_data = new
                            {
                                mime_type = contentType,
                                data = base64
                            }
                        }
                    }
                }
            },
            generationConfig = new
            {
                temperature = 0.1,
                response_mime_type = "application/json"
            }
        };

        var client = httpClientFactory.CreateClient("gemini");
        client.BaseAddress = new Uri(geminiOptions.BaseUrl);
        var path = $"/v1beta/models/{geminiOptions.VisionModel}:generateContent";

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, path)
            {
                Content = JsonContent.Create(payload, options: JsonOptions)
            };
            request.Headers.Add("x-goog-api-key", geminiOptions.ApiKey);

            using var response = await client.SendAsync(request, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Gemini request failed: {StatusCode} {Body}", response.StatusCode, body);
                var message = response.StatusCode == System.Net.HttpStatusCode.TooManyRequests
                    ? "Gemini quota exceeded. Check billing/quota or retry later."
                    : "Gemini request failed. Check API key, quota, or image input.";
                throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, message);
            }

            var json = ReadGeminiText(body);
            using var _ = JsonDocument.Parse(json);
            return json;
        }
        catch (TravelAiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Gemini vision request failed");
            throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "Cannot connect to Gemini.");
        }
    }

    private async Task<string> GenerateImageItineraryWithOllamaAsync(string extractedJson, CancellationToken ct)
    {
        var prompt = $$"""
            You are a professional travel planner.

            You will receive structured data of places in a city.

            Your task is to create an optimized travel itinerary.

            RULES:
            - Group places by geography (nearby locations first)
            - Respect opening hours
            - Morning: coffee / breakfast spots
            - Afternoon: sightseeing / exploration
            - Evening: chill / cafe / light activities
            - Avoid unnecessary backtracking
            - Optimize travel time logically
            - Return Vietnamese content where possible.

            INPUT:
            {{extractedJson}}

            OUTPUT FORMAT (STRICT JSON ONLY):

            {
              "city": "",
              "itinerary": [
                {
                  "day": 1,
                  "schedule": [
                    {
                      "time": "",
                      "place": "",
                      "activity": "",
                      "reason": ""
                    }
                  ]
                }
              ],
              "summary": "",
              "tips": []
            }
            """;

        var messages = new object[]
        {
            new
            {
                role = "system",
                content = "You create travel itineraries from structured place JSON. Return strict JSON only."
            },
            new { role = "user", content = prompt }
        };

        return await CallOllamaAsync(messages, jsonFormat: true, ct);
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
            Tao lich trinh du lich bang tieng Viet tu form nguoi dung.
            Chi tra ve JSON hop le, khong markdown. Toi da 2 hoat dong moi ngay.
            Schema:
            {
              "title": "string",
              "summary": "string",
              "days": [{"day": 1, "date": "yyyy-MM-dd", "activities": [{"time": "08:00", "destination": "string", "activity": "string", "transport": "string", "estimatedCost": 0, "note": "string"}]}],
              "costBreakdown": {"transport": 0, "food": 0, "accommodation": 0, "activities": 0, "total": 0, "perPerson": 0},
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
            ["stream"] = false,
            ["options"] = new
            {
                temperature = jsonFormat ? 0.1 : 0.3,
                num_ctx = 1024,
                num_predict = jsonFormat ? 450 : 140
            }
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

    private static string ReadGeminiText(string body)
    {
        using var doc = JsonDocument.Parse(body);
        var candidates = doc.RootElement.GetProperty("candidates");
        if (candidates.GetArrayLength() == 0)
            return "";

        var parts = candidates[0]
            .GetProperty("content")
            .GetProperty("parts");
        if (parts.GetArrayLength() == 0)
            return "";

        return parts[0].GetProperty("text").GetString() ?? "";
    }
}
