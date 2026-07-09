using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using VietAITravel.Api.DTOs;
namespace VietAITravel.Api.Services;
public sealed partial class TravelChatService
{
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
    // Groq is used as a fallback when Ollama is unavailable or too slow.
    // Ollama remains the primary AI as per project guidelines.
    private async Task<string> CallGroqAsync(object[] messages, CancellationToken ct)
    {
        var keys = groqOptions.ApiKey.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (keys.Length == 0) throw new TravelAiException(StatusCodes.Status500InternalServerError, "No Groq API key configured.");

        var client = httpClientFactory.CreateClient();
        client.BaseAddress = new Uri(groqOptions.BaseUrl);

        var payload = new
        {
            model = groqOptions.ChatModel,
            messages,
            temperature = 0.1,
            max_tokens = 2500,
            response_format = new { type = "json_object" }
        };

        foreach (var key in keys)
        {
            client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", key);
            try
            {
                using var response = await client.PostAsJsonAsync(
                    $"{groqOptions.BaseUrl.TrimEnd('/')}/chat/completions", payload, JsonOptions, ct);
                var body = await response.Content.ReadAsStringAsync(ct);
                
                if (response.IsSuccessStatusCode)
                {
                    using var doc = JsonDocument.Parse(body);
                    return doc.RootElement
                        .GetProperty("choices")[0]
                        .GetProperty("message")
                        .GetProperty("content")
                        .GetString() ?? "{}";
                }
                
                var maskedKey = key.Length > 4 ? key.Substring(key.Length - 4) : "****";
                logger.LogWarning("Groq chat request failed with key ending in {KeyEnd}: {StatusCode} {Body}", 
                    maskedKey, response.StatusCode, body);
                
                // If the key is rate limited or invalid, we continue to the next key.
                continue;
            }
            catch (Exception ex)
            {
                var maskedKey = key.Length > 4 ? key.Substring(key.Length - 4) : "****";
                logger.LogWarning(ex, "Groq chat request exception with key ending in {KeyEnd}", maskedKey);
                // Continue to try the next key
            }
        }
        
        throw new TravelAiException(StatusCodes.Status503ServiceUnavailable, "All Groq API keys failed or were rate limited.");
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
                num_ctx = 4096,
                num_predict = jsonFormat ? 2048 : 512
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
