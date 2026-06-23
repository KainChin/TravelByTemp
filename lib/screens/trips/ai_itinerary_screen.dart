import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/api_client.dart';

class AiItineraryScreen extends StatefulWidget {
  const AiItineraryScreen({super.key});

  @override
  State<AiItineraryScreen> createState() => _AiItineraryScreenState();
}

class _AiItineraryScreenState extends State<AiItineraryScreen> {
  var _generating = false;
  var _selectedDay = 1;
  var _extraDays = 0;

  final _sampleItems = const [
    _PlanItem('08:00', Icons.hotel_outlined, 'Check-in Hotel', 'TTC Hotel - Da Lat', 'Relax & take a break', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=300'),
    _PlanItem('10:00', Icons.camera_alt_outlined, 'Dalat Railway Station', 'Explore the historic train station', 'French-style landmark', 'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=300'),
    _PlanItem('12:30', Icons.restaurant_outlined, 'Lunch: Banh Can Le', 'Try local speciality', 'Warm street-food stop', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300'),
    _PlanItem('14:00', Icons.landscape_outlined, 'Tuyen Lam Lake', 'Peaceful lake & pine forest', 'Slow scenic afternoon', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=300'),
    _PlanItem('16:30', Icons.local_cafe_outlined, 'An Cafe', 'Enjoy coffee with a view', 'Garden cafe break', 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=300'),
    _PlanItem('19:00', Icons.dinner_dining_outlined, 'Dinner: Memory Restaurant', 'Cozy local fusion cuisine', 'End the day slowly', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300'),
  ];

  Future<void> _generateItinerary() async {
    final session = VietaiScope.of(context);
    final budgetCtrl = TextEditingController(text: '2000000');
    final daysCtrl = TextEditingController(text: '2');
    final prefCtrl = TextEditingController(text: 'nature, cool weather, food, photos');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate AI itinerary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Budget (VND)'),
            ),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Days'),
            ),
            TextField(
              controller: prefCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Preferences'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _generating = true);
    try {
      await session.generateItinerary(
        budget: double.tryParse(budgetCtrl.text) ?? 2000000,
        days: int.tryParse(daysCtrl.text) ?? 2,
        preferences: prefCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI itinerary generated')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      budgetCtrl.dispose();
      daysCtrl.dispose();
      prefCtrl.dispose();
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final result = session.lastAiResult;
    final items = _itemsFromResult(result);
    final totalDays = _totalDays(result);
    final title = result?.title ?? 'Create Itinerary';
    final subtitle = result == null
        ? 'Da Lat - 2 Days 1 Night'
        : '${result.recommendedDestinations.length} places - ${result.currentTemperature.toStringAsFixed(0)}C';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(title: title, subtitle: subtitle),
            _DaySelector(
              selectedDay: _selectedDay,
              totalDays: totalDays,
              onChanged: (day) => setState(() => _selectedDay = day),
              onAddDay: () {
                setState(() {
                  _extraDays += 1;
                  _selectedDay = totalDays + 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Day ${totalDays + 1} added')),
                );
              },
            ),
            const _ScenicBand(),
            _Timeline(items: items),
            _AddActivity(onTap: _generateItinerary, loading: _generating),
            _AiSuggestion(onTap: _generateItinerary, loading: _generating),
            _DaySummary(
              itemCount: items.length,
              day: _selectedDay,
              onEditBudget: _generateItinerary,
              onSave: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Day $_selectedDay saved')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  int _totalDays(AiRecommendResult? result) {
    final generatedDays = result == null || result.dailyPlan.isEmpty
        ? 2
        : result.dailyPlan.map((d) => d.day).reduce((a, b) => a > b ? a : b);
    return generatedDays + _extraDays;
  }

  List<_PlanItem> _itemsFromResult(AiRecommendResult? result) {
    if (result == null || result.dailyPlan.isEmpty) return _sampleItems;

    final day = result.dailyPlan.firstWhere(
      (d) => d.day == _selectedDay,
      orElse: () => result.dailyPlan.first,
    );

    if (day.items.isEmpty) return _sampleItems;

    return day.items.map((item) {
      return _PlanItem(
        item.time.isEmpty ? '--:--' : item.time,
        Icons.place_outlined,
        item.activity.isEmpty ? 'Explore destination' : item.activity,
        item.note ?? 'AI recommended activity',
        'Optimized for your route',
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=300',
      );
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        children: [
          _RoundButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.event_note_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.more_horiz,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Regenerate itinerary'),
                        onTap: () => Navigator.pop(ctx),
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: const Text('Share itinerary'),
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDay,
    required this.totalDays,
    required this.onChanged,
    required this.onAddDay,
  });

  final int selectedDay;
  final int totalDays;
  final ValueChanged<int> onChanged;
  final VoidCallback onAddDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var day = 1; day <= totalDays; day++) ...[
                    _DayCard(
                      day: day,
                      date: 'Day $day',
                      selected: selectedDay == day,
                      onTap: () => onChanged(day),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onAddDay,
            icon: const Icon(Icons.add),
            label: const Text('Add Day'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.date, required this.selected, required this.onTap});

  final int day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.cardBorder, width: selected ? 1.6 : 1),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 12)] : null,
        ),
        child: Column(
          children: [
            Text('Day $day', style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AppColors.primaryDark : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ScenicBand extends StatelessWidget {
  const _ScenicBand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Image.network(
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<_PlanItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineTile(item: items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item, required this.isLast});

  final _PlanItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 62,
              child: Column(
                children: [
                  Text(item.time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 1.5, color: AppColors.cardBorder)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                      child: Icon(item.icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 86,
                      child: NetworkImageCard(
                        imageUrl: item.image,
                        height: 64,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_indicator, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddActivity extends StatelessWidget {
  const _AddActivity({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
        label: Text(loading ? 'Generating...' : 'Add Activity'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _AiSuggestion extends StatelessWidget {
  const _AiSuggestion({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 18),
                    SizedBox(width: 6),
                    Text('AI Suggestion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Optimize your plan for better time and experience', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: loading ? null : onTap,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
            child: const Text('Optimize'),
          ),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.itemCount,
    required this.day,
    required this.onEditBudget,
    required this.onSave,
  });

  final int itemCount;
  final int day;
  final VoidCallback onEditBudget;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Day $day Summary', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              TextButton(onPressed: onEditBudget, child: const Text('Edit Budget')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryMetric(label: 'Est. Cost', value: '1,250,000'),
              _SummaryMetric(label: 'Distance', value: '45 km'),
              _SummaryMetric(label: 'Activities', value: '$itemCount'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              minHeight: 8,
              value: 0.72,
              backgroundColor: Color(0xFFECECEC),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Save Day $day'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(width: 50, height: 50, child: Icon(icon)),
      ),
    );
  }
}

class _PlanItem {
  const _PlanItem(this.time, this.icon, this.title, this.subtitle, this.note, this.image);

  final String time;
  final IconData icon;
  final String title;
  final String subtitle;
  final String note;
  final String image;
}
