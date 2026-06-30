// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class _InlineMenuBar extends StatelessWidget {
  const _InlineMenuBar();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.explore_outlined, 'Explore'),
      (Icons.favorite_outline, 'Saved'),
      (Icons.luggage, 'Trips'),
      (Icons.chat_bubble_outline, 'Messages'),
      (Icons.person_outline, 'Profile'),
    ];
    return SafeArea(
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: Row(
          children: items.map((item) {
            final active = item.$2 == 'Trips';
            return Expanded(
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: active ? _TripItineraryResultScreenState._primary : const Color(0xFF9CA3AF), size: 22),
                    const SizedBox(height: 3),
                    Text(item.$2, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? _TripItineraryResultScreenState._primary : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _TripItineraryResultScreenState._bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(18)),
      child: const Column(
        children: [
          Icon(Icons.route_outlined, color: _TripItineraryResultScreenState._muted),
          SizedBox(height: 8),
          Text('Chưa có hoạt động cho ngày này', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}




class _AddMenuItem extends StatelessWidget {
  const _AddMenuItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _TripItineraryResultScreenState._primarySoft,
        child: Icon(icon, color: _TripItineraryResultScreenState._primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}




