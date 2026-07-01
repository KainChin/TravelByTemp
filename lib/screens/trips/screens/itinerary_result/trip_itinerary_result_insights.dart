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


