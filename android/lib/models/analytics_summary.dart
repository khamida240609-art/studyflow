class AnalyticsSummary {
  const AnalyticsSummary({
    required this.lostCount,
    required this.foundCount,
    required this.returnedCount,
    required this.activeCount,
    required this.priorityDocumentCount,
    required this.rewardedCount,
  });

  final int lostCount;
  final int foundCount;
  final int returnedCount;
  final int activeCount;
  final int priorityDocumentCount;
  final int rewardedCount;
}
