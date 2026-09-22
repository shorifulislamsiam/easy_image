import 'dart:io' as io;
import 'package:flutter/widgets.dart';

ImageProvider createFileImageProvider(String path) {
  return FileImage(io.File(path));
}
