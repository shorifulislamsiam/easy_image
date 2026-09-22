import 'dart:async';
import '../errors/easy_image_exception.dart';

/// Item in the download queue.
class _QueueItem<T> {
  final Future<T> Function() task;
  final Completer<T> completer;
  final bool Function()? isCancelled;

  _QueueItem({
    required this.task,
    required this.completer,
    this.isCancelled,
  });
}

/// A concurrent task queue that limits simultaneous downloads to prevent network/thread saturation.
class ImageDownloadQueue {
  static final ImageDownloadQueue _sharedInstance = ImageDownloadQueue();

  /// Default shared queue instance.
  static ImageDownloadQueue get shared => _sharedInstance;

  final int maxConcurrent;
  int _activeCount = 0;
  final List<_QueueItem<dynamic>> _queue = [];

  ImageDownloadQueue({this.maxConcurrent = 6});

  /// The number of currently running download tasks.
  int get activeCount => _activeCount;

  /// The number of tasks waiting in line to be executed.
  int get queueLength => _queue.length;

  /// Enqueues a download task, running it when a concurrency slot is available.
  Future<T> enqueue<T>(
    Future<T> Function() task, {
    bool Function()? isCancelled,
  }) {
    if (isCancelled?.call() == true) {
      return Future.error(
        const EasyImageTimeoutException('Download cancelled before queueing.'),
      );
    }

    final completer = Completer<T>();
    final item = _QueueItem<T>(
      task: task,
      completer: completer,
      isCancelled: isCancelled,
    );

    _queue.add(item);
    _processNext();

    return completer.future;
  }

  void _processNext() {
    if (_activeCount >= maxConcurrent || _queue.isEmpty) {
      return;
    }

    final item = _queue.removeAt(0);

    if (item.isCancelled?.call() == true) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(
          const EasyImageTimeoutException('Download cancelled in queue.'),
        );
      }
      _processNext();
      return;
    }

    _activeCount++;

    item.task().then((result) {
      if (!item.completer.isCompleted) {
        item.completer.complete(result);
      }
    }).catchError((Object error, StackTrace st) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(error, st);
      }
    }).whenComplete(() {
      _activeCount--;
      _processNext();
    });

    // If more slots remain open, start another task immediately
    if (_activeCount < maxConcurrent && _queue.isNotEmpty) {
      _processNext();
    }
  }

  /// Clears all pending (queued but not yet running) tasks.
  void clearQueue() {
    for (final item in _queue) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(
          const EasyImageTimeoutException('Queue cleared.'),
        );
      }
    }
    _queue.clear();
  }
}
