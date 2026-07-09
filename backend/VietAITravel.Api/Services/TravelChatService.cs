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
    public string ChatModel { get; set; } = "llama-3.1-8b-instant";
}

public sealed partial class TravelChatService(
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


    public async Task<ChatEnvelopeResponse> GenerateItineraryAsync(GenerateItineraryRequest request, CancellationToken ct)
    {
        if (request.Destinations.Count == 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "At least one destination is required.");
        if (request.PeopleCount <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "People count must be greater than zero.");
        if (request.BudgetPerPerson <= 0)
            throw new TravelAiException(StatusCodes.Status400BadRequest, "Trip budget must be greater than zero.");

        var feasibility = AnalyzeTripFeasibility(request);
        var roundTripTransportPerPerson = (request.RouteLegs ?? []).Sum(x => x.EstimatedCostVnd) * 2;
        var groupRoundTripTransport = roundTripTransportPerPerson * request.PeopleCount;
        var totalBudget = request.BudgetPerPerson;
        var remainingBudget = totalBudget - groupRoundTripTransport;
        var destinationNames = string.Join(", ", request.Destinations.Select(d => d.Name));
        
        var prompt = $$"""
            Tao lich trinh du lich bang tieng Viet tu form nguoi dung.
            Chi tra ve JSON hop le, khong markdown. Moi ngay phai co 6-8 hoat dong trai dai tu sang den toi.
            Chi phi tung hoat dong phai la so le thuc te theo Viet Nam, khong dung toan so tron nhu 100000/200000.
            
            QUAN TRONG: ĐỊA ĐIỂM DU LỊCH BẮT BUỘC LÀ: {{destinationNames}}.
            => BẠN KHÔNG ĐƯỢC PHÉP đổi sang thành phố khác (ví dụ: đang ở Bến Tre/Hà Tiên tuyệt đối không được viết lịch trình Hà Nội/Đà Lạt). Mọi hoạt động, ăn uống, vui chơi phải diễn ra tại {{destinationNames}}. CHÚ Ý: CHỈ GỢI Ý CÁC ĐỊA ĐIỂM TẠI TỈNH MÀ NGƯỜI DÙNG ĐÃ TỚI, TUYỆT ĐỐI KHÔNG LAN MAN SANG CÁC NƠI KHÁC NẰM NGOÀI {{destinationNames}}.
            
            QUAN TRONG: TỔNG NGÂN SÁCH CỦA NHÓM LÀ {{totalBudget}} VNĐ (cho {{request.PeopleCount}} người). NHƯNG CHI PHÍ DI CHUYỂN KHỨ HỒI ĐÃ CHIẾM HẾT {{groupRoundTripTransport}} VNĐ.
            => SỐ TIỀN CÒN LẠI ĐỂ TIÊU CHO CẢ NHÓM (ĂN UỐNG, KHÁCH SẠN, VUI CHƠI) CHỈ CÒN ĐÚNG: {{remainingBudget}} VNĐ.
            
            NẾU {{remainingBudget}} <= 0 HOẶC KHÔNG ĐỦ TIỀN KHÁCH SẠN:
            - TRẢ VỀ status của feasibility là "not_feasible", ghi rõ "message": "Chi phí di chuyển khứ hồi đã vượt quá hoặc chiếm gần hết ngân sách. Không đủ tiền để chi trả cho các hoạt động và chỗ ở."
            - Gợi ý người dùng đổi địa điểm gần hơn hoặc tăng ngân sách trong "recommendations".
            - BẠN BẮT BUỘC PHẢI THIẾT KẾ MỘT LỊCH TRÌNH MẪU ĐẠI KHÁI, NHƯNG HIỂN THỊ CẢNH BÁO. KHÔNG ĐƯỢC BỎ TRỐNG PHẦN ACTIVITIES.
            
            BẠN CHỈ ĐƯỢC PHÉP thiết kế các hoạt động sao cho TỔNG CHI PHÍ costBreakdown (không tính transport) KHÔNG ĐƯỢC VƯỢT QUÁ {{remainingBudget}} VNĐ (nếu còn tiền)!
            ĐẶC BIỆT LƯU Ý VỀ CHI TIÊU HẰNG NGÀY:
            - Phân bổ đều số tiền {{remainingBudget}} ra tất cả các ngày đi, tuyệt đối KHÔNG ĐƯỢC tiêu hết sạch tiền vào ngày đầu tiên.
            - Nếu {{remainingBudget}} còn quá ít (sau khi trừ vé xe/máy bay), PHẢI CHỈ ĐỊNH các địa điểm ăn uống bình dân, quán vỉa hè, tham quan miễn phí hoặc giá siêu rẻ (chợ đêm, công viên, bãi biển công cộng).
            - Nếu {{remainingBudget}} dư dả, hãy mạnh dạn đề xuất các nhà hàng sang trọng, resort, khu vui chơi giải trí cao cấp, ăn hải sản...
            - Giá tiền "estimatedCost" của mỗi hoạt động phải PHẢN ÁNH ĐÚNG mức độ ngân sách trên.            
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
            - BẮT BUỘC ĐA DẠNG HÓA VÀ CỤ THỂ HÓA LỊCH TRÌNH: MỘT ĐỊA ĐIỂM (nhà hàng, quán cafe, điểm tham quan) TUYỆT ĐỐI KHÔNG ĐƯỢC LẶP LẠI HAI LẦN TRONG CHUYẾN ĐI (ngoại trừ khách sạn). Các hoạt động trong cùng 1 ngày và giữa các ngày phải mang lại trải nghiệm hoàn toàn khác biệt nhau (ví dụ: sáng đi đảo/biển, chiều đi bảo tàng, tối đi chợ đêm). KHÔNG ĐƯỢC dùng các mô tả chung chung vô nghĩa như "Tham quan điểm nổi bật", "Ăn sáng", "Nghỉ ngơi" mà PHẢI nêu rõ đích danh (ví dụ: "Thưởng thức bún quậy Kiến Xây", "Tham quan Bảo tàng Quảng Ninh", "Chơi công viên Sun World"). Lịch trình chung chung, lặp lại địa điểm sẽ bị coi là lỗi nghiêm trọng.
            - TUYẾN ĐƯỜNG DI CHUYỂN HỢP LÝ (TỐI ƯU HÓA LỘ TRÌNH): Sắp xếp thứ tự các địa điểm đi trong ngày theo một lộ trình địa lý hợp lý. Tuyệt đối không được nhảy cóc qua lại liên tục giữa các nơi cách xa nhau (ví dụ: không đi Bãi Cháy -> Tuần Châu -> Cửa Lục rồi lại quay lại Bãi Cháy -> Cửa Lục). Hãy nhóm các địa điểm ở gần nhau vào cùng một buổi (Sáng/Chiều) để tránh việc phải quay đầu hay di chuyển lãng phí thời gian của người dùng.
            
            QUY ĐỊNH VỀ CHỖ NGHỈ/KHÁCH SẠN:
            - NẾU CHUYẾN ĐI TRONG 1 NGÀY (không qua đêm): TUYỆT ĐỐI KHÔNG xếp khách sạn. Chỉ xếp 1 mục "Nghỉ ngơi/Uống cafe" giá rẻ (dưới 100k) vào khoảng 15h-16h.
            - NẾU CHUYẾN ĐI TỪ 2 NGÀY TRỞ LÊN: PHẢI xếp 1 mục "Nhận phòng khách sạn / Nghỉ ngơi" vào lúc 14h-16h chiều ngày đầu tiên. Giá khách sạn phải tính toán cẩn thận để phù hợp với {{remainingBudget}} còn lại.
            Neu ngan sach khong du, khong duoc gia vo nhu chuyen di van tron ven.
            Phai them warnings ro rang va summary noi that: can cat giam hoat dong, doi phuong tien, giam ngay hoac tang ngan sach.
            QUY ĐỊNH TÍNH TOÁN CHI PHÍ (CỰC KỲ QUAN TRỌNG):
            - Trong object costBreakdown: "transport" PHẢI BẰNG ĐÚNG {{groupRoundTripTransport}}.
            - "total" (Tổng chi phí dự kiến) PHẢI LÀ PHÉP CỘNG CỦA: transport + food + accommodation + activities. KHÔNG ĐƯỢC BỊA SỐ.
            - Nếu "total" > {{totalBudget}} (Ngân sách ban đầu), status của feasibility phải là "not_feasible" hoặc "tight".
            Schema:
            {
              "title": "string",
              "summary": "string",
              "userBudget": 0,
              "peopleCount": 0,
              "days": [{"day": 1, "date": "yyyy-MM-dd", "activities": [{"time": "08:00", "destination": "ten dia diem cu the", "placeName": "ten dia diem cu the", "address": "string|null", "rating": 4.5, "activity": "string", "category": "ăn uống|tham quan|khách sạn|di chuyển", "estimatedCost": 0, "latitude": 0, "longitude": 0, "note": "string"}]}],
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
                content = """
                    You are an Expert Vietnam Travel Planning AI and an advanced AI Transportation & Budget Planning Engine for a Vietnam Travel Planning application.
                    Your mission is to create realistic, enjoyable, diverse, and practical travel itineraries. 
                    You must intelligently analyze ALL available information and determine the most realistic, safest, most economical transportation plan.
                    
                    CRITICAL RULES:
                    1. Never hallucinate. Never recommend impossible transportation. For example, flying from Ho Chi Minh City to Vung Tau is completely unrealistic and impossible; you must teach the AI to evaluate if the flight is realistic for the given distance. 
                    2. Combine multiple categories of experiences (Nature, Culture, etc.). Every day should feel unique.
                    3. ONLY suggest activities within the requested destination province.
                    4. Always return valid JSON according to the schema. Prioritize realistic planning over making things look "nice".
                    """
            },
            new { role = "user", content = $"{prompt}\nDu lieu form:\n{userData}" }
        };

        object? itinerary;
        try
        {
            using var aiTimeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
            aiTimeout.CancelAfter(TimeSpan.FromSeconds(180)); // Allow up to 3 minutes for local AI
            var json = await CallOllamaAsync(messages, jsonFormat: true, aiTimeout.Token);
            itinerary = JsonSerializer.Deserialize<object>(json, JsonOptions);
            if (itinerary is null)
                itinerary = BuildFallbackItinerary(request);
        }
        catch (Exception ex) when (ex is TravelAiException or JsonException or OperationCanceledException)
        {
            logger.LogWarning(ex, "Ollama failed or timed out. Trying Groq as fallback...");
            // Try Groq as secondary AI
            if (!string.IsNullOrWhiteSpace(groqOptions.ApiKey))
            {
                try
                {
                    using var groqTimeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
                    groqTimeout.CancelAfter(TimeSpan.FromSeconds(60));
                    var groqJson = await CallGroqAsync(messages, groqTimeout.Token);
                    itinerary = JsonSerializer.Deserialize<object>(groqJson, JsonOptions);
                    if (itinerary is null)
                        itinerary = BuildFallbackItinerary(request);
                    logger.LogInformation("Groq successfully generated the itinerary.");
                }
                catch (Exception groqEx)
                {
                    logger.LogWarning(groqEx, "Groq also failed. Using rule-based fallback.");
                    itinerary = BuildFallbackItinerary(request);
                }
            }
            else
            {
                logger.LogWarning("Groq API key not configured. Using rule-based fallback.");
                itinerary = BuildFallbackItinerary(request);
            }
        }

        return new ChatEnvelopeResponse("Da tao lich trinh.", itinerary);
    }

}
