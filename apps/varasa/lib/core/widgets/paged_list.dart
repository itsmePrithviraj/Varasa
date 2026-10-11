import 'package:flutter/material.dart';
import '../../domain/models.dart';
import 'common.dart';

class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.load,
    required this.itemBuilder,
    required this.itemId,
    this.header,
    this.headerBuilder,
    this.columns = 1,
    this.showRefresh = true,
    this.padding = const EdgeInsets.all(20),
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'New contributions will appear here.',
  });
  final Future<CursorPage<T>> Function(String? cursor) load;
  final Widget Function(BuildContext, T) itemBuilder;
  final String Function(T) itemId;
  final Widget? header;
  final Widget Function(int loaded, bool hasMore, bool busy)? headerBuilder;
  final int columns;
  final bool showRefresh;
  final EdgeInsets padding;
  final String emptyTitle, emptyMessage;
  @override
  State<PagedList<T>> createState() => PagedListState<T>();
}

class PagedListState<T> extends State<PagedList<T>> {
  final _items = <T>[];
  String? _cursor;
  Object? _error;
  bool _busy = false, _started = false, _hasMore = true;
  int _generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      refresh();
    }
  }

  Future<void> refresh() => _fetch(reset: true);
  Future<void> _fetch({bool reset = false}) async {
    if (_busy && !reset) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
        _hasMore = true;
      }
    });
    try {
      final page = await widget.load(_cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        final ids = _items.map(widget.itemId).toSet();
        _items.addAll(page.items.where((item) => ids.add(widget.itemId(item))));
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: refresh,
    child: ListView.builder(
      padding: widget.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: (_items.length / widget.columns).ceil() + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showRefresh)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Refresh list',
                    onPressed: _busy ? null : refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              if (widget.header != null) widget.header!,
              if (widget.headerBuilder != null)
                widget.headerBuilder!(_items.length, _hasMore, _busy),
            ],
          );
        }
        if (index <= (_items.length / widget.columns).ceil()) {
          if (widget.columns == 1) {
            return widget.itemBuilder(context, _items[index - 1]);
          }
          final start = (index - 1) * widget.columns;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < widget.columns; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  Expanded(
                    child: start + col < _items.length
                        ? widget.itemBuilder(context, _items[start + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              if (_busy)
                const CircularProgressIndicator()
              else if (_error != null)
                EmptyState(
                  title: 'Couldn’t load this page',
                  message: errorMessage(_error!),
                  action: OutlinedButton(
                    onPressed: () => _fetch(),
                    child: const Text('Retry'),
                  ),
                )
              else ...[
                if (_items.isEmpty)
                  EmptyState(
                    title: widget.emptyTitle,
                    message: widget.emptyMessage,
                  ),
                if (_hasMore)
                  OutlinedButton(
                    onPressed: () => _fetch(),
                    child: const Text('Load more'),
                  )
                else if (_items.isNotEmpty)
                  const Text(
                    'You’ve reached the end. Use Refresh to check for updates.',
                  ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
