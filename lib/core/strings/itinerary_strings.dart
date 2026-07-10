/// Centralized UI strings for the itinerary result screen.
///
/// Thay vì hardcode chuỗi tiếng Việt rải rác trong các file `part of`, ta gom
/// vào đây để:
/// - Dễ migrate sang `intl/AppLocalizations` sau này.
/// - Tìm kiếm / thay thế nhanh khi đổi copy.
/// - Tránh duplicate giữa các file (vd: 'Đã lưu hành trình').
library;

class ItineraryStrings {
  ItineraryStrings._();

  // ─── AppBar / page ────────────────────────────────────────────────────────
  static const String pageTitle = 'Chi tiết chuyến đi';
  static const String titleFallback = 'Hành trình đề xuất';
  static const String titleByDay = 'Hành trình theo ngày';
  static const String tooltipSaved = 'Đã lưu hành trình';
  static const String tooltipSave = 'Lưu hành trình';

  // ─── Default summary ──────────────────────────────────────────────────────
  static const String defaultSummary =
      'Lịch trình đã có bản đồ, chi phí từng hoạt động và có thể chỉnh sửa.';

  // ─── Bottom save bar ──────────────────────────────────────────────────────
  static const String saveLabel = 'Lưu lại';
  static const String savedLabel = 'Đã lưu';
  static const String savingLabel = 'Đang lưu...';
  static const String editLabel = 'Sửa';
  static const String aiLabel = 'AI';

  // ─── Add menu sheet ───────────────────────────────────────────────────────
  static const String addMenuTitle = 'Thêm vào lịch trình';
  static const String addMenuSubtitle = 'Chọn loại hoạt động bạn muốn thêm cho ngày này.';
  static const String addKindPlace = 'Địa điểm';
  static const String addKindRestaurant = 'Ăn uống';
  static const String addKindHotel = 'Khách sạn';
  static const String addKindActivity = 'Hoạt động';
  static const String addKindTransport = 'Di chuyển';

  // ─── Editor sheet ─────────────────────────────────────────────────────────
  static const String editorSaveButton = 'Lưu thay đổi';
  static const String fieldHour = 'Giờ';
  static const String fieldCost = 'Chi phí (VNĐ)';
  static const String fieldCategory = 'Danh mục';
  static const String fieldTitle = 'Hoạt động';
  static const String fieldDestination = 'Địa điểm';
  static const String fieldAddress = 'Địa chỉ';
  static const String fieldDuration = 'Thời lượng (phút)';
  static const String fieldNote = 'Ghi chú';
  static const String categorySightseeing = 'Tham quan';
  static const String categoryFood = 'Ăn uống';
  static const String categoryHotel = 'Khách sạn';
  static const String categoryTransport = 'Di chuyển';

  // ─── Validation ───────────────────────────────────────────────────────────
  static const String errorTimeFormat = 'Giờ phải có định dạng HH:mm (ví dụ 08:30).';
  static const String errorDestinationEmpty = 'Vui lòng nhập tên địa điểm.';
  static const String errorCostNotNumber = 'Chi phí phải là số (>= 0).';
  static const String errorCostNegative = 'Chi phí không được âm.';
  static const String errorDurationNotPositiveInt =
      'Thời lượng phải là số nguyên dương (phút).';
  static String errorTimeConflict(String otherTitle, String otherTime) =>
      'Khung giờ bị trùng với hoạt động "$otherTitle" lúc $otherTime.';
  static const String errorGeneric = 'Vui lòng kiểm tra lại thông tin.';

  // ─── Snackbar ─────────────────────────────────────────────────────────────
  static const String snackSavedToDatabase = 'Đã lưu hành trình lên database.';
  static const String snackSavedLocally = 'Đã lưu tạm hành trình trên máy.';
  static const String snackAiApplied = 'Đã áp dụng thay đổi AI vào lịch trình.';

  // ─── Empty states ─────────────────────────────────────────────────────────
  static const String emptyActivities = 'Chưa có hoạt động cho ngày này';
  static const String emptyActivitiesCta = 'Thêm hoạt động';

  // ─── Timeline ─────────────────────────────────────────────────────────────
  static const String timelineSectionTitle = 'Lịch trình trong ngày';
  static const String timelineAddButton = 'Thêm';
  static const String menuEdit = 'Chỉnh sửa';
  static const String menuAiOptimize = 'AI tối ưu lại hoạt động này';
  static const String menuDelete = 'Xóa';

  // ─── Budget ───────────────────────────────────────────────────────────────
  static const String budgetNotSelected = 'Chưa chọn';
  static const String budgetNoData = 'Chưa có dữ liệu';

  // ─── Chat (AI) ────────────────────────────────────────────────────────────
  static const String chatTitle = 'Trợ lý AI';
  static const String chatInputHint = 'Hỏi AI về chuyến đi...';
  static const String chatSend = 'Gửi';
  static const String aiDraftFallback =
      'AI đã nhận yêu cầu của bạn, nhưng hiện chưa có thao tác chỉnh lịch phù hợp để áp dụng tự động. Hãy thử yêu cầu cụ thể hơn như giảm chi phí, thêm quán ăn, đổi khách sạn hoặc đổi phương tiện.';

  // ─── Distance label ───────────────────────────────────────────────────────
  static const String distanceClose = 'Gần điểm tiếp theo';
  static String distanceNext(String km) => '$km km tới điểm kế';
}