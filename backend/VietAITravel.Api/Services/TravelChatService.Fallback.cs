using System.Globalization;
using System.Text;
using System.Text.Json;
using VietAITravel.Api.DTOs;
namespace VietAITravel.Api.Services;
public sealed partial class TravelChatService
{
    private static object BuildFallbackItinerary(GenerateItineraryRequest request)
    {
        var feasibility = AnalyzeTripFeasibility(request);
        var destinations = request.Destinations.Count == 0
            ? [new TripDestinationInput("fallback", "Diem den", null, null, request.DepartureDate, request.ReturnDate, null, null)]
            : request.Destinations;
        var profile = BuildPreferenceProfile(request);

        var totalDays = Math.Max(1, (request.ReturnDate.Date - request.DepartureDate.Date).Days + 1);
        var nights = Math.Max(0, totalDays - 1);
        // Remaining budget after round-trip transport deduction
        var roundTripTransport = feasibility.TransportPerPerson * 2;
        var userBudgetPerPerson = request.BudgetPerPerson / request.PeopleCount;
        var remainingPerPerson = Math.Max(0, userBudgetPerPerson - roundTripTransport);
        // Per-night hotel budget (priority allocation)
        var hotelPerNight = remainingPerPerson <= 600_000m ? 100_000m
            : remainingPerPerson <= 2_000_000m ? 250_000m
            : 450_000m;
        var totalHotelCost = hotelPerNight * nights;
        var budgetForActivities = Math.Max(0, remainingPerPerson - totalHotelCost);
        var perDayActivityBudget = totalDays > 0 ? budgetForActivities / totalDays : 0;
        var days = Enumerable.Range(1, totalDays).Select(day =>
        {
            var destination = destinations[(day - 1) % destinations.Count];
            var date = request.DepartureDate.Date.AddDays(day - 1);
            var latitude = destination.Latitude ?? 16.0544;
            var longitude = destination.Longitude ?? 108.2022;
            var daySeed = day * 13791 + destination.Name.Sum(c => c);
            decimal Cost(decimal ratio, int offset) =>
                Math.Round((perDayActivityBudget * ratio) + ((daySeed + offset) % 23000) + 5000, 0);
            var plan = BuildDayActivityPlan(destination.Name, profile, day);
            var places = CuratedPlacesFor(destination.Name);
            var hotelName = places.Resort;

            // Build activity list - only include hotel if multi-day trip
            var activityList = new List<object>
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
                }
            };

            // Only add hotel check-in for multi-day trips (at least 1 night)
            if (nights > 0)
            {
                activityList.Add(new
                {
                    time = "16:30",
                    destination = hotelName,
                    placeName = hotelName,
                    address = destination.Name,
                    rating = 4.3,
                    activity = $"Nhan phong khach san tai {hotelName}",
                    estimatedCost = Math.Round(hotelPerNight, 0),
                    category = "khách sạn",
                    latitude = latitude + 0.021,
                    longitude = longitude + 0.018,
                    note = "Nghi ngoi sau ngay dai, nhan phong sau 14:00."
                });
            }
            else
            {
                activityList.Add(new
                {
                    time = "16:30",
                    destination = plan.Evening,
                    placeName = plan.Evening,
                    address = destination.Name,
                    rating = 4.4,
                    activity = $"Nghi ngoi/check-in cafe tai {plan.Evening}",
                    estimatedCost = Cost(0.09m, 21100),
                    latitude = latitude + 0.021,
                    longitude = longitude + 0.018,
                    note = "Chuyen di trong ngay, nghi ngoi truoc khi ve."
                });
            }

            activityList.Add(new
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
            });

            return new
            {
                day,
                date = date.ToString("yyyy-MM-dd"),
                activities = activityList
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
                transport = Math.Round(roundTripTransport * request.PeopleCount, 0),
                food = Math.Round(feasibility.FoodPerPerson * request.PeopleCount, 0),
                accommodation = Math.Round(totalHotelCost * request.PeopleCount, 0),
                activities = Math.Round(budgetForActivities * request.PeopleCount, 0),
                total = Math.Round(request.BudgetPerPerson, 0),
                perPerson = Math.Round(userBudgetPerPerson, 0)
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

        var morning = vegan
            ? places.Vegan
            : wantsFood
                ? places.Food
                : places.Morning;

        var firstStop = wantsBeach
            ? places.Beach
            : wantsNature
                ? places.Nature
                : wantsCulture
                    ? places.Culture
                    : wantsPhoto
                        ? places.Photo
                        : places.Highlight;

        if (kids) firstStop = places.Family;
        if (avoidWalking) firstStop = places.EasyAccess;

        var lunch = vegan
            ? places.Vegan
            : wantsBudget
                ? places.Market
                : wantsFood
                    ? places.Food
                    : places.Lunch;

        var afternoon = wantsResort
            ? places.Resort
            : wantsNature
                ? places.NatureAlt
                : wantsCulture
                    ? places.CultureAlt
                    : wantsPhoto
                        ? places.PhotoAlt
                        : places.Experience;

        var rest = wantsFood
            ? places.Cafe
            : wantsResort
                ? places.Resort
                : places.Cafe;

        var evening = wantsNightlife
            ? places.Nightlife
            : wantsFood
                ? places.NightMarket
                : day % 2 == 0
                    ? places.NightMarket
                    : places.Evening;

        return new DayActivityPlan(morning, firstStop, lunch, afternoon, rest, evening);
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
        string Evening);

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

        // Round-trip: multiply one-way leg costs by 2
        var transportPerPerson = routeLegs.Count > 0
            ? routeLegs.Sum(x => Math.Max(0, x.EstimatedCostVnd)) * 2
            : EstimateFallbackTransportPerPerson(request) * 2;

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
}
