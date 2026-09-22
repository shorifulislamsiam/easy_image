/// Loading animation styles supported by [SmartImage].
enum SmartImageLoadingType {
  /// No special animated loading style; shows standard placeholder.
  none,

  /// Displays an indeterminate or progress-based indicator.
  progress,

  /// Displays a smooth animated shimmer placeholder.
  shimmer,

  /// Fades the placeholder while loading.
  fade,

  /// Blur-up progressive loading (low-res preview or BlurHash).
  blurUp,
}
