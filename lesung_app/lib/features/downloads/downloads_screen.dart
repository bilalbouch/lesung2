import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/download_card.dart';
import '../../components/section_title.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Téléchargements — actifs en haut (progression temps réel),
/// terminés et échoués en dessous.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    final downloads = ref.read(engineProvider).downloads;
    downloads.onChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    ref.read(engineProvider).downloads.onChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(engineProvider);
    final downloads = engine.downloads;

    final active = downloads.active;
    final failed = downloads.failed;
    final completed = downloads.completed;

    final empty =
        active.isEmpty && failed.isEmpty && completed.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: empty
          ? AppEmptyState.noDownloads()
          : ListView(
              padding: AppSpacing.screen,
              children: [
                if (active.isNotEmpty) ...[
                  const SectionTitle(title: 'Aktiv'),
                  for (final task in active)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _cardFor(task, engine),
                    ),
                ],
                if (failed.isNotEmpty) ...[
                  const SectionTitle(title: 'Fehlgeschlagen'),
                  for (final task in failed)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _cardFor(task, engine),
                    ),
                ],
                if (completed.isNotEmpty) ...[
                  const SectionTitle(title: 'Abgeschlossen'),
                  for (final task in completed)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.m),
                      child: _cardFor(task, engine),
                    ),
                ],
                AppSpacing.gapXxl,
              ],
            ),
    );
  }

  Widget _cardFor(DownloadTask task, Engine engine) {
    final progress =
        engine.downloads.progressFor(task.id)?.progress ?? task.progress;
    final status = task.status;
    final speed = engine.downloads.progressFor(task.id);

    if (status == DownloadStatus.completed) {
      return DownloadCard(
        title: task.title,
        author: task.author,
        coverUrl: task.coverUrl,
        state: DownloadCardState.completed,
        progress: 1,
        onOpen: () => context.push(AppRoutes.reader,
            extra: ReaderBookArgs(
                bookId: task.id,
                filePath:
                    engine.downloadManager.storage.finalFileFor(task).path,
                title: task.title)),
      );
    }
    if (status == DownloadStatus.failed) {
      return DownloadCard(
        title: task.title,
        author: task.author,
        coverUrl: task.coverUrl,
        state: DownloadCardState.failed,
        progress: progress,
        subtitle: task.errorMessage,
        onRetry: () => engine.downloadManager.retry(task.id),
        onCancel: () => engine.downloadManager.remove(task.id),
      );
    }
    final paused = status == DownloadStatus.paused;
    return DownloadCard(
      title: task.title,
      author: task.author,
      coverUrl: task.coverUrl,
      state: paused ? DownloadCardState.paused : DownloadCardState.active,
      progress: progress,
      subtitle: _subtitle(task, progress, speed),
      onPause: paused ? null : () => engine.downloadManager.pause(task.id),
      onResume: paused ? () => engine.downloadManager.resume(task.id) : null,
      onCancel: () => engine.downloadManager.cancel(task.id),
    );
  }

  String _subtitle(DownloadTask task, double progress, DownloadProgress? downloadProgress) {
    final percent = '${(progress * 100).toStringAsFixed(0)} %';
    if (downloadProgress == null ||
        downloadProgress.speedBytesPerSec <= 0) {
      return percent;
    }
    final mb = (downloadProgress.speedBytesPerSec / (1 << 20))
        .toStringAsFixed(1);
    final eta = downloadProgress.eta;
    final etaText = eta == null
        ? ''
        : ' · noch ${eta.inMinutes > 0 ? '${eta.inMinutes} min' : '${eta.inSeconds} s'}';
    return '$percent · $mb MB/s$etaText';
  }
}
