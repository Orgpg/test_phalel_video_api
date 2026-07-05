import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/booking.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchLearnerBookings();
      context.read<BookingProvider>().fetchTeacherBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'As Learner'),
            Tab(text: 'As Teacher'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookingsList(role: 'learner'),
          _BookingsList(role: 'teacher'),
        ],
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final String role;
  const _BookingsList({required this.role});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final bookings = role == 'learner' ? provider.learnerBookings : provider.teacherBookings;

        if (provider.state == BookingState.loading && bookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No bookings found', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (role == 'learner') {
              await provider.fetchLearnerBookings();
            } else {
              await provider.fetchTeacherBookings();
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _BookingCard(booking: bookings[index], role: role);
            },
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final String role;
  const _BookingCard({required this.booking, required this.role});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.status.name,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(booking.scheduledFor),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.mentorListing?.title ?? 'Session',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              role == 'learner' 
                  ? 'Teacher: ${booking.teacher?.name}' 
                  : 'Learner: ${booking.learner?.name}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.coinPrice} Coins',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to details (not implemented yet)
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.CONFIRMED: return Colors.green;
      case BookingStatus.CANCELLED: return Colors.red;
      case BookingStatus.COMPLETED: return Colors.blue;
      case BookingStatus.PENDING: return Colors.orange;
    }
  }
}
