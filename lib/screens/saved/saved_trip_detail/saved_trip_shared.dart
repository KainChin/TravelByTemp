// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Shared card containers ───────────────────────────────────────────────────
// Style đồng bộ với saved_screen: card trắng + border 1px + shadow cực nhẹ
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _GradCard extends StatelessWidget {
  const _GradCard({required this.gradient, required this.child, this.padding = const EdgeInsets.all(20)});
  final LinearGradient gradient;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.last.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

// ─── Section label (đồng bộ với _SectionTitle của saved_screen) ────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label, this.trailing});
  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Empty state (đồng bộ với saved_screen) ──────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty();
  final bool _centered = true;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_task_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có hoạt động',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bấm "Thêm" ở góc trên để bắt đầu.',
            style: TextStyle(color: _muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
