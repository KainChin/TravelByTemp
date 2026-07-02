// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Shared card containers ───────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(color: Color(0x080F172A), blurRadius: 24, offset: Offset(0, 10)),
        BoxShadow(color: Color(0x040F172A), blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: child,
  );
}

class _GradCard extends StatelessWidget {
  const _GradCard({required this.gradient, required this.child});
  final LinearGradient gradient; final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: gradient, borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x331A1F36), blurRadius: 28, offset: Offset(0, 14))],
    ),
    child: child,
  );
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon; final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(gradient: _gradIndigo, borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Icon(icon, size: 15, color: Colors.white),
    ),
    const SizedBox(width: 9),
    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
  ]);
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Chưa có hoạt động', style: TextStyle(color: _muted)),
    ),
  );
}
