import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    required this.kind,
    required this.targetId,
    this.postId,
  });
  final String kind, targetId;
  final String? postId;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _details = TextEditingController();
  String _reason = 'Spam';
  bool _busy = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report a concern')),
    body: ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Help keep Varasa welcoming. Reports are shared with moderators, not with the member you report.',
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [
              'Spam',
              'Harassment',
              'Privacy concern',
              'Misleading cultural information',
              'Other',
            ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: _busy ? null : (v) => setState(() => _reason = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _details,
            enabled: !_busy,
            maxLength: 1000,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Add context · Optional',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await RepositoryScope.of(context).reportContent(
                        kind: widget.kind,
                        targetId: widget.targetId,
                        postId: widget.postId,
                        reason: _reason,
                        details: _details.text,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Your report has been recorded for review.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: Text(_busy ? 'Sending…' : 'Submit report'),
          ),
        ],
      ),
    ),
  );
}
