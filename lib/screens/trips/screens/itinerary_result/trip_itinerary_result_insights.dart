// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class AiInsightSection extends StatelessWidget {
  const AiInsightSection({super.key});

  @override
  Widget build(BuildContext context) {
    const reasons = [
      'Tuyến đường được sắp xếp để hạn chế quay đầu.',
      'Các địa điểm được nhóm theo khu vực trong từng ngày.',
      'Thời gian tham quan được chia đều để tránh lịch quá dày.',
      'Phương tiện và hoạt động cân bằng giữa chi phí và thời gian.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _TripItineraryResultScreenState._primarySoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4EDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.psychology_alt_outlined,
                  color: _TripItineraryResultScreenState._primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vì sao AI chọn lịch trình này?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reasons.map((reason) => _BulletLine(text: reason)),
        ],
      ),
    );
  }
}

class BookingSection extends StatelessWidget {
  const BookingSection({
    super.key,
    required this.days,
    required this.onBookFlight,
    required this.onBookHotel,
    required this.onBookTickets,
  });

  final List<Map<String, dynamic>> days;
  final VoidCallback onBookFlight;
  final VoidCallback onBookHotel;
  final VoidCallback onBookTickets;

  @override
  Widget build(BuildContext context) {
    final activities = days.expand(_activitiesFor).toList();
    final hasFlight = activities.any((item) => _normalizeText('${item['activity']} ${item['note']}').contains('may bay'));
    final hasHotel = activities.any((item) => _activityCategory(item) == 'khách sạn');
    final hasTickets = activities.any((item) => _activityCategory(item) == 'tham quan' && _activityCost(item) > 0);
    final flightBooked = activities.any((item) => _isBooked(item) && _normalizeText('${item['activity']} ${item['note']}').contains('may bay'));
    final hotelBooked = activities.any((item) => _isBooked(item) && _activityCategory(item) == 'khách sạn');
    final ticketsBooked = activities.any((item) => _isBooked(item) && _activityCategory(item) == 'tham quan');

    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái đặt dịch vụ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _BookingStatusCard(
            icon: Icons.flight_takeoff,
            label: 'Vé máy bay',
            needed: hasFlight,
            booked: flightBooked,
            onBook: onBookFlight,
          ),
          _BookingStatusCard(
            icon: Icons.hotel_outlined,
            label: 'Khách sạn',
            needed: hasHotel,
            booked: hotelBooked,
            onBook: onBookHotel,
          ),
          _BookingStatusCard(
            icon: Icons.confirmation_number_outlined,
            label: 'Vé tham quan',
            needed: hasTickets,
            booked: ticketsBooked,
            onBook: onBookTickets,
          ),
        ],
      ),
    );
  }
}

class AiChecklistSection extends StatelessWidget {
  const AiChecklistSection({super.key, required this.days});

  final List<Map<String, dynamic>> days;

  @override
  Widget build(BuildContext context) {
    final activities = days.expand(_activitiesFor).toList();
    final items = [
      _ChecklistData(
        'Đặt vé máy bay',
        activities.any((item) => _isBooked(item) && _normalizeText('${item['activity']} ${item['note']}').contains('may bay')),
      ),
      _ChecklistData(
        'Đặt khách sạn',
        activities.any((item) => _isBooked(item) && _activityCategory(item) == 'khách sạn'),
      ),
      const _ChecklistData('Chuẩn bị giấy tờ', false),
      const _ChecklistData('Chuẩn bị hành lý', false),
      _ChecklistData(
        'Đặt vé tham quan',
        activities.any((item) => _isBooked(item) && _activityCategory(item) == 'tham quan'),
      ),
    ];
    final done = items.where((item) => item.checked).length;
    final progress = items.isEmpty ? 0.0 : done / items.length;

    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_outlined, color: _TripItineraryResultScreenState._primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('AI Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              Text(
                '$done/${items.length}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: _TripItineraryResultScreenState._primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EFEA),
              color: _TripItineraryResultScreenState._primary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _ChecklistLine(text: item.label, checked: item.checked)),
        ],
      ),
    );
  }
}

class _BookingStatusCard extends StatelessWidget {
  const _BookingStatusCard({
    required this.icon,
    required this.label,
    required this.needed,
    required this.booked,
    required this.onBook,
  });

  final IconData icon;
  final String label;
  final bool needed;
  final bool booked;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final statusLabel = booked ? 'Đã đặt' : needed ? 'Cần đặt' : 'Không cần';
    final statusColor = booked
        ? _TripItineraryResultScreenState._primary
        : needed
            ? const Color(0xFFBE123C)
            : _TripItineraryResultScreenState._muted;
    final statusBg = booked
        ? _TripItineraryResultScreenState._primarySoft
        : needed
            ? const Color(0xFFFFE4E6)
            : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TripItineraryResultScreenState._line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: _TripItineraryResultScreenState._primarySoft,
            child: Icon(icon, color: _TripItineraryResultScreenState._primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (needed && !booked) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onBook, child: const Text('Đặt ngay')),
          ],
        ],
      ),
    );
  }
}

bool _isBooked(Map<String, dynamic> item) {
  final raw = _normalizeText(
    '${item['bookingStatus'] ?? item['booking_status'] ?? item['status'] ?? item['booked'] ?? ''}',
  );
  return raw == 'true' ||
      raw.contains('booked') ||
      raw.contains('confirmed') ||
      raw.contains('da dat') ||
      raw.contains('paid');
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.text, required this.checked});

  final String text;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 20,
            color: checked ? _TripItineraryResultScreenState._primary : _TripItineraryResultScreenState._muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check_circle, size: 15, color: _TripItineraryResultScreenState._primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _TripItineraryResultScreenState._ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistData {
  const _ChecklistData(this.label, this.checked);

  final String label;
  final bool checked;
}
