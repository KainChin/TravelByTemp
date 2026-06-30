// ignore_for_file: use_string_in_part_of_directives

part of create_trip_screen;

class _HeroInterviewCard extends StatelessWidget {
  const _HeroInterviewCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _AiInterviewViewState._primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeNetworkImage(
              url: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
              source: 'create trip hero image',
              fallback: const SizedBox.shrink(),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE80A241E), Color(0x66152F28)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Lập hành trình',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 84),
                const Text(
                  'Kể mình nghe\nchuyến đi bạn muốn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chọn điểm đến, thời gian, ngân sách và nhóm đi để app gợi ý tuyến đường phù hợp.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



