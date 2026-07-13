import 'package:flutter/material.dart';

class ComingSoonScreen extends StatefulWidget {
  final String title;

  const ComingSoonScreen({
    super.key,
    required this.title,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  @override
  Widget build(BuildContext context) {
    Widget contentWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title - Single Line
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            children: [
              TextSpan(
                text: 'Feature Under ',
                style: TextStyle(color: Color(0xFF0F172A)),
              ),
              TextSpan(
                text: 'Development',
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        
        // Description - Centered Align
        SizedBox(
          width: 500,
          child: Text(
            "Our team is actively building this feature to deliver a secure, reliable, and seamless experience. This functionality will be available in an upcoming release.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Button - Centered
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_rounded, size: 20),
          label: const Text(
            'Coming Soon',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Feature Badges - Single line description & more space
        Wrap(
          spacing: 48, // More space between them
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureBadge(
              icon: Icons.verified_user_rounded,
              title: 'Secure',
              subtitle: 'Built with enterprise grade security',
            ),
            _buildFeatureBadge(
              icon: Icons.speed_rounded,
              title: 'Reliable',
              subtitle: 'Optimized for performance',
            ),
            _buildFeatureBadge(
              icon: Icons.person_rounded,
              title: 'User Focused',
              subtitle: 'Designed for a better user experience',
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: contentWidget,
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({required IconData icon, required String title, required String subtitle}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
