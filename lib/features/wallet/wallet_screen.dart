import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/models/wallet.dart';
import 'topup_bottom_sheet.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<WalletProvider>().fetchTransactions();
      context.read<WalletProvider>().fetchTopupRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Transactions'), Tab(text: 'Topup Requests')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const TopupBottomSheet()),
        backgroundColor: Colors.deepPurple,
        label: const Text('Top Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.state == WalletState.loading && provider.wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildBalanceCard(provider.wallet),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsList(provider.transactions),
                    _buildTopupRequestsList(provider.topupRequests),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(Wallet? wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text('${wallet?.skillCoins ?? 0} Skill Coins', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Premium Coins: ${wallet?.premiumCoins ?? 0}', style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<CoinTransaction> transactions) {
    if (transactions.isEmpty) return const Center(child: Text('No transactions yet'));
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<WalletProvider>().fetchWallet();
        await context.read<WalletProvider>().fetchTransactions();
      },
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) => _buildTransactionItem(transactions[index]),
      ),
    );
  }

  Widget _buildTopupRequestsList(List<TopupRequest> requests) {
    if (requests.isEmpty) return const Center(child: Text('No topup requests yet'));
    return RefreshIndicator(
      onRefresh: () => context.read<WalletProvider>().fetchTopupRequests(),
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) => _buildTopupRequestItem(requests[index]),
      ),
    );
  }

  Widget _buildTransactionItem(CoinTransaction tx) {
    final bool isDebit = tx.amount < 0;
    final color = isDebit ? Colors.red : Colors.green;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(isDebit ? Icons.arrow_outward : Icons.arrow_downward, color: color)),
      title: Text(tx.note ?? tx.type.toString().split('.').last.replaceAll('_', ' ')),
      subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(tx.createdAt)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${isDebit ? "" : "+"}${tx.amount}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Bal: ${tx.balanceAfter}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTopupRequestItem(TopupRequest req) {
    Color statusColor;
    switch (req.status) {
      case TopupStatus.APPROVED: statusColor = Colors.green; break;
      case TopupStatus.REJECTED: statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.blue),
        title: Text('${req.requestedCoins} Coins'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${req.mmkAmount} MMK • ${DateFormat('MMM dd, yyyy').format(req.createdAt)}'),
            if (req.adminNote != null) Text('Note: ${req.adminNote}', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(req.status.toString().split('.').last, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
