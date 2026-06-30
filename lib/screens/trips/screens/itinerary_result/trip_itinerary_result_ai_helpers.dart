// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

enum _AiChangeKind { reduceCost, addFood, addHotel, addPlace, transport }

class _AiDraft {
  const _AiDraft({
    required this.message,
    required this.changes,
  });

  final String message;
  final List<_AiChange> changes;
}

class _AiChange {
  const _AiChange({
    required this.kind,
    required this.title,
    required this.description,
  });

  final _AiChangeKind kind;
  final String title;
  final String description;
}

_AiDraft _draftFor(String prompt) {
  final value = _normalizeText(prompt);

  if (value.contains('chi phi') || value.contains('ngan sach') || value.contains('giam')) {
    return const _AiDraft(
      message: 'AI đề xuất giảm chi phí bằng cách cân lại chi phí hoạt động và chọn điểm ăn uống gần tuyến hiện tại.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.reduceCost,
          title: 'Giảm chi phí hoạt động',
          description: 'Ước tính tiết kiệm khoảng 12% ngân sách trong ngày.',
        ),
        _AiChange(
          kind: _AiChangeKind.addFood,
          title: 'Thêm quán ăn hợp lý',
          description: 'Ưu tiên quán gần điểm hiện tại để hạn chế di chuyển.',
        ),
      ],
    );
  }

  if (value.contains('khach san')) {
    return const _AiDraft(
      message: 'AI sẽ ưu tiên khách sạn gần cụm hoạt động để giảm thời gian di chuyển và giữ ngân sách dễ kiểm soát.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.addHotel,
          title: 'Đổi/Thêm khách sạn phù hợp',
          description: 'Tối ưu vị trí lưu trú gần cụm hoạt động trong ngày.',
        ),
        _AiChange(
          kind: _AiChangeKind.reduceCost,
          title: 'Cân lại ngân sách lưu trú',
          description: 'Giảm các chi phí chưa cần thiết trong ngày.',
        ),
      ],
    );
  }

  if (value.contains('phuong tien') || value.contains('di chuyen')) {
    return const _AiDraft(
      message: 'AI đề xuất kiểm tra lại chặng di chuyển để giảm thời gian quay đầu trong ngày.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.transport,
          title: 'Đổi phương tiện',
          description: 'Sắp xếp lại chặng di chuyển để tiết kiệm thời gian.',
        ),
      ],
    );
  }

  if (value.contains('quan an') || value.contains('nha hang')) {
    return const _AiDraft(
      message: 'AI sẽ thêm quán ăn gần điểm hiện tại để không làm lệch tuyến tham quan.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.addFood,
          title: 'Thêm quán ăn gần địa điểm hiện tại',
          description: 'Không làm lệch tuyến tham quan trong ngày.',
        ),
      ],
    );
  }

  if (value.contains('dia diem') || value.contains('tham quan') || value.contains('gan day')) {
    return const _AiDraft(
      message: 'AI đề xuất thêm điểm tham quan gần tuyến hiện tại và không làm lịch quá dày.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.addPlace,
          title: 'Thêm điểm tham quan gần đây',
          description: 'Chèn vào khoảng trống phù hợp trong lịch trình.',
        ),
      ],
    );
  }

  if (value.contains('toi uu') || value.contains('lich trinh')) {
    return const _AiDraft(
      message: 'AI đề xuất tối ưu thứ tự hoạt động để giảm thời gian di chuyển trong ngày.',
      changes: [
        _AiChange(
          kind: _AiChangeKind.transport,
          title: 'Tối ưu thứ tự di chuyển',
          description: 'Giảm thời gian quay đầu giữa các điểm.',
        ),
      ],
    );
  }

  return const _AiDraft(
    message: 'AI đã nhận yêu cầu của bạn, nhưng hiện chưa có thao tác chỉnh lịch phù hợp để áp dụng tự động. Hãy thử yêu cầu cụ thể hơn như giảm chi phí, thêm quán ăn, đổi khách sạn hoặc đổi phương tiện.',
    changes: [],
  );
}

int _humanizeCost(int value, int seed) {
  if (value <= 0) return 0;
  if (value % 1000 != 0) return value;
  final offset = 3000 + (seed % 23) * 700;
  return value + offset;
}
