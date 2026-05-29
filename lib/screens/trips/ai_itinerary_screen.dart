import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/trips/map_view_screen.dart';
import 'package:assignment/services/api_client.dart';

class AiItineraryScreen extends StatefulWidget {
  const AiItineraryScreen({super.key});

  @override
  State<AiItineraryScreen> createState() => _AiItineraryScreenState();
}

class _AiItineraryScreenState extends State<AiItineraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var _generating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    final session = VietaiScope.of(context);
    final budgetCtrl = TextEditingController(text: '2000000');
    final daysCtrl = TextEditingController(text: '3');
    final prefCtrl = TextEditingController(text: 'thiên nhiên, mát mẻ, chụp ảnh');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo lịch trình AI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ngân sách (VND)')),
            TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số ngày')),
            TextField(controller: prefCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Sở thích')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _generating = true);
    try {
      await session.generateItinerary(
        budget: double.tryParse(budgetCtrl.text) ?? 2000000,
        days: int.tryParse(daysCtrl.text) ?? 3,
        preferences: prefCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo lịch trình từ Ollama + pgvector')),
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
    final isWide = MediaQuery.sizeOf(context).width > 700;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('AI Itinerary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Nhiệt độ ${session.userTemperatureC.toStringAsFixed(0)}°C tại ${session.locationName}\n'
                    'Gợi ý qua vector search + Ollama local',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _generating ? null : _generateItinerary,
                    icon: _generating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_generating ? 'Đang tạo...' : 'Tạo lịch trình AI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildTitle(result.title, result.summary),
            _buildSummaryBar(result, session),
            _buildTabs(),
            Expanded(
              child: isWide ? _buildWideLayout(result) : _buildMobileLayout(result),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GradientButton(
                    label: 'Tạo lại lịch trình',
                    icon: Icons.refresh,
                    onPressed: _generating ? null : _generateItinerary,
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'Save to My Itinerary',
                    gradient: AppColors.gradientSave,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Spacer(),
          _circleIcon(Icons.share_outlined),
          const SizedBox(width: 8),
          _circleIcon(Icons.favorite_border),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildTitle(String title, String summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Itinerary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Row(
              children: [
                Flexible(
                  child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(summary, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(AiRecommendResult result, dynamic session) {
    final items = [
      (Icons.schedule, '${result.dailyPlan.length} Days'),
      (Icons.place, '${result.recommendedDestinations.length} Places'),
      (Icons.thermostat, '${result.currentTemperature.toStringAsFixed(0)}°C'),
      (Icons.wb_sunny, result.currentWeatherDescription.length > 12
          ? '${result.currentWeatherDescription.substring(0, 12)}…'
          : result.currentWeatherDescription),
    ];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final (icon, label) = e.value;
          return Expanded(
            child: Row(
              children: [
                if (e.key > 0)
                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                Expanded(
                  child: Column(
                    children: [
                      Icon(icon, size: 18, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapViewScreen()),
            );
            _tabController.index = 0;
          }
        },
        tabs: const [
          Tab(text: 'Itinerary'),
          Tab(text: 'Map View'),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AiRecommendResult result) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _itineraryContent(result),
        const SizedBox(height: 16),
        _aiSidebar(result),
      ],
    );
  }

  Widget _buildWideLayout(AiRecommendResult result) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: SingleChildScrollView(child: _itineraryContent(result))),
        Expanded(flex: 2, child: SingleChildScrollView(child: _aiSidebar(result))),
      ],
    );
  }

  Widget _itineraryContent(AiRecommendResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final day in result.dailyPlan) ...[
            Text(
              'Day ${day.day}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            for (final item in day.items)
              _activityTile(
                item.time,
                Icons.place,
                item.activity,
                item.note ?? '',
                '',
              ),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < result.recommendedDestinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _destinationHeader(
                '${i + 1}',
                result.recommendedDestinations[i].name,
                result.recommendedDestinations[i].weatherFit,
                Icons.landscape,
              ),
            ),
        ],
      ),
    );
  }

  Widget _destinationHeader(String num, String name, String duration, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(width: 8),
        Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 20)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.copy, size: 20)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
      ],
    );
  }

  Widget _activityTile(String time, IconData icon, String title, String desc, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Icon(icon, size: 18, color: AppColors.primary),
                Expanded(
                  child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.cardBorder),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(price, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetworkImageCard(imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=200', height: 56, borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiSidebar(AiRecommendResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('AI Recommendations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(width: 4),
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Gợi ý từ AI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          for (final r in result.recommendedDestinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(r.reason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(r.weatherFit, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Choose'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Must-Try Foods', style: TextStyle(fontWeight: FontWeight.w600)),
          _foodRow('Bánh căn', '₫30K'),
          _foodRow('Lẩu gà lá é', '₫120K'),
          _foodRow('Kem bơ', '₫25K'),
          const SizedBox(height: 16),
          const Text('Budget Estimate', style: TextStyle(fontWeight: FontWeight.w600)),
          _budgetRow('Accommodation', '₫900,000'),
          _budgetRow('Food & Drinks', '₫350,000'),
          _budgetRow('Activities', '₫250,000'),
          const Divider(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₫1,500,000', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visit Langbiang early morning for the best views and fewer crowds.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ask AI Anything', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['What to eat in Đà Lạt?', 'Best photo spots?'].map((q) {
              return ActionChip(label: Text(q, style: const TextStyle(fontSize: 11)), onPressed: () {});
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ask me anything...',
              hintStyle: const TextStyle(fontSize: 13),
              suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: AppColors.primary)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight, child: Icon(Icons.restaurant, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(amount, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
