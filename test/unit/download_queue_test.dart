import 'package:flutter_test/flutter_test.dart';
import 'package:easy_image/smart_image.dart';

void main() {
  group('ImageDownloadQueue Concurrency Limiter', () {
    test(
        'executes up to maxConcurrent tasks simultaneously and queues remainder',
        () async {
      final queue = ImageDownloadQueue(maxConcurrent: 2);

      int currentlyRunning = 0;
      int maxSimultaneousObserved = 0;
      final completed = <int>[];

      Future<void> runTask(int id, Duration duration) async {
        currentlyRunning++;
        if (currentlyRunning > maxSimultaneousObserved) {
          maxSimultaneousObserved = currentlyRunning;
        }

        await Future<void>.delayed(duration);
        currentlyRunning--;
        completed.add(id);
      }

      // Enqueue 4 tasks
      final f1 =
          queue.enqueue(() => runTask(1, const Duration(milliseconds: 30)));
      final f2 =
          queue.enqueue(() => runTask(2, const Duration(milliseconds: 30)));
      final f3 =
          queue.enqueue(() => runTask(3, const Duration(milliseconds: 10)));
      final f4 =
          queue.enqueue(() => runTask(4, const Duration(milliseconds: 10)));

      expect(queue.activeCount, 2);
      expect(queue.queueLength, 2);

      await Future.wait([f1, f2, f3, f4]);

      expect(maxSimultaneousObserved, 2);
      expect(completed.length, 4);
      expect(queue.activeCount, 0);
      expect(queue.queueLength, 0);
    });

    test('cancels queued tasks before execution', () async {
      final queue = ImageDownloadQueue(maxConcurrent: 1);

      bool isCancelled = false;

      final t1 = queue.enqueue(
          () => Future.delayed(const Duration(milliseconds: 30), () => 't1'));
      final t2 = queue.enqueue(
        () => Future.value('t2'),
        isCancelled: () => isCancelled,
      );

      // Cancel t2 while t1 is running
      isCancelled = true;

      expect(await t1, 't1');
      await expectLater(t2, throwsA(isA<SmartImageException>()));
    });
  });
}
