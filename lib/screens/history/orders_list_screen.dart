import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../providers.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  late Future<List<Order>> _future;
  int _refresh = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(orderRepositoryProvider).loadAll();
  }

  Future<void> _refreshList() async {
    setState(() {
      _refresh++;
      _reload();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('history'))),
      body: FutureBuilder<List<Order>>(
        key: ValueKey(_refresh),
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data ?? const <Order>[];
          if (orders.isEmpty) {
            return Center(
              child: Text(l.t('noOrders'),
                  style: const TextStyle(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            onRefresh: _refreshList,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 14, top: 6),
                    child: Center(child: BrandLogo(scale: 0.85)),
                  );
                }
                final o = orders[i - 1];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.music_note, color: AppColors.gold),
                    title: Text(o.clientName),
                    subtitle: Text(
                      '${l.t(o.occasion.l10nKey)} • ${DateFormat.yMMMd(l.lang).format(o.createdAt)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(l.t(o.status.l10nKey),
                          style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                    ),
                    onTap: () => context.go('/orders/${o.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
