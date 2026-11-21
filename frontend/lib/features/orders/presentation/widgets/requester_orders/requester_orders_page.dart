import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/order_models.dart';
import 'requester_orders_header.dart';
import 'requester_orders_results.dart';

class RequesterOrdersPage extends StatefulWidget {
  const RequesterOrdersPage({
    super.key,
    required this.onlyOpen,
    required this.rows,
    required this.onRefresh,
    required this.onFilter,
  });
  final bool onlyOpen;
  final AsyncValue<List<Order>> rows;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onFilter;

  @override
  State<RequesterOrdersPage> createState() => _RequesterOrdersPageState();
}

class _RequesterOrdersPageState extends State<RequesterOrdersPage> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) _search.clear();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverToBoxAdapter(
            child: RequesterOrdersHeader(
              onlyOpen: widget.onlyOpen,
              onFilter: widget.onFilter,
              searching: _searching,
              onSearch: _toggleSearch,
              search: _search,
              onQuery: (_) => setState(() {}),
            ),
          ),
        ],
        body: RequesterOrdersResults(
          rows: widget.rows,
          onlyOpen: widget.onlyOpen,
          query: _search.text,
          onRefresh: widget.onRefresh,
          onClear: () => setState(_search.clear),
        ),
      ),
    ),
  );
}
