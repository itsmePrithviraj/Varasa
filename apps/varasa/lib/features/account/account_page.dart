import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paged_list.dart';
import '../../domain/models.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  String? _message;
  Stream<List<AccountJob>>? _jobs;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jobs ??= RepositoryScope.of(context).watchJobs();
  }

  Future<void> _request(bool deleting) async {
    final repo = RepositoryScope.of(context);
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deleting ? 'Delete your account?' : 'Export your account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                deleting
                    ? 'This permanently removes your profile, stories and relationships. You will be signed out while deletion runs. Export anything you want to keep first.'
                    : 'Your profile, contributions and relationships will be prepared as JSON files. Download each part within seven days.',
              ),
              const SizedBox(height: 16),
              if (repo.requiresPassword)
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Confirm your password',
                  ),
                )
              else
                Text(
                  repo.isDemo
                      ? 'This affects this local demo session only.'
                      : 'Continue to confirm your Google account.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(deleting ? 'Delete account' : 'Prepare export'),
          ),
        ],
      ),
    );
    final secret = password.text;
    // Keep the controller alive until the dialog exit animation has finished.
    Future<void>.delayed(const Duration(seconds: 1), password.dispose);
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await repo.reauthenticate(secret);
      if (deleting) {
        await repo.requestDeletion();
      } else {
        await repo.requestExport();
        if (mounted) {
          setState(
            () => _message = 'Export requested. Its progress appears below.',
          );
        }
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your account & data')),
    body: SafeArea(
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Your contributions, in your hands',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Export includes your own records and references to uploaded files. Download attachments separately before deleting your account. Reports may be retained with identifying fields removed for moderation.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _request(false),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export my data'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _request(true),
                  child: const Text('Delete my account'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_message!),
              ),
            const SizedBox(height: 24),
            Text(
              'Data requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            StreamBuilder<List<AccountJob>>(
              key: const ValueKey('account-jobs'),
              stream: _jobs,
              builder: (context, snapshot) => AsyncState(
                snapshot: snapshot,
                builder: (jobs) => Column(
                  children: [
                    if (jobs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No data requests yet.'),
                      ),
                    ...jobs.map(
                      (job) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          job.type == 'export'
                              ? 'Account export'
                              : 'Account deletion',
                        ),
                        subtitle: Text('${job.status} · ${job.section}'),
                        trailing:
                            job.status == 'complete' && job.type == 'export'
                            ? TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ExportPartsPage(jobId: job.id),
                                  ),
                                ),
                                child: const Text('Files'),
                              )
                            : job.status == 'failed' && job.type == 'export'
                            ? TextButton(
                                onPressed: () async {
                                  try {
                                    await RepositoryScope.of(
                                      context,
                                    ).retryJob(job.id);
                                  } catch (e) {
                                    if (context.mounted) showError(context, e);
                                  }
                                },
                                child: const Text('Retry'),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExportPartsPage extends StatelessWidget {
  const ExportPartsPage({super.key, required this.jobId});
  final String jobId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Export files')),
    body: ContentWidth(
      child: PagedList<Map<String, dynamic>>(
        header: const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'Download every part to keep a complete copy. These files contain personal data; store them somewhere private. Files expire after seven days.',
          ),
        ),
        load: (cursor) =>
            RepositoryScope.of(context).fetchExportParts(jobId, cursor: cursor),
        itemId: (item) => item['id'] as String,
        itemBuilder: (context, item) => ListTile(
          title: Text(item['name'] as String? ?? item['id'] as String),
          subtitle: Text(item['section'] as String? ?? 'JSON data'),
          trailing: ExportDownloadButton(
            path: item['path'] as String,
            partId: item['id'] as String,
          ),
        ),
        emptyTitle: 'No files available',
        emptyMessage:
            'This export may have expired. Request a new export from your account.',
      ),
    ),
  );
}

class ExportDownloadButton extends StatefulWidget {
  const ExportDownloadButton({
    super.key,
    required this.path,
    required this.partId,
  });
  final String path, partId;
  @override
  State<ExportDownloadButton> createState() => _ExportDownloadButtonState();
}

class _ExportDownloadButtonState extends State<ExportDownloadButton> {
  bool _busy = false;
  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final bytes = await RepositoryScope.of(
        context,
      ).readExportPart(widget.path);
      if (!mounted) return;
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save export part',
        fileName: 'varasa-${widget.partId}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _busy ? 'Preparing download' : 'Download this part',
    onPressed: _busy ? null : _download,
    icon: _busy
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download),
  );
}
