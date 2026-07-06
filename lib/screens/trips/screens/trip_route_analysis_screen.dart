// ignore_for_file: unnecessary_library_name

library trip_route_analysis_screen;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/budget_tier.dart';
import '../models/route_analysis.dart';
import '../services/trip_itinerary_service.dart';
import '../../../core/widgets/vietai_scope.dart';
import 'trip_itinerary_result_screen.dart';

part 'route_analysis/trip_route_analysis_map.dart';
part 'route_analysis/trip_route_analysis_layout.dart';
part 'route_analysis/trip_route_analysis_legs.dart';
part 'route_analysis/trip_route_analysis_picker.dart';
part 'route_analysis/trip_route_analysis_summary.dart';
part 'route_analysis/trip_route_analysis_common.dart';

class TripRouteAnalysisScreen extends StatefulWidget {
  const TripRouteAnalysisScreen({
    super.key,
    required this.analysis,
    required this.departureDate,
    required this.returnDate,
    required this.peopleCount,
    required this.budgetPerPerson,
    this.travelGroup,
    this.interests = const [],
    this.specialRequest,
  });

  final TripRouteAnalysis analysis;
  final DateTime departureDate;
  final DateTime returnDate;
  final int peopleCount;
  final double budgetPerPerson;
  final String? travelGroup;
  final List<String> interests;
  final String? specialRequest;

  @override
  State<TripRouteAnalysisScreen> createState() => _TripRouteAnalysisScreenState();
}

class _TripRouteAnalysisScreenState extends State<TripRouteAnalysisScreen> {
  bool _isGenerating = false;
  late TripRouteAnalysis _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
  }

  @override
  void didUpdateWidget(covariant TripRouteAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis != widget.analysis) {
      _analysis = widget.analysis;
    }
  }

  Future<void> _generateItinerary() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    final token = VietaiScope.of(context).auth?.accessToken;
    final service = TripItineraryService(authToken: token);
    try {
      final result = await service.generate(
        destinations: _analysis.destinations,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        peopleCount: widget.peopleCount,
        budgetPerPerson: widget.budgetPerPerson,
        departurePoint: _analysis.departure.name,
        travelGroup: widget.travelGroup,
        interests: widget.interests,
        specialRequest: widget.specialRequest,
        routeLegs: _analysis.legs,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripItineraryResultScreen(
            response: result.response,
            itinerary: result.itinerary,
            itineraryId: result.itineraryId,
          ),
        ),
      );
    } on TripItineraryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (error, stackTrace) {
      debugPrint('[RouteAnalysis] Could not generate itinerary: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      service.dispose();
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    final detailChildren = _detailChildren(analysis);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Khoảng cách & phương tiện'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            if (!wide) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _RouteTitle(analysis: analysis),
                  const SizedBox(height: 14),
                  _RouteMapCard(analysis: analysis),
                  const SizedBox(height: 14),
                  ...detailChildren,
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RouteTitle(analysis: analysis),
                        const SizedBox(height: 14),
                        Expanded(child: _RouteMapCard(analysis: analysis, fillHeight: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 460,
                    child: _DetailsRail(children: detailChildren),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _detailChildren(TripRouteAnalysis analysis) {
    return [
      _LegList(
        analysis: analysis,
        onChangeMode: _changeLegMode,
      ),
      const SizedBox(height: 14),
      _SummaryCard(
        analysis: analysis,
        budgetTotal: widget.budgetPerPerson,
        peopleCount: widget.peopleCount,
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateItinerary,
        icon: _isGenerating
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          _isGenerating ? 'ĐANG TẠO LỊCH TRÌNH...' : 'TẠO LỊCH TRÌNH',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0FA958),
          disabledBackgroundColor: Colors.grey.shade300,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ];
  }

  void _changeLegMode(RouteLeg leg, TransportOption option) {
    final updated = _analysis.legs.map((item) {
      if (item.order != leg.order) return item;
      return item.copyWith(
        recommendedMode: option.mode,
        reason: option.reason,
        durationHours: option.durationHours,
        estimatedCostVndOverride: option.estimatedCostVnd,
        transportOptions: item.transportOptions
            .map(
              (candidate) => candidate.copyWith(
                isRecommended: candidate.mode == option.mode,
              ),
            )
            .toList(),
      );
    }).toList();
    setState(() => _analysis = _analysis.copyWith(legs: updated));
  }
}

