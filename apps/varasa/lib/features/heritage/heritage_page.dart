import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/heritage_chrome.dart';
import 'cultural_data.dart';

class HeritagePage extends StatefulWidget {
  const HeritagePage({super.key});
  @override
  State<HeritagePage> createState() => _HeritagePageState();
}

class _HeritagePageState extends State<HeritagePage> {
  String _query = '';
  Map<String, dynamic>? _category;
  @override
  Widget build(BuildContext context) {
    final results = categories
        .expand((c) => (c['items'] as List).cast<Map<String, dynamic>>())
        .where(
          (item) => '${item['title']} ${item['description']}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return PopScope(
      canPop: _category == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _category != null) setState(() => _category = null);
      },
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            if (_category == null) ...[
              TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  labelText: 'Explore the collection',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 24),
              if (_query.isEmpty)
                ...categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _CategoryBanner(
                      category: c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
                )
              else ...[
                if (results.isEmpty)
                  const EmptyState(
                    title: 'Keep exploring',
                    message: 'Try an art form, festival, game or region.',
                  ),
                ...results.map((item) => _HeritageTile(item: item)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Original Varasa collection · Sources and regional traditions are being reviewed.',
                style: TextStyle(fontSize: 12),
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _category = null),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('All heritage'),
                ),
              ),
              _CategoryBanner(category: _category!),
              const Divider(height: 40),
              ...(_category!['items'] as List).cast<Map<String, dynamic>>().map(
                (item) => _HeritageTile(item: item),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category, this.onTap});
  final Map<String, dynamic> category;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE0BFA8),
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                (category['title'] as String).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              height: 100,
              child: HeritageImage(
                category['image'] as String,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeritageTile extends StatelessWidget {
  const _HeritageTile({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => HeritageDetailPage(item: item),
          ),
        ),
        child: SizedBox(
          height: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HeritageImage(item['image'] as String),
              const ColoredBox(color: Color(0xC7FFFFFF)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'CinzelDecorative',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF281B14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HeritageDetailPage extends StatelessWidget {
  const HeritageDetailPage({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const HeritageHeader(back: true),
          Expanded(
            child: ContentWidth(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: HeritageImage(item['image'] as String, height: 260),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item['title'] as String,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    item['description'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'From the original Varasa collection. Regional names and ways of practising may differ.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
