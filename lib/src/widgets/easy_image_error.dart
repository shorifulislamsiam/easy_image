import 'package:flutter/material.dart';
import '../errors/easy_image_exception.dart';

/// Clean default error widget with optional retry button.
class EasyImageError extends StatelessWidget {
  final EasyImageException? error;
  final Widget? customErrorWidget;
  final VoidCallback? onRetry;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const EasyImageError({
    super.key,
    this.error,
    this.customErrorWidget,
    this.onRetry,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (customErrorWidget != null) {
      return SizedBox(
        width: width,
        height: height,
        child: customErrorWidget!,
      );
    }

    final effectiveRadius = borderRadius ?? BorderRadius.circular(0);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        color: backgroundColor ?? Colors.grey.shade100,
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: (width != null && height != null)
                    ? (width! < 60 || height! < 60 ? 18 : 28)
                    : 28,
                color: Colors.grey.shade600,
              ),
              if (onRetry != null &&
                  (width == null || width! >= 70) &&
                  (height == null || height! >= 60)) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 2),
                          Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for [EasyImageError].
typedef SmartImageError = EasyImageError;
