import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_page_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('DownloadQueueRepository', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('stores a gallery manifest as a queued job with page records', () async {
      final comic = sampleComic(id: '700', mediaId: '77');

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Queued Comic',
      );

      final job = await harness.downloadQueueRepository.loadJob('700');
      final pages = await harness.downloadQueueRepository.loadPages('700');

      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.queued);
      expect(job.totalPages, comic.numPages);
      expect(pages, hasLength(comic.numPages));
      expect(pages.first.remotePath, 'galleries/77/1.jpg');
      expect(pages.first.status, DownloadPageStatus.pending);
    });

    test('requeue keeps completed pages and resets incomplete ones', () async {
      final comic = sampleComic(id: '701', mediaId: '88');
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Resume Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('701');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '701',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/1.webp',
        storedFormat: 'webp',
        byteSize: 123,
      );
      await harness.downloadQueueRepository.markPageFailed(
        comicId: '701',
        pageNumber: 2,
        error: 'network',
      );

      await harness.downloadQueueRepository.requeueJob('701');

      final job = await harness.downloadQueueRepository.loadJob('701');
      final pages = await harness.downloadQueueRepository.loadPages('701');

      expect(job!.status, DownloadJobStatus.queued);
      expect(job.completedPages, 1);
      expect(job.nextPageNumber, 2);
      expect(pages.first.status, DownloadPageStatus.completed);
      expect(pages.last.status, DownloadPageStatus.pending);
      expect(pages.last.localPath, isNull);
    });

    test('markPageCompleted preserves a paused job status', () async {
      final comic = sampleComic(id: '702', mediaId: '99');
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Paused Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('702');
      await harness.downloadQueueRepository.markJobPaused('702');

      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '702',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/1.webp',
        storedFormat: 'webp',
        byteSize: 123,
      );

      final job = await harness.downloadQueueRepository.loadJob('702');

      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.paused);
      expect(job.completedPages, 1);
      expect(job.nextPageNumber, 2);
      expect(job.completedAt, isNull);
    });

    test('markPageCompleted preserves a failed job status', () async {
      final comic = sampleComic(id: '703', mediaId: '100');
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Failed Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('703');
      await harness.downloadQueueRepository.markPageFailed(
        comicId: '703',
        pageNumber: 1,
        error: 'network',
      );

      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '703',
        pageNumber: 2,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/2.webp',
        storedFormat: 'webp',
        byteSize: 456,
      );

      final job = await harness.downloadQueueRepository.loadJob('703');

      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.failed);
      expect(job.completedPages, 1);
      expect(job.nextPageNumber, 1);
      expect(job.lastError, 'network');
      expect(job.completedAt, isNull);
    });

    test('pauseInterruptedJobs pauses only downloading jobs and preserves progress', () async {
      final downloadingComic = sampleComic(id: '704', mediaId: '101');
      final queuedComic = sampleComic(id: '705', mediaId: '102');
      final failedComic = sampleComic(id: '706', mediaId: '103');

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: downloadingComic,
        title: 'Downloading Comic',
      );
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: queuedComic,
        title: 'Queued Comic',
      );
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: failedComic,
        title: 'Failed Comic',
      );

      await harness.downloadQueueRepository.markJobDownloading('704');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '704',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/704-1.webp',
        storedFormat: 'webp',
        byteSize: 111,
      );
      await harness.downloadQueueRepository.markJobDownloading('706');
      await harness.downloadQueueRepository.markPageFailed(
        comicId: '706',
        pageNumber: 1,
        error: 'network',
      );

      await harness.downloadQueueRepository.pauseInterruptedJobs();

      final pausedJob = await harness.downloadQueueRepository.loadJob('704');
      final queuedJob = await harness.downloadQueueRepository.loadJob('705');
      final failedJob = await harness.downloadQueueRepository.loadJob('706');

      expect(pausedJob, isNotNull);
      expect(pausedJob!.status, DownloadJobStatus.paused);
      expect(pausedJob.completedPages, 1);
      expect(pausedJob.nextPageNumber, 2);

      expect(queuedJob, isNotNull);
      expect(queuedJob!.status, DownloadJobStatus.queued);

      expect(failedJob, isNotNull);
      expect(failedJob!.status, DownloadJobStatus.failed);
      expect(failedJob.lastError, 'network');
    });
  });
}
