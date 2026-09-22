import 'package:flutter/widgets.dart';
import 'file_image_io.dart'
    if (dart.library.js_interop) 'file_image_web.dart'
    if (dart.library.html) 'file_image_web.dart' as impl;

/// Creates a cross-platform [ImageProvider] for file paths.
ImageProvider getFileImageProvider(String path) =>
    impl.createFileImageProvider(path);
