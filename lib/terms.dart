// terms.dart
// AgroSmart Terms & Conditions page without top image and continue button.

import 'dart:ui';
import 'package:flutter/material.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({Key? key}) : super(key: key);

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final double start = 0.1 * index;
    final double end = start + 0.4;

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = const [
      _TermPoint(
        title: 'Purpose',
        content:
            'AgroSmart connects verified buyers and sellers, enabling secure and trustworthy agricultural equipment transactions nationwide.',
      ),
      _TermPoint(
        title: 'Scope',
        content:
            'The platform only introduces parties; all inspections, negotiations, and finalization are handled independently by users.',
      ),
      _TermPoint(
        title: 'Inspection',
        content:
            'Never purchase unseen equipment. Always arrange physical inspections or third-party evaluations before making any commitment.',
      ),
      _TermPoint(
        title: 'Documentation',
        content:
            'Confirm ownership, service history, and legal clearance. Keep copies of all documents before finalizing transactions.',
      ),
      _TermPoint(
        title: 'Liability',
        content:
            'AgroSmart provides listing and introductions only. We do not guarantee equipment condition or assume responsibility.',
      ),
      _TermPoint(
        title: 'Safety',
        content:
            'During demonstrations, prioritize safety. Use protective equipment and avoid risky attempts at all times.',
      ),
      _TermPoint(
        title: 'Anti-Scam',
        content:
            'Stay alert against fraud. Verify identities, use documented payments, and immediately report suspicious activity.',
      ),
      _TermPoint(
        title: 'Acceptance',
        content:
            'By using AgroSmart, you accept these terms and commit to honesty, transparency, and responsibility.',
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.lightGreenAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 55, 86, 118),
              Color.fromARGB(255, 9, 14, 19),
              Color(0xFF000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 680, // Fixed height
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 12,
                        offset: const Offset(2, 6),
                      ),
                    ],
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < points.length; i++)
                            _buildAnimatedItem(points[i], i),
                          const SizedBox(height: 20),
                          _buildAnimatedItem(
                            const _ClosingNote(),
                            points.length,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermPoint extends StatelessWidget {
  final String title;
  final String content;
  const _TermPoint({Key? key, required this.title, required this.content})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.greenAccent.withOpacity(0.9),
            child: Text(
              title[0],
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingNote extends StatelessWidget {
  const _ClosingNote({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Important:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.lightGreenAccent,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'These terms encourage safe and transparent transactions. Always exercise independent judgment and due diligence.',
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
        ),
      ],
    );
  }
}
