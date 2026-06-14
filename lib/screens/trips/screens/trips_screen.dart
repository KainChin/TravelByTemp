import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_widgets.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();

  static const _defaultLocation = LatLng(10.7769, 106.7009); // HCM fallback

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Fit map bounds khi có route ───────────────────────────
  void _fitMapToBounds(TripProvider provider) {
    if (_mapController == null || provider.currentLocation == null || provider.destination == null) return;
    final dest = LatLng(provider.destination!.lat, provider.destination!.lng);
    final bounds = LatLngBounds(
      southwest: LatLng(
        provider.currentLocation!.latitude < dest.latitude ? provider.currentLocation!.latitude : dest.latitude,
        provider.currentLocation!.longitude < dest.longitude ? provider.currentLocation!.longitude : dest.longitude,
      ),
      northeast: LatLng(
        provider.currentLocation!.latitude > dest.latitude ? provider.currentLocation!.latitude : dest.latitude,
        provider.currentLocation!.longitude > dest.longitude ? provider.currentLocation!.longitude : dest.longitude,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, provider, _) {
        // Auto fit map khi có destination
        if (provider.destination != null && provider.polylinePoints.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToBounds(provider));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          body: SafeArea(
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  TripSearchBar(
                    controller: _searchController,
                    onChanged: (v) => provider.searchPlaces(v),
                    onClear: () {
                      _searchController.clear();
                      provider.clearDestination();
                    },
                  ),
                  // Suggestions dropdown
                  if (provider.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SuggestionList(
                      suggestions: provider.suggestions,
                      onSelect: (place) {
                        _searchController.text = place['name']!;
                        provider.selectDestination(place);
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  CurrentLocationRow(
                    locationText: provider.currentLocation != null
                        ? 'Ho Chi Minh City, Vietnam'
                        : 'Đang xác định vị trí...',
                    onChange: () => provider.getCurrentLocation(),
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              // ── Map ──
              _buildMap(provider),

              // ── Bottom content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                      )
                    else if (provider.destination != null) ...[
                      DestinationInfoCard(
                        name: provider.destination!.name,
                        address: provider.destination!.address,
                        duration: provider.destination!.durationText,
                        distance: provider.destination!.distanceText,
                        bestRoute: provider.destination!.bestRoute,
                        imagePath: '',
                      ),
                      const SizedBox(height: 12),
                      _buildConfirmButton(),
                      const SizedBox(height: 12),
                      const _OrDivider(),
                    ],
                    const SizedBox(height: 4),
                    const AiPlannerBanner(),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
      ),
      const SizedBox(width: 14),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Plan Your Trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Where do you want to go?', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
      ]),
    ]);
  }

  Widget _buildMap(TripProvider provider) {
    final initial = provider.currentLocation ?? _defaultLocation;
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initial, zoom: 12),
          markers: provider.markers,
          polylines: provider.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            if (provider.currentLocation != null) {
              controller.animateCamera(CameraUpdate.newLatLng(provider.currentLocation!));
            }
          },
        ),
        // Zoom buttons
        Positioned(
          right: 12, bottom: 12,
          child: Column(children: [
            _mapBtn(Icons.add, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
            const SizedBox(height: 4),
            _mapBtn(Icons.remove, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
            const SizedBox(height: 4),
            _mapBtn(Icons.near_me, () {
              if (provider.currentLocation != null) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(provider.currentLocation!));
              }
            }),
          ]),
        ),
        // Loading overlay
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))),
      ]),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {},
        child: const Text('Confirm Destination', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('Or let AI plan you ✨',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}