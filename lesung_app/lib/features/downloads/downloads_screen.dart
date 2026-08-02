import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/download_card.dart';
import '../../components/section_title.dart';
import '../../l10n/generated/app_localizations.dart';

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
    downloads?.onChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    ref.read(engineProvider).downloads?.onChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(engineProvider);
    final downloads = engine.downloads;
    final l10n = AppLocalizations.of(context)!;

    if (downloads == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.downloadsTitle)),
        body: AppEmptyState.noDownloads(context: context),
      );
    }

    final active = downloads.active;

    final failed = downloads.failed;
    final completed = downloads.completed;

    final empty =
        active.isEmpty && failed.isEmpty && completed.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: empty
          ? AppEmptyState.noDownloads(context: context)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (active.isNotEmpty) ...[
                  SectionTitle(title: l10n.downloadsActive),
                  for (final task in active)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16),
                      child: _cardFor(task, engine),
                    ),
                ],
                if (failed.isNotEmpty) ...[
                  SectionTitle(title: l10n.downloadsFailed),
                  for (final task in failed)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16),
                      child: _cardFor(task, engine),
                    ),
                ],
                if (completed.isNotEmpty) ...[
                  SectionTitle(title: l10n.downloadsCompleted),
                  for (final task in completed)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 16),
                      child: _cardFor(task, engine),
                    ),
                ],
                const SizedBox(height: 48),
              ],
            ),
    );
  }

  Widget _cardFor(DownloadTask task, Engine engine) {
    final downloads = engine.downloads!;
    final downloadManager = engine.downloadManager!;
    final progress =
        downloads.progressFor(task.id)?.progress ?? task.progress;
    final status = task.status;
    final speed = downloads.progressFor(task.id);

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
                filePath: downloadManager.storage.finalFileFor(task).path,
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
        onRetry: () => downloadManager.retry(task.id),
        onCancel: () => downloadManager.remove(task.id),
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
      onPause: paused ? null : () => downloadManager.pause(task.id),
      onResume: paused ? () => downloadManager.resume(task.id) : null,
      onCancel: () => downloadManager.cancel(task.id),
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
