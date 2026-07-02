// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Budget Section ───────────────────────────────────────────────────────────
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.projected, required this.actual,
    required this.totalProjected, required this.totalActual,
    required this.fmt, required this.catIcon, required this.catLabel,
    required this.catColor, required this.onAddExpense,
  });
  final Map<String, int> projected, actual;
  final int totalProjected, totalActual;
  final String Function(int) fmt;
  final IconData Function(String) catIcon;
  final String Function(String) catLabel;
  final Color Function(String) catColor;
  final void Function(String) onAddExpense;

  static const _keys = ['transport', 'accommodation', 'food', 'activities'];

  @override
  Widget build(BuildContext context) => Column(children: [
    _GradCard(
      gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Text('Ngân sách Dự kiến', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
        const SizedBox(height: 14),
        _TotalRow(label: 'Tổng dự kiến', value: fmt(totalProjected), dark: true),
        const SizedBox(height: 14),
        ..._keys.map((k) => _BudgetBar(icon: catIcon(k), label: catLabel(k),
            value: projected[k] ?? 0, total: totalProjected, color: catColor(k), fmt: fmt)),
      ]),
    ),
    const SizedBox(height: 14),
    _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _SectionLabel(icon: Icons.receipt_long_rounded, label: 'Chi tiêu Thực tế'),
        const Spacer(),
        _StatusBadge(over: totalActual > totalProjected),
      ]),
      const SizedBox(height: 12),
      _TotalRow(
        label: 'Tổng thực tế', value: fmt(totalActual), dark: false,
        overBudget: totalActual > totalProjected,
      ),
      const SizedBox(height: 14),
      ..._keys.map((k) => _ActualBar(
        icon: catIcon(k), label: catLabel(k),
        actual: actual[k] ?? 0, projected: projected[k] ?? 0,
        barColor: catColor(k), fmt: fmt, onAdd: () => onAddExpense(k),
      )),
    ])),
  ]);
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, required this.dark, this.overBudget = false});
  final String label, value;
  final bool dark, overBudget;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : (overBudget ? Colors.red : _indigo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.1) : null,
        gradient: dark ? null : LinearGradient(colors: [textColor.withValues(alpha: 0.08), Colors.transparent]),
        borderRadius: BorderRadius.circular(14),
        border: dark ? null : Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(color: dark ? Colors.white70 : _muted, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.over});
  final bool over;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      gradient: over ? _gradRed : _gradTeal,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [BoxShadow(color: (over ? Colors.red : _teal).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Text(over ? 'Vượt ngân sách' : 'Trong ngân sách',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
  );
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.icon, required this.label, required this.value,
      required this.total, required this.color, required this.fmt});
  final IconData icon; final String label; final int value, total; final Color color; final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
          Text(fmt(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ]),
        const SizedBox(height: 6),
        _GlowBar(ratio: ratio, color: color, bg: Colors.white.withValues(alpha: 0.1)),
      ]),
    );
  }
}

class _ActualBar extends StatelessWidget {
  const _ActualBar({required this.icon, required this.label, required this.actual,
      required this.projected, required this.barColor, required this.fmt, required this.onAdd});
  final IconData icon; final String label; final int actual, projected; final Color barColor;
  final String Function(int) fmt; final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ratio = projected > 0 ? (actual / projected).clamp(0.0, 1.0) : 0.0;
    final over = actual > projected;
    final c = over ? Colors.red : barColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Text(fmt(actual), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onAdd, child: Container(
            width: 26, height: 26,
            decoration: BoxDecoration(gradient: _gradIndigo, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.35), blurRadius: 8)]),
            child: const Icon(Icons.add, size: 15, color: Colors.white),
          )),
        ]),
        const SizedBox(height: 6),
        _GlowBar(ratio: ratio, color: c, bg: _line),
        if (projected > 0)
          Align(alignment: Alignment.centerRight,
              child: Text('/ ${fmt(projected)}', style: const TextStyle(fontSize: 10, color: _muted))),
      ]),
    );
  }
}

class _GlowBar extends StatelessWidget {
  const _GlowBar({required this.ratio, required this.color, required this.bg});
  final double ratio; final Color color, bg;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: Stack(children: [
      Container(height: 8, color: bg),
      FractionallySizedBox(widthFactor: ratio, child: Container(
        height: 8,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
        ),
      )),
    ]),
  );
}

// ─── Expense Sheet (modal) ────────────────────────────────────────────────────
class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.categoryLabel, required this.onSave});
  final String categoryLabel;
  final void Function(int) onSave;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Nhập chi tiêu – ${widget.categoryLabel}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 16),
      TextField(
        controller: _ctrl, keyboardType: TextInputType.number, autofocus: true,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: 'Số tiền (VNĐ)', filled: true, fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          suffixText: 'đ',
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, height: 52, child: DecoratedBox(
        decoration: BoxDecoration(gradient: _gradIndigo, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]),
        child: ElevatedButton(
          onPressed: () {
            final v = int.tryParse(_ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            widget.onSave(v);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Lưu chi tiêu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      )),
    ]),
  );
}

// ─── Bill Scan Card ───────────────────────────────────────────────────────────
class _BillScanCard extends StatelessWidget {
  const _BillScanCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D28D9), Color(0xFF0D9488)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(color: _indigo.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(8, 16)),
      ],
    ),
    child: Row(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0x33FFFFFF), Color(0x0AFFFFFF)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(4, 4)),
            BoxShadow(color: Color(0x11FFFFFF), blurRadius: 10, offset: Offset(-2, -2)),
          ],
        ),
        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 30),
      ),
      const SizedBox(width: 16),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI Phân tích & Scan Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        SizedBox(height: 5),
        Text('Chụp/Tải hóa đơn để AI cập nhật chi tiêu thực tế tự động.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45)),
      ])),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))]),
        child: const Text('Scan', style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w900, fontSize: 12)),
      ),
    ]),
  );
}
