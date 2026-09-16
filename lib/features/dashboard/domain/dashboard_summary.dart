class DashboardSummary {
  const DashboardSummary({
    required this.totalCustomers,
    required this.totalSuppliers,
    required this.totalReceivable,
    required this.totalPayable,
    required this.paymentsInToday,
    required this.paymentsOutToday,
    required this.expensesToday,
    required this.revenuesToday,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.appointmentsToday,
    required this.dueToday,
    required this.overdueCount,
    required this.upcomingReminders,
    required this.promisesDueSoon,
    required this.promisesOverdue,
  });

  final int totalCustomers;
  final int totalSuppliers;
  final double totalReceivable;
  final double totalPayable;
  final double paymentsInToday;
  final double paymentsOutToday;
  final double expensesToday;
  final double revenuesToday;
  final double inventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int appointmentsToday;
  final int dueToday;
  final int overdueCount;
  final int upcomingReminders;
  final int promisesDueSoon;
  final int promisesOverdue;

  static const empty = DashboardSummary(
    totalCustomers: 0,
    totalSuppliers: 0,
    totalReceivable: 0,
    totalPayable: 0,
    paymentsInToday: 0,
    paymentsOutToday: 0,
    expensesToday: 0,
    revenuesToday: 0,
    inventoryValue: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    appointmentsToday: 0,
    dueToday: 0,
    overdueCount: 0,
    upcomingReminders: 0,
    promisesDueSoon: 0,
    promisesOverdue: 0,
  );
}
