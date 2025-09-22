import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;
  final Widget? emptyWidget;
  final bool isLoading;
  final Widget? separatorBuilder;
  final ScrollPhysics? physics;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onRefresh,
    this.padding = const EdgeInsets.all(16),
    this.emptyWidget,
    this.isLoading = false,
    this.separatorBuilder,
    this.physics,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user scrolls within 200 pixels of the bottom
      if (widget.hasMore && !widget.isLoadingMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return RefreshIndicator(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: widget.emptyWidget,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          return widget.separatorBuilder ?? const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            // Loading indicator at the bottom
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.isLoadingMore
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }
}
