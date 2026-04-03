import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TextEditingController _promptCtrl = TextEditingController();

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final sessions = context.watch<SessionProvider>().sessions;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Study Analytics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Personalized insights from your data.',
                style: TextStyle(color: AppTheme.secondary(context), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _promptCtrl,
              decoration: const InputDecoration(
                hintText: 'Write your question to AI...',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: analytics.loading
                  ? null
                  : () => analytics.ask(sessions, _promptCtrl.text),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Insights'),
            ),
            const SizedBox(height: 16),
            if (analytics.loading)
              const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            else if (analytics.insights.isEmpty)
              Text('No insights yet. Generate to see recommendations.',
                  style: TextStyle(color: AppTheme.secondary(context)))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: analytics.insights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _InsightCard(text: analytics.insights[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insights, color: AppTheme.accent2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
