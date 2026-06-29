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
            Chi tra ve JSON hop le, khong markdown. Moi ngay phai co 6-8 hoat dong trai dai tu sang den toi.
            Chi phi tung hoat dong phai la so le thuc te theo Viet Nam, khong dung toan so tron nhu 100000/200000.
            Schema:
            {
              "title": "string",
              "summary": "string",
              "days": [{"day": 1, "date": "yyyy-MM-dd", "activities": [{"time": "08:00", "destination": "string", "activity": "string", "estimatedCost": 0, "latitude": 0, "longitude": 0, "note": "string"}]}],
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

        object? itinerary;
        try
        {
            using var aiTimeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
            aiTimeout.CancelAfter(TimeSpan.FromSeconds(18));
            var json = await CallOllamaAsync(messages, jsonFormat: true, aiTimeout.Token);
            itinerary = JsonSerializer.Deserialize<object>(json, JsonOptions);
            if (itinerary is null)
                itinerary = BuildFallbackItinerary(request);
        }
        catch (Exception ex) when (ex is TravelAiException or JsonException or OperationCanceledException)
        {
            logger.LogWarning(ex, "Falling back to deterministic itinerary because local AI is unavailable, slow, or returned invalid JSON.");
            itinerary = BuildFallbackItinerary(request);
        }

        return new ChatEnvelopeResponse("Da tao lich trinh.", itinerary);
    }

    private static object BuildFallbackItinerary(GenerateItineraryRequest request)
    {
        var destinations = request.Destinations.Count == 0
            ? [new TripDestinationInput("fallback", "Diem den", null, null, request.DepartureDate, request.ReturnDate, null, null)]
            : request.Destinations;

        var totalDays = Math.Max(1, (request.ReturnDate.Date - request.DepartureDate.Date).Days + 1);
        var perDayBudget = request.BudgetPerPerson / totalDays;
        var days = Enumerable.Range(1, totalDays).Select(day =>
        {
            var destination = destinations[(day - 1) % destinations.Count];
            var date = request.DepartureDate.Date.AddDays(day - 1);
            var latitude = destination.Latitude ?? 16.0544;
            var longitude = destination.Longitude ?? 108.2022;
            var daySeed = day * 13791 + destination.Name.Sum(c => c);
            decimal Cost(decimal ratio, int offset) =>
                Math.Round((perDayBudget * ratio) + ((daySeed + offset) % 37000) + 9000, 0);

            return new
            {
                day,
                date = date.ToString("yyyy-MM-dd"),
                activities = new object[]
                {
                    new
                    {
                        time = "07:30",
                        destination = destination.Name,
                        activity = "An sang dia phuong va cafe",
                        estimatedCost = Cost(0.08m, 1100),
                        latitude,
                        longitude,
                        note = "Bat dau nhe de giu suc cho ca ngay."
                    },
                    new
                    {
                        time = "09:00",
                        destination = destination.Name,
                        activity = $"Tham quan diem noi bat o {destination.Name}",
                        estimatedCost = Cost(0.16m, 5200),
                        latitude = latitude + 0.006,
                        longitude = longitude + 0.007,
                        note = "Uu tien khung gio sang de tranh dong."
                    },
                    new
                    {
                        time = "11:30",
                        destination = destination.Name,
                        activity = "An trua gan tuyen tham quan",
                        estimatedCost = Cost(0.13m, 9300),
                        latitude = latitude + 0.011,
                        longitude = longitude + 0.004,
                        note = "Chon quan co danh gia tot, khong quay nguoc tuyen."
                    },
                    new
                    {
                        time = "14:00",
                        destination = destination.Name,
                        activity = "Kham pha diem phu hoac bao tang/khu trai nghiem",
                        estimatedCost = Cost(0.15m, 15100),
                        latitude = latitude + 0.016,
                        longitude = longitude + 0.012,
                        note = "Them hoat dong trong nha neu thoi tiet xau."
                    },
                    new
                    {
                        time = "16:30",
                        destination = destination.Name,
                        activity = "Cafe, check-in va nghi nhe",
                        estimatedCost = Cost(0.09m, 21100),
                        latitude = latitude + 0.021,
                        longitude = longitude + 0.018,
                        note = "Khoang nghi de tranh lich qua day."
                    },
                    new
                    {
                        time = "19:00",
                        destination = destination.Name,
                        activity = "An toi va di dao khu trung tam",
                        estimatedCost = Cost(0.17m, 28700),
                        latitude = latitude + 0.025,
                        longitude = longitude + 0.023,
                        note = "Ket thuc ngay bang khu am thuc/cho dem neu co."
                    }
                }
            };
        }).ToList();

        return new
        {
            title = destinations.Count == 1
                ? $"Hanh trinh {destinations[0].Name}"
                : $"Hanh trinh {string.Join(" - ", destinations.Take(3).Select(x => x.Name))}",
            summary = "Lich trinh duoc tao nhanh bang rule-based fallback de tranh cho AI local qua lau.",
            days,
            costBreakdown = new
            {
                transport = Math.Round(request.BudgetPerPerson * 0.25m, 0),
                food = Math.Round(request.BudgetPerPerson * 0.25m, 0),
                accommodation = Math.Round(request.BudgetPerPerson * 0.35m, 0),
                activities = Math.Round(request.BudgetPerPerson * 0.15m, 0),
                total = Math.Round(request.BudgetPerPerson * request.PeopleCount, 0),
                perPerson = Math.Round(request.BudgetPerPerson, 0)
            },
            warnings = new[]
            {
                "Day la lich trinh du phong. Bat LM Studio/Ollama hoac dung model nho hon de nhan lich trinh AI chi tiet hon."
            }
        };
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
