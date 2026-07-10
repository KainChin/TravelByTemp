// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Budget Section ───────────────────────────────────────────────────────────
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.projected, required this.actual,
    required this.totalProjected, required this.totalActual,
    required this.fmt, required this.catIcon, required this.catLabel,
    required this.catColor, required this.onAddExpense,
    this.scopeLabel = 'toàn chuyến đi',
  });
  final Map<String, int> projected, actual;
  final int totalProjected, totalActual;
  final String Function(int) fmt;
  final IconData Function(String) catIcon;
  final String Function(String) catLabel;
  final Color Function(String) catColor;
  final void Function(String) onAddExpense;
  /// Hiển thị giúp user biết số liệu đang cho phạm vi nào, ví dụ
  /// 'toàn chuyến đi' hoặc 'ngày 2'. Default = 'toàn chuyến đi'.
  final String scopeLabel;

  static const _keys = ['transport', 'accommodation', 'food', 'activities'];

  @override
  Widget build(BuildContext context) => Column(children: [
    _GradCard(
      gradient: _gradPrimary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Ngân sách Dự kiến',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              scopeLabel,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        _TotalRow(
          label: 'Tổng dự kiến',
          value: fmt(totalProjected),
          dark: true,
          highlightColor: Colors.white,
        ),
        const SizedBox(height: 14),
        ..._keys.map((k) => _BudgetBar(
          icon: catIcon(k),
          label: catLabel(k),
          value: projected[k] ?? 0,
          total: totalProjected,
          color: Colors.white,
          fmt: fmt,
        )),
      ]),
    ),
    const SizedBox(height: 14),
    _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: _SectionLabel(icon: Icons.receipt_long_rounded, label: 'Chi tiêu Thực tế')),
        _StatusBadge(over: totalActual > totalProjected),
      ]),
      const SizedBox(height: 12),
      _TotalRow(
        label: 'Tổng thực tế',
        value: fmt(totalActual),
        dark: false,
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
  const _TotalRow({
    required this.label,
    required this.value,
    required this.dark,
    this.overBudget = false,
    this.highlightColor,
  });
  final String label, value;
  final bool dark, overBudget;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? (dark ? Colors.white : _primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.15) : _primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: dark ? null : Border.all(color: _primary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(
              color: dark ? Colors.white.withValues(alpha: 0.9) : _muted,
              fontSize: 13,
            ),
        ),
        const Spacer(),
        Text(value,
            style: TextStyle(
              color: overBudget && !dark ? Colors.red : accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.over});
  final bool over;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      gradient: over ? _gradRed : _gradTeal,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [
        BoxShadow(
          color: (over ? Colors.red : _teal).withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      over ? 'Vượt ngân sách' : 'Trong ngân sách',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
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
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 7),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
          Text(fmt(value),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
        const SizedBox(height: 6),
        _GlowBar(ratio: ratio, color: color, bg: Colors.white.withValues(alpha: 0.2)),
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
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink))),
          Text(fmt(actual),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  gradient: _gradPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 15, color: Colors.white),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        _GlowBar(ratio: ratio, color: c, bg: _line),
        if (projected > 0)
          Align(alignment: Alignment.centerRight,
              child: Text('/ ${fmt(projected)}',
                  style: const TextStyle(fontSize: 10, color: _muted))),
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
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: _ink)),
      const SizedBox(height: 4),
      const Text('Số tiền bạn đã chi cho hạng mục này.',
          style: TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 18),
      TextField(
        controller: _ctrl, keyboardType: TextInputType.number, autofocus: true,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink),
        decoration: InputDecoration(
          labelText: 'Số tiền (VNĐ)',
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixText: 'đ',
          suffixStyle: const TextStyle(fontWeight: FontWeight.w900, color: _primary),
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 52, child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _gradPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            final v = int.tryParse(_ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            widget.onSave(v);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Lưu chi tiêu',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      )),
    ]),
  );
}

// ─── Bill Scan Card ───────────────────────────────────────────────────────────
class _BillScanCard extends StatelessWidget {
  const _BillScanCard();

  void _onTap(BuildContext context) {
    // Chưa có tính năng scan thật → hướng dẫn user dùng tạm ô nhập chi tiêu
    // ở trên (nút `+` cạnh mỗi hạng mục). Tránh hiển thị "sắp ra mắt" gây
    // frustration cho user.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Tạm thời hãy dùng nút + ở từng hạng mục để nhập chi tiêu.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _gradPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Phân tích & Scan Bill',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              SizedBox(height: 4),
              Text('Chụp/Tải hóa đơn để AI cập nhật chi tiêu thực tế tự động.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45)),
            ],
          )),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text('Scan',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ]),
      ),
    ),
  );
}
