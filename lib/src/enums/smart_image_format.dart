/// Supported image formats detected by SmartImage.
enum SmartImageFormat {
  /// Portable Network Graphics (raster).
  png,

  /// JPEG format (raster).
  jpeg,

  /// WebP format (raster, static or animated).
  webp,

  /// Graphics Interchange Format (raster, animated or static).
  gif,

  /// Bitmap image format (raster).
  bmp,

  /// Scalable Vector Graphics (vector, XML-based).
  svg,

  /// Format could not be conclusively determined.
  unknown;

  /// Returns true if this format is a vector format (e.g. SVG).
  bool get isVector => this == SmartImageFormat.svg;

  /// Returns true if this format is an animated raster format.
  bool get isAnimated =>
      this == SmartImageFormat.gif || this == SmartImageFormat.webp;
}
