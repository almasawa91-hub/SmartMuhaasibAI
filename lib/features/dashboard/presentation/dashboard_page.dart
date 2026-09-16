import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/stat_card.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repository = DashboardRepository();
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadSummary();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.loadSummary());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    const currency = 'YER'; // TODO(phase-6): يُقرأ من إعدادات المنشأة الفعلية.

    return RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DashboardSummary>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error.toString(), onRetry: _refresh);
            }
            final s = snapshot.data ?? DashboardSummary.empty;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _SectionTitle('العملاء والموردون'),
                _grid([
                  StatCard(label: 'إجمالي العملاء', value: AppFormatters.number(s.totalCustomers), icon: Icons.people),
                  StatCard(label: 'إجمالي الموردين', value: AppFormatters.number(s.totalSuppliers), icon: Icons.local_shipping),
                  StatCard(
                    label: 'مستحق على العملاء',
                    value: AppFormatters.currency(s.totalReceivable, currency),
                    icon: Icons.arrow_downward,
                    color: s.totalReceivable > 0 ? Colors.orange.shade700 : null,
                  ),
                  StatCard(
                    label: 'مستحق للموردين',
                    value: AppFormatters.currency(s.totalPayable, currency),
                    icon: Icons.arrow_upward,
                    color: s.totalPayable > 0 ? Colors.red.shade700 : null,
                  ),
                ]),
                _SectionTitle('حركة اليوم المالية'),
                _grid([
                  StatCard(label: 'المقبوضات اليوم', value: AppFormatters.currency(s.paymentsInToday, currency), icon: Icons.download, color: Colors.green.shade700),
                  StatCard(label: 'المدفوعات اليوم', value: AppFormatters.currency(s.paymentsOutToday, currency), icon: Icons.upload, color: Colors.red.shade700),
                  StatCard(label: 'المصروفات اليوم', value: AppFormatters.currency(s.expensesToday, currency), icon: Icons.money_off),
                  StatCard(label: 'الإيرادات اليوم', value: AppFormatters.currency(s.revenuesToday, currency), icon: Icons.attach_money),
                ]),
                _SectionTitle('المخزون'),
                _grid([
                  StatCard(label: 'قيمة المخزون', value: AppFormatters.currency(s.inventoryValue, currency), icon: Icons.inventory_2),
                  StatCard(
                    label: 'منخفض المخزون',
                    value: AppFormatters.number(s.lowStockCount),
                    icon: Icons.warning_amber,
                    color: s.lowStockCount > 0 ? Colors.amber.shade800 : null,
                  ),
                  StatCard(
                    label: 'نفد من المخزون',
                    value: AppFormatters.number(s.outOfStockCount),
                    icon: Icons.remove_shopping_cart,
                    color: s.outOfStockCount > 0 ? Colors.red.shade700 : null,
                  ),
                ]),
                _SectionTitle('المواعيد والتذكيرات'),
                _grid([
                  StatCard(label: 'مواعيد اليوم', value: AppFormatters.number(s.appointmentsToday), icon: Icons.event),
                  StatCard(
                    label: 'المتأخرون',
                    value: AppFormatters.number(s.overdueCount),
                    icon: Icons.report,
                    color: s.overdueCount > 0 ? Colors.red.shade700 : null,
                  ),
                  StatCard(label: 'تذكيرات قادمة', value: AppFormatters.number(s.upcomingReminders), icon: Icons.notifications_active),
                  StatCard(label: 'وعود سداد قريبة', value: AppFormatters.number(s.promisesDueSoon), icon: Icons.schedule),
                  StatCard(
                    label: 'وعود متأخرة',
                    value: AppFormatters.number(s.promisesOverdue),
                    icon: Icons.error_outline,
                    color: s.promisesOverdue > 0 ? Colors.red.shade700 : null,
                  ),
                ]),
              ],
            );
          },
        ),
    );
  }

  Widget _grid(List<Widget> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: cards,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('حدث خطأ أثناء تحميل البيانات', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
