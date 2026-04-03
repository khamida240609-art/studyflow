class PostSaveResult {
  const PostSaveResult({
    required this.postId,
    required this.uploadAttemptCount,
    required this.uploadSuccessCount,
  });

  final String postId;
  final int uploadAttemptCount;
  final int uploadSuccessCount;

  bool get hasUploadIssues => uploadSuccessCount < uploadAttemptCount;

  int get failedUploadCount => uploadAttemptCount - uploadSuccessCount;
}
