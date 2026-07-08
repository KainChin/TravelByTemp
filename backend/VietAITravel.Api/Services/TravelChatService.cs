using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Globalization;
using System.Text;
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
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Trip budget must be greater than zero.");

        var feasibility = AnalyzeTripFeasibility(request);
        var prompt = """
            Tao lich trinh du lich bang tieng Viet tu form nguoi dung.
            Chi tra ve JSON hop le, khong markdown. Moi ngay phai co 6-8 hoat dong trai dai tu sang den toi.
            Chi phi tung hoat dong phai la so le thuc te theo Viet Nam, khong dung toan so tron nhu 100000/200000.
            Bat buoc phan tich tinh kha thi dua tren:
            - so nguoi
            - tong ngan sach nhom va ngan sach quy doi moi nguoi
            - ngay di/ngay ve
            - diem xuat phat, diem den
            - cac chang di chuyen da duoc validate
            - so thich, kieu nhom va yeu cau dac biet
            RouteLegs la ket qua validate bang code. Khong duoc tu quyet dinh availability cua may bay.
            Neu routeLegs co mode=flight thi coi do la multi-modal da xac minh: origin -> originAirport -> flight -> destinationAirport -> destination.
            Ollama chi duoc giai thich/goi y cach dat ve va sap xep lich, khong duoc disable hoac thay the flight availability da validate.

            Bat buoc sinh dia diem/hoat dong phu hop voi du lieu nguoi dung da chon:
            - travelGroup quyet dinh nhip do va loai dia diem: mot minh, nguoi yeu, gia dinh, ban be.
            - interests quyet dinh noi dung chinh: bien, am thuc, chup anh, van hoa, thien nhien, nightlife, nghi duong, tiet kiem.
            - specialRequest la rang buoc bat buoc: tranh di bo nhieu, co tre em, an chay, tranh mua, nguoi lon tuoi...
            - Moi ngay phai co ten dia diem cu the de nguoi dung co the tim tren Google Maps.
            - Khong duoc viet chung chung nhu "tham quan diem noi bat", "quan dac san dia phuong", "cafe view dep".
            - Neu khong chac ten quan an/cafe cu the, uu tien ten diem/khong gian co that trong khu vuc: cho, pho di bo, bao tang, cong vien, khu du lich, bai bien, lang nghe, khu sinh thai.
            - Moi activity nen co placeName, address neu biet, rating tu 4.0 tro len neu la goi y tham khao.
            - Khong de lich trinh mau giong nhau giua cac ngay.

            Neu ngan sach khong du, khong duoc gia vo nhu chuyen di van tron ven.
            Phai them warnings ro rang va summary noi that: can cat giam hoat dong, doi phuong tien, giam ngay hoac tang ngan sach.
            Tong chi phi trong costBreakdown.total phai dua tren uoc tinh thuc te, khong duoc bang ngan sach nguoi dung neu chi phi thuc te cao hon.
            Schema:
            {
              "title": "string",
              "summary": "string",
              "userBudget": 0,
              "peopleCount": 0,
              "days": [{"day": 1, "date": "yyyy-MM-dd", "activities": [{"time": "08:00", "destination": "ten dia diem cu the", "placeName": "ten dia diem cu the", "address": "string|null", "rating": 4.5, "activity": "string", "estimatedCost": 0, "latitude": 0, "longitude": 0, "note": "string"}]}],
              "costBreakdown": {"transport": 0, "food": 0, "accommodation": 0, "activities": 0, "total": 0, "perPerson": 0},
              "feasibility": {"status": "feasible|tight|not_feasible", "budgetTotal": 0, "estimatedMinimumTotal": 0, "gap": 0, "message": "string", "recommendations": ["string"]},
              "warnings": ["string"]
            }
            """;

        var userData = JsonSerializer.Serialize(new { request, feasibility }, JsonOptions);
        var messages = new object[]
        {
            new
            {
                role = "system",
                content = "Ban la AI lap lich trinh du lich thuc te tai Viet Nam. Luon tra ve JSON hop le theo schema. Uu tien tinh dung thuc te hon viec tao noi dung dep."
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
        var feasibility = AnalyzeTripFeasibility(request);
        var destinations = request.Destinations.Count == 0
            ? [new TripDestinationInput("fallback", "Diem den", null, null, request.DepartureDate, request.ReturnDate, null, null)]
            : request.Destinations;
        var profile = BuildPreferenceProfile(request);

        var totalDays = Math.Max(1, (request.ReturnDate.Date - request.DepartureDate.Date).Days + 1);
        var userBudgetPerPerson = request.BudgetPerPerson / request.PeopleCount;
        var perPersonEstimate = Math.Max(feasibility.EstimatedMinimumPerPerson, userBudgetPerPerson * 0.72m);
        var perDayBudget = perPersonEstimate / totalDays;
        var days = Enumerable.Range(1, totalDays).Select(day =>
        {
            var destination = destinations[(day - 1) % destinations.Count];
            var date = request.DepartureDate.Date.AddDays(day - 1);
            var latitude = destination.Latitude ?? 16.0544;
            var longitude = destination.Longitude ?? 108.2022;
            var daySeed = day * 13791 + destination.Name.Sum(c => c);
            decimal Cost(decimal ratio, int offset) =>
                Math.Round((perDayBudget * ratio) + ((daySeed + offset) % 37000) + 9000, 0);
            var plan = BuildDayActivityPlan(destination.Name, profile, day);

            return new
            {
                day,
                date = date.ToString("yyyy-MM-dd"),
                activities = new object[]
                {
                    new
                    {
                        time = "07:30",
                        destination = plan.Morning,
                        placeName = plan.Morning,
                        address = destination.Name,
                        rating = 4.4,
                        activity = $"An sang/cafe tai {plan.Morning}",
                        estimatedCost = Cost(0.08m, 1100),
                        latitude,
                        longitude,
                        note = profile.MorningNote
                    },
                    new
                    {
                        time = "09:00",
                        destination = plan.FirstStop,
                        placeName = plan.FirstStop,
                        address = destination.Name,
                        rating = 4.7,
                        activity = $"Tham quan {plan.FirstStop}",
                        estimatedCost = Cost(0.16m, 5200),
                        latitude = latitude + 0.006,
                        longitude = longitude + 0.007,
                        note = profile.PaceNote
                    },
                    new
                    {
                        time = "11:30",
                        destination = plan.Lunch,
                        placeName = plan.Lunch,
                        address = destination.Name,
                        rating = 4.5,
                        activity = $"An trua tai {plan.Lunch}",
                        estimatedCost = Cost(0.13m, 9300),
                        latitude = latitude + 0.011,
                        longitude = longitude + 0.004,
                        note = profile.FoodNote
                    },
                    new
                    {
                        time = "14:00",
                        destination = plan.Afternoon,
                        placeName = plan.Afternoon,
                        address = destination.Name,
                        rating = 4.6,
                        activity = $"Trai nghiem {plan.Afternoon}",
                        estimatedCost = Cost(0.15m, 15100),
                        latitude = latitude + 0.016,
                        longitude = longitude + 0.012,
                        note = profile.SpecialNote
                    },
                    new
                    {
                        time = "16:30",
                        destination = plan.RestStop,
                        placeName = plan.RestStop,
                        address = destination.Name,
                        rating = 4.4,
                        activity = $"Nghi nhe/check-in tai {plan.RestStop}",
                        estimatedCost = Cost(0.09m, 21100),
                        latitude = latitude + 0.021,
                        longitude = longitude + 0.018,
                        note = profile.RestNote
                    },
                    new
                    {
                        time = "19:00",
                        destination = plan.Evening,
                        placeName = plan.Evening,
                        address = destination.Name,
                        rating = 4.5,
                        activity = $"An toi/di dao tai {plan.Evening}",
                        estimatedCost = Cost(0.17m, 28700),
                        latitude = latitude + 0.025,
                        longitude = longitude + 0.023,
                        note = profile.EveningNote
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
            preferenceSummary = profile.Summary,
            userBudget = Math.Round(feasibility.BudgetTotal, 0),
            totalBudget = Math.Round(feasibility.BudgetTotal, 0),
            peopleCount = request.PeopleCount,
            days,
            costBreakdown = new
            {
                transport = Math.Round(feasibility.TransportPerPerson * request.PeopleCount, 0),
                food = Math.Round(feasibility.FoodPerPerson * request.PeopleCount, 0),
                accommodation = Math.Round(feasibility.AccommodationPerPerson * request.PeopleCount, 0),
                activities = Math.Round(feasibility.ActivitiesPerPerson * request.PeopleCount, 0),
                total = Math.Round(feasibility.EstimatedMinimumTotal, 0),
                perPerson = Math.Round(feasibility.EstimatedMinimumPerPerson, 0)
            },
            feasibility = new
            {
                status = feasibility.Status,
                budgetTotal = Math.Round(feasibility.BudgetTotal, 0),
                estimatedMinimumTotal = Math.Round(feasibility.EstimatedMinimumTotal, 0),
                gap = Math.Round(feasibility.Gap, 0),
                message = feasibility.Message,
                recommendations = feasibility.Recommendations
            },
            warnings = feasibility.Warnings
        };
    }

    private sealed record TripFeasibility(
        string Status,
        decimal BudgetTotal,
        decimal EstimatedMinimumTotal,
        decimal EstimatedMinimumPerPerson,
        decimal TransportPerPerson,
        decimal FoodPerPerson,
        decimal AccommodationPerPerson,
        decimal ActivitiesPerPerson,
        decimal Gap,
        string Message,
        IReadOnlyList<string> Recommendations,
        IReadOnlyList<string> Warnings);

    private sealed record PreferenceProfile(
        string Summary,
        string MorningNote,
        string PaceNote,
        string FoodNote,
        string SpecialNote,
        string RestNote,
        string EveningNote);

    private sealed record DayActivityPlan(
        string Morning,
        string FirstStop,
        string Lunch,
        string Afternoon,
        string RestStop,
        string Evening);

    private static PreferenceProfile BuildPreferenceProfile(GenerateItineraryRequest request)
    {
        var interests = request.Interests ?? Array.Empty<string>();
        var group = request.TravelGroup ?? "";
        var special = request.SpecialRequest ?? "";

        var groupNote = "Nhip di can bang, phu hop voi nhom.";
        if (ContainsInsensitive(group, "mot minh")) groupNote = "Nhip di gon, linh hoat cho nguoi di mot minh.";
        if (ContainsInsensitive(group, "nguoi yeu")) groupNote = "Nhip di nhe, uu tien khong gian rieng va diem ngam canh.";
        if (ContainsInsensitive(group, "gia dinh")) groupNote = "Nhip di vua phai, uu tien dia diem an toan va de nghi.";
        if (ContainsInsensitive(group, "ban be")) groupNote = "Nhip di nang dong, uu tien diem trai nghiem va an uong theo nhom.";

        var foodNote = interests.Any(x => ContainsInsensitive(x, "am thuc"))
            ? "Uu tien quan dac san dia phuong, tranh nha hang qua du lich neu ngan sach han che."
            : "Chon diem an gan tuyen de tiet kiem thoi gian di chuyen.";
        if (ContainsInsensitive(special, "an chay")) {
            foodNote = "Bat buoc uu tien quan chay hoac quan co mon chay ro rang.";
        }

        var specialNote = string.IsNullOrWhiteSpace(special)
            ? "Co phuong an trong nha neu thoi tiet xau."
            : $"Dieu chinh theo yeu cau: {special}.";
        if (ContainsInsensitive(special, "tre em")) {
            specialNote = "Uu tien diem phu hop tre em, co cho nghi va nha ve sinh de tiep can.";
        }
        if (ContainsInsensitive(special, "tranh di bo") || ContainsInsensitive(special, "nguoi lon tuoi")) {
            specialNote = "Han che di bo dai, uu tien taxi/xe rieng va diem dung chan gan nhau.";
        }
        if (ContainsInsensitive(special, "tranh mua")) {
            specialNote = "Uu tien hoat dong trong nha hoac co mai che de tranh mua.";
        }

        var interestText = interests.Count == 0 ? "chua chon so thich" : string.Join(", ", interests);
        return new PreferenceProfile(
            $"Phu hop voi nhom {group}, so thich: {interestText}. {specialNote}",
            "Bat dau nhe de giu suc cho ca ngay.",
            groupNote,
            foodNote,
            specialNote,
            "Chen khoang nghi de lich khong bi qua day.",
            ContainsInsensitive(group, "nguoi yeu")
                ? "Ket thuc ngay bang diem ngam canh, cafe yen tinh hoac bua toi lang man."
                : "Ket thuc ngay bang khu an uong, cho dem hoac hoat dong nhe gan trung tam.");
    }

    private static DayActivityPlan BuildDayActivityPlan(string destinationName, PreferenceProfile profile, int day)
    {
        var summary = profile.Summary;
        var places = CuratedPlacesFor(destinationName);
        var wantsFood = ContainsInsensitive(summary, "am thuc");
        var wantsNature = ContainsInsensitive(summary, "thien nhien");
        var wantsBeach = ContainsInsensitive(summary, "bien");
        var wantsPhoto = ContainsInsensitive(summary, "chup anh");
        var wantsCulture = ContainsInsensitive(summary, "van hoa");
        var wantsNightlife = ContainsInsensitive(summary, "nightlife");
        var wantsResort = ContainsInsensitive(summary, "nghi duong");
        var wantsBudget = ContainsInsensitive(summary, "tiet kiem");
        var vegan = ContainsInsensitive(summary, "an chay");
        var avoidWalking = ContainsInsensitive(summary, "tranh di bo") || ContainsInsensitive(summary, "nguoi lon tuoi");
        var kids = ContainsInsensitive(summary, "tre em") || ContainsInsensitive(summary, "gia dinh");

        // Xoay vòng địa điểm theo ngày để mỗi ngày có một bộ địa điểm khác nhau.
        var pool = places.AllOrdered().ToList();
        if (pool.Count == 0) pool = new List<string> { destinationName };
        var morningPick = pool[WrapIndex(0, pool.Count, day)];
        var firstStopPick = pool[WrapIndex(1, pool.Count, day)];
        var lunchPick = pool[WrapIndex(2, pool.Count, day)];
        var afternoonPick = pool[WrapIndex(3, pool.Count, day)];
        var restPick = pool[WrapIndex(4, pool.Count, day)];
        var eveningPick = pool[WrapIndex(5, pool.Count, day)];

        var morning = vegan ? places.Vegan : wantsFood ? places.Food : morningPick;
        var firstStop = wantsBeach
            ? places.Beach
            : wantsNature
                ? places.Nature
                : wantsCulture
                    ? places.Culture
                    : wantsPhoto
                        ? places.Photo
                        : firstStopPick;
        if (kids) firstStop = places.Family;
        if (avoidWalking) firstStop = places.EasyAccess;

        var lunch = vegan ? places.Vegan : wantsBudget ? places.Market : wantsFood ? places.Food : lunchPick;
        var afternoon = wantsResort
            ? places.Resort
            : wantsNature
                ? places.NatureAlt
                : wantsCulture
                    ? places.CultureAlt
                    : wantsPhoto
                        ? places.PhotoAlt
                        : afternoonPick;
        var rest = wantsFood
            ? places.Cafe
            : wantsResort
                ? places.Resort
                : restPick;
        var evening = wantsNightlife
            ? places.Nightlife
            : wantsFood
                ? places.NightMarket
                : eveningPick;

        return new DayActivityPlan(morning, firstStop, lunch, afternoon, rest, evening);
    }

    private static int WrapIndex(int slot, int count, int day)
    {
        // Day bắt đầu từ 1, mỗi ngày +slot tăng thêm 6 bước để các slot lệch
        // hẳn về phía sau, đảm bảo ngày 2, 3, ... chọn địa điểm hoàn toàn khác.
        return ((slot + (day - 1) * 6) % count + count) % count;
    }

    private sealed record CuratedPlaceSet(
        string Morning,
        string Food,
        string Vegan,
        string Highlight,
        string Beach,
        string Nature,
        string Culture,
        string Photo,
        string Family,
        string EasyAccess,
        string Market,
        string Lunch,
        string Resort,
        string NatureAlt,
        string CultureAlt,
        string PhotoAlt,
        string Experience,
        string Cafe,
        string Nightlife,
        string NightMarket,
        string Evening)
    {
        public IReadOnlyList<string> AllOrdered() => new[]
        {
            Morning, Highlight, Lunch, AfternoonOrExperience(), RestCafe(), EveningOrNight()
        };

        private string AfternoonOrExperience() => Experience;
        private string RestCafe() => Cafe;
        private string EveningOrNight() => NightMarket;
    }

    private static CuratedPlaceSet CuratedPlacesFor(string destinationName)
    {
        if (ContainsInsensitive(destinationName, "ben tre"))
        {
            return new CuratedPlaceSet(
                "Chợ Bến Tre",
                "Chợ Bến Tre",
                "Quán chay Thiện Duyên Bến Tre",
                "Cồn Phụng",
                "Cồn Phụng",
                "Khu du lịch Lan Vương",
                "Nhà cổ Huỳnh Phủ",
                "Làng hoa Chợ Lách",
                "Khu du lịch Lan Vương",
                "Cồn Phụng",
                "Chợ Bến Tre",
                "Nhà hàng nổi TTC Bến Tre",
                "Mekong Home Bến Tre",
                "Sân chim Vàm Hồ",
                "Lò kẹo dừa Bến Tre",
                "Làng hoa Chợ Lách",
                "Khu du lịch Lan Vương",
                "Cafe Hẻm Bến Tre",
                "Phố đi bộ Bến Tre",
                "Chợ đêm Bến Tre",
                "Bờ sông Bến Tre");
        }
        if (ContainsInsensitive(destinationName, "ha noi"))
        {
            return new CuratedPlaceSet("Phố cổ Hà Nội", "Bún chả Hương Liên", "Ưu Đàm Chay", "Hồ Hoàn Kiếm", "Hồ Tây", "Vườn quốc gia Ba Vì", "Văn Miếu - Quốc Tử Giám", "Phố bích họa Phùng Hưng", "Thủy cung Lotte World Aquarium Hà Nội", "Hồ Hoàn Kiếm", "Chợ Đồng Xuân", "Bún chả Hương Liên", "Khách sạn Apricot Hà Nội", "Hồ Tây", "Bảo tàng Dân tộc học Việt Nam", "Nhà thờ Lớn Hà Nội", "Hoàng thành Thăng Long", "Cafe Giảng", "Tạ Hiện", "Chợ đêm phố cổ Hà Nội", "Hồ Hoàn Kiếm");
        }
        if (ContainsInsensitive(destinationName, "da nang"))
        {
            return new CuratedPlaceSet("Chợ Hàn", "Mì Quảng Bà Mua", "Nhà hàng chay Ans Vegetarian", "Cầu Rồng", "Bãi biển Mỹ Khê", "Bán đảo Sơn Trà", "Bảo tàng Điêu khắc Chăm", "Cầu Tình Yêu Đà Nẵng", "Asia Park Đà Nẵng", "Cầu Rồng", "Chợ Cồn", "Mì Quảng Bà Mua", "InterContinental Danang Sun Peninsula Resort", "Ngũ Hành Sơn", "Bảo tàng Đà Nẵng", "Cầu Vàng Bà Nà Hills", "Bà Nà Hills", "NAM House Cafe", "An Thượng Night Street", "Chợ đêm Sơn Trà", "Cầu Rồng");
        }
        if (ContainsInsensitive(destinationName, "phu quoc"))
        {
            return new CuratedPlaceSet("Chợ Dương Đông", "Bún quậy Kiến Xây", "Nhà hàng chay Phú Quốc", "Dinh Cậu", "Bãi Sao", "Suối Tranh", "Nhà tù Phú Quốc", "Sunset Sanato Beach Club", "VinWonders Phú Quốc", "Dinh Cậu", "Chợ Dương Đông", "Bún quậy Kiến Xây", "Premier Village Phu Quoc Resort", "Hòn Thơm", "Làng chài Hàm Ninh", "Sunset Sanato Beach Club", "Grand World Phú Quốc", "Chuồn Chuồn Bistro & Sky Bar", "Grand World Phú Quốc", "Chợ đêm Phú Quốc", "Dinh Cậu");
        }
        if (ContainsInsensitive(destinationName, "da lat"))
        {
            return new CuratedPlaceSet("Chợ Đà Lạt", "Bánh căn Nhà Chung", "Nhà hàng chay Hoa Sen Đà Lạt", "Quảng trường Lâm Viên", "Hồ Tuyền Lâm", "Thung lũng Tình Yêu", "Dinh Bảo Đại", "Ga Đà Lạt", "Vườn hoa thành phố Đà Lạt", "Quảng trường Lâm Viên", "Chợ Đà Lạt", "Bánh căn Nhà Chung", "Ana Mandara Villas Dalat", "Langbiang", "Nhà thờ Domaine de Marie", "Ga Đà Lạt", "Đường hầm Đất Sét", "Tiệm cà phê Túi Mơ To", "Chợ đêm Đà Lạt", "Chợ đêm Đà Lạt", "Hồ Xuân Hương");
        }
        return new CuratedPlaceSet(
            $"Chợ trung tâm {destinationName}",
            $"Quán đặc sản nổi bật tại {destinationName}",
            $"Nhà hàng chay trung tâm {destinationName}",
            $"Điểm tham quan nổi bật {destinationName}",
            $"Khu biển/ven sông nổi bật {destinationName}",
            $"Khu sinh thái hoặc công viên nổi bật {destinationName}",
            $"Bảo tàng/di tích nổi bật {destinationName}",
            $"Điểm check-in nổi bật {destinationName}",
            $"Khu vui chơi gia đình {destinationName}",
            $"Điểm tham quan dễ tiếp cận {destinationName}",
            $"Chợ trung tâm {destinationName}",
            $"Nhà hàng địa phương nổi bật {destinationName}",
            $"Khách sạn/resort nổi bật {destinationName}",
            $"Khu thiên nhiên nổi bật {destinationName}",
            $"Làng nghề/chợ địa phương {destinationName}",
            $"Điểm chụp ảnh đẹp {destinationName}",
            $"Khu trải nghiệm địa phương {destinationName}",
            $"Cafe nổi bật {destinationName}",
            $"Khu phố đêm {destinationName}",
            $"Chợ đêm/khu ẩm thực {destinationName}",
            $"Khu trung tâm {destinationName}");
    }

    private static TripFeasibility AnalyzeTripFeasibility(GenerateItineraryRequest request)
    {
        var days = Math.Max(1, (request.ReturnDate.Date - request.DepartureDate.Date).Days + 1);
        var nights = Math.Max(0, days - 1);
        var routeLegs = request.RouteLegs ?? Array.Empty<TripRouteLegInput>();
        var interests = request.Interests ?? Array.Empty<string>();
        var budgetTotal = request.BudgetPerPerson;
        var userBudgetPerPerson = budgetTotal / request.PeopleCount;

        var transportPerPerson = routeLegs.Count > 0
            ? routeLegs.Sum(x => Math.Max(0, x.EstimatedCostVnd))
            : EstimateFallbackTransportPerPerson(request);

        var foodPerDay = interests.Any(x => ContainsInsensitive(x, "am thuc") || ContainsInsensitive(x, "food"))
            ? 260_000m
            : 190_000m;
        var accommodationPerNight = userBudgetPerPerson >= 5_000_000m ? 650_000m : 380_000m;
        if (ContainsInsensitive(request.TravelGroup, "gia dinh")) accommodationPerNight += 120_000m;
        if (ContainsInsensitive(request.SpecialRequest, "tre em")) accommodationPerNight += 120_000m;

        var activityPerDay = interests.Any(x => ContainsInsensitive(x, "nghi duong") || ContainsInsensitive(x, "nightlife"))
            ? 260_000m
            : 150_000m;

        var foodPerPerson = foodPerDay * days;
        var accommodationPerPerson = accommodationPerNight * nights;
        var activitiesPerPerson = activityPerDay * days;
        var subtotalPerPerson = transportPerPerson + foodPerPerson + accommodationPerPerson + activitiesPerPerson;
        var bufferPerPerson = Math.Round(subtotalPerPerson * 0.1m, 0);
        var estimatedPerPerson = subtotalPerPerson + bufferPerPerson;
        var estimatedTotal = estimatedPerPerson * request.PeopleCount;
        var gap = estimatedTotal - budgetTotal;
        var ratio = budgetTotal <= 0 ? 999m : estimatedTotal / budgetTotal;

        var status = ratio <= 1.0m ? "feasible" : ratio <= 1.25m ? "tight" : "not_feasible";
        var warnings = new List<string>();
        var recommendations = new List<string>();

        if (status == "not_feasible")
        {
            warnings.Add($"Ngan sach hien tai thieu khoang {Math.Round(gap, 0):N0}d so voi muc toi thieu thuc te.");
            recommendations.Add("Tang ngan sach, giam so ngay hoac giam so diem den.");
        }
        else if (status == "tight")
        {
            warnings.Add("Ngan sach kha sat muc toi thieu, nen han che khach san/hoat dong gia cao.");
            recommendations.Add("Dat ve som va giu 10-15% ngan sach du phong.");
        }
        else
        {
            recommendations.Add("Ngan sach du de lap lich trinh tron ven neu giu dung phuong an di chuyen da chon.");
        }

        if (request.PeopleCount >= 8)
        {
            warnings.Add("Nhom dong nguoi can dat ve, phong va xe som de tranh lech gia.");
            recommendations.Add("Nen uu tien xe rieng/limousine hoac chia nhom nho khi di noi do.");
        }

        if (routeLegs.Any(x => ContainsInsensitive(x.Mode, "flight")))
            warnings.Add("Co chang may bay, gia ve co the tang manh neu dat sat ngay.");
        if (routeLegs.Any(x => ContainsInsensitive(x.Mode, "ferry")))
            warnings.Add("Co chang tau/pha, lich co the bi anh huong boi thoi tiet.");

        var message = status switch
        {
            "feasible" => "Chuyen di kha kha thi voi ngan sach va so nguoi hien tai.",
            "tight" => "Chuyen di co the thuc hien nhung ngan sach rat sat, can cat giam lua chon dat tien.",
            _ => "Chuyen di kho tron ven voi ngan sach hien tai neu giu nguyen so nguoi, so ngay va diem den."
        };

        return new TripFeasibility(
            status,
            budgetTotal,
            estimatedTotal,
            estimatedPerPerson,
            transportPerPerson,
            foodPerPerson,
            accommodationPerPerson,
            activitiesPerPerson,
            gap,
            message,
            recommendations.Distinct().Take(3).ToArray(),
            warnings.Distinct().Take(4).ToArray());
    }

    private static decimal EstimateFallbackTransportPerPerson(GenerateItineraryRequest request)
    {
        var hops = Math.Max(1, request.Destinations.Count);
        var hasLongTrip = request.Destinations.Any(x =>
            ContainsInsensitive(x.Name, "ha noi") ||
            ContainsInsensitive(x.Name, "phu quoc") ||
            ContainsInsensitive(x.Name, "sapa") ||
            ContainsInsensitive(x.Name, "lao cai"));
        return hasLongTrip ? 1_800_000m * hops : 450_000m * hops;
    }

    private static bool ContainsInsensitive(string? value, string needle)
    {
        if (string.IsNullOrWhiteSpace(value)) return false;
        return NormalizeForSearch(value).Contains(NormalizeForSearch(needle), StringComparison.OrdinalIgnoreCase);
    }

    private static string NormalizeForSearch(string value)
    {
        var normalized = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(normalized.Length);
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                builder.Append(c);
        }
        return builder.ToString().Normalize(NormalizationForm.FormC).ToLowerInvariant();
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
