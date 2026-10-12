import 'package:equatable/equatable.dart';
import 'package:flutter_laundry_offline_app/data/models/order.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final Map<OrderStatus, int> todayStatusCounts;
  final int todayRevenue;
  final int monthOrderCount;
  final List<Order> recentOrders;
  final List<Order> overdueOrders;

  const DashboardLoaded({
    required this.todayStatusCounts,
    required this.todayRevenue,
    required this.monthOrderCount,
    required this.recentOrders,
    this.overdueOrders = const [],
  });

  @override
  List<Object?> get props => [
        todayStatusCounts,
        todayRevenue,
        monthOrderCount,
        recentOrders,
        overdueOrders,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
