import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  int _tabIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTitle(),
            _buildSummaryBar(),
            _buildTabSwitcher(),
            Expanded(child: _buildMapArea()),
            _buildDestinationList(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GradientButton(
                label: 'Save to My Itinerary',
                gradient: AppColors.gradientSave,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          _iconBtn(Icons.share_outlined),
          const SizedBox(width: 8),
          _iconBtn(Icons.favorite_border),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
        color: Colors.white,
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Your Itinerary ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Map', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              ],
            ),
            Text(
              'Visualize your trip route and explore destinations.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(Icons.schedule, '3 Days'),
          _SummaryItem(Icons.place, '2 Places'),
          _SummaryItem(Icons.account_balance_wallet, '₫1.5M'),
          _SummaryItem(Icons.house, 'Relaxing'),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tab('Itinerary', 0),
            _tab('Map View', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F4EA), Color(0xFFD4E8F0), Color(0xFFE8EEF4)],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _mapChip(Icons.list, 'All Stops'),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _mapChip(Icons.directions_car, 'Traffic'),
          ),
          Positioned(
            left: 12,
            bottom: 60,
            child: Column(
              children: [
                _mapFab(Icons.my_location),
                const SizedBox(height: 8),
                _mapFab(Icons.add),
                _mapFab(Icons.remove),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 60,
            child: _mapChip(Icons.center_focus_strong, 'Center Route'),
          ),
          Positioned(
            top: 45,
            left: 40,
            child: _pin('1', 'Đà Lạt'),
          ),
          Positioned(
            bottom: 80,
            right: 50,
            child: _pin('2', 'Nha Trang'),
          ),
          Positioned(
            left: MediaQuery.sizeOf(context).width * 0.35,
            top: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, size: 14, color: AppColors.accentBlue),
                  SizedBox(width: 4),
                  Text('2h 45m · 140 km', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _mapFab(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      child: Icon(icon, size: 18),
    );
  }

  Widget _pin(String num, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Text(num, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }

  Widget _buildDestinationList() {
    return SizedBox(
      height: 200,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _destCard('1', 'Đà Lạt', '2 Days / 1 Night', [
            ('Check-in Hotel', '08:00', Icons.hotel),
            ('Dalat Railway', '10:00', Icons.camera_alt),
            ('Lunch', '12:30', Icons.restaurant),
          ]),
          const SizedBox(height: 12),
          _destCard('2', 'Nha Trang', '1 Day', [
            ('Nha Trang Beach', '09:00', Icons.beach_access),
            ('Ponagar Tower', '11:00', Icons.account_balance),
          ]),
        ],
      ),
    );
  }

  Widget _destCard(String num, String city, String duration, List<(String, String, IconData)> activities) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(city, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Day', style: TextStyle(fontSize: 12)),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...activities.asMap().entries.map((e) {
                  final (title, time, icon) = e.value;
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primaryLight,
                              child: Text('${e.key + 1}', style: const TextStyle(fontSize: 9, color: AppColors.primary)),
                            ),
                            const Spacer(),
                            Icon(icon, size: 14, color: AppColors.primary),
                          ],
                        ),
                        const Spacer(),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: const Text('+ more', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.7, size.height * 0.75);

    canvas.drawPath(path, paint);

    for (var i = 1; i <= 5; i++) {
      final t = i / 6.0;
      final x = size.width * (0.25 + 0.45 * t);
      final y = size.height * (0.2 + 0.55 * t);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = AppColors.primary);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
