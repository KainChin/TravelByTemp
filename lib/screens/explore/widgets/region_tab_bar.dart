import 'package:flutter/material.dart';
import '../models/region_model.dart';

class RegionTabBar extends StatelessWidget {
  final RegionType selectedRegion;
  final ValueChanged<RegionType> onRegionChanged;

  const RegionTabBar({
    super.key,
    required this.selectedRegion,
    required this.onRegionChanged,
  });

  static const _tabs = [
    (type: RegionType.west, label: 'Miền Tây', sub: 'West'),
    (type: RegionType.north, label: 'Miền Bắc', sub: 'North'),
    (type: RegionType.central, label: 'Miền Trung', sub: 'Central'),
    (type: RegionType.south, label: 'Miền Nam', sub: 'South'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = selectedRegion == tab.type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRegionChanged(tab.type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF16A34A), width: 1.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      tab.sub,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
