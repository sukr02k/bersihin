import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_laundry_offline_app/core/constants/colors.dart';
import 'package:flutter_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:flutter_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:flutter_laundry_offline_app/data/models/customer.dart';
import 'package:flutter_laundry_offline_app/data/models/order.dart';
import 'package:flutter_laundry_offline_app/data/repositories/customer_repository.dart';
import 'package:flutter_laundry_offline_app/data/repositories/order_repository.dart';
import 'package:flutter_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:flutter_laundry_offline_app/logic/cubits/customer/customer_state.dart';
import 'package:flutter_laundry_offline_app/logic/cubits/order/order_cubit.dart';
import 'package:flutter_laundry_offline_app/presentation/screens/customers/customer_form_screen.dart';
import 'package:flutter_laundry_offline_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:flutter_laundry_offline_app/presentation/widgets/order_card.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  late Customer _customer;
  List<Order> _orders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    if (_customer.id == null) {
      setState(() => _isLoadingOrders = false);
      return;
    }

    setState(() => _isLoadingOrders = true);
    try {
      final updatedCustomer =
          await _customerRepository.getCustomerById(_customer.id!);
      final orders = await _orderRepository.getOrdersByCustomer(
        customerId: _customer.id!,
        phone: (updatedCustomer ?? _customer).phone,
      );

      if (mounted) {
        setState(() {
          if (updatedCustomer != null) {
            _customer = updatedCustomer;
          }
          _orders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  Customer get customer => _customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<CustomerCubit>(),
                    child: CustomerFormScreen(customer: customer),
                  ),
                ),
              );
              _loadCustomerData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: BlocListener<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess &&
              state.message.contains('dihapus')) {
            Navigator.pop(context);
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: _loadCustomerData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer header card
                _buildHeaderCard(context),
                const SizedBox(height: 16),

                // Statistics card
                _buildStatisticsCard(),
                const SizedBox(height: 16),

                // Contact info card
                _buildContactCard(),
                const SizedBox(height: 16),

                // Notes card (if exists)
                if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                  _buildNotesCard(),
                  const SizedBox(height: 16),
                ],

                // Order History section
                _buildOrderHistorySection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: customer.isLoyalCustomer
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              child: customer.isLoyalCustomer
                  ? const Icon(Icons.star, color: AppColors.warning, size: 36)
                  : Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Name and badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer.isLoyalCustomer)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PELANGGAN LOYAL',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Total Order',
                    value: '${customer.totalOrders}',
                    color: AppColors.info,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.payments_outlined,
                    label: 'Total Belanja',
                    value: CurrencyFormatter.format(customer.totalSpent),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bergabung',
                    value: customer.createdAt != null
                        ? DateFormatter.formatDate(customer.createdAt!)
                        : '-',
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.update_outlined,
                    label: 'Order Terakhir',
                    value: customer.lastOrderDate != null
                        ? DateFormatter.formatDate(customer.lastOrderDate!)
                        : 'Belum ada',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Kontak',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone_outlined,
              label: 'Nomor HP',
              value: customer.phone ?? '-',
            ),
            const Divider(height: 24),
            _buildContactItem(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: customer.address ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customer.notes!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Transaksi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_orders.length} transaksi',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingOrders)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_orders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat transaksi',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return OrderCard(
                order: order,
                onTap: () async {
                  if (order.id == null) return;
                  final customerCubit = context.read<CustomerCubit>();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => OrderCubit(),
                        child: OrderDetailScreen(orderId: order.id!),
                      ),
                    ),
                  );
                  await _loadCustomerData();
                  customerCubit.loadCustomers();
                },
              );
            },
          ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pelanggan "${customer.name}"?\n\nData pelanggan akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CustomerCubit>().deleteCustomer(customer.id!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
