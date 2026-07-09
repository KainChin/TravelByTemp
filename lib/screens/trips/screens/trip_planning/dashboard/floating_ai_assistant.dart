import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingAiAssistant extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingAiAssistant({super.key, required this.onTap});

  @override
  State<FloatingAiAssistant> createState() => _FloatingAiAssistantState();
}

class _FloatingAiAssistantState extends State<FloatingAiAssistant> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111), // Premium Black
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.4 : 0.2),
                blurRadius: _isHovering ? 24 : 12,
                offset: Offset(0, _isHovering ? 12 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms, curve: Curves.easeInOut),
              
              const SizedBox(width: 12),
              
              Text(
                'AI Assistant',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
