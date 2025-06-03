import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class LoanHistoryPage extends StatefulWidget {
  final String loanFilter;
  final String searchQuery;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const LoanHistoryPage({
    Key? key,
    required this.loanFilter,
    required this.searchQuery,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  @override
  _LoanManagementTabState createState() => _LoanManagementTabState();
}

class _LoanManagementTabState extends State<LoanHistoryPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Loan History'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildLoanFilterRow(context),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildLoanQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final loan = snapshot.data!.docs[index];
                      return LoanCard(
                        loanData: loan.data() as Map<String, dynamic>,
                        loanId: loan.id,
                        firestore: widget.firestore,
                        auth: widget.auth,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_bottom,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing Your Loan Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Please wait while we prepare your loan details. This may take a few minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No loans found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Query _buildLoanQuery() {
    try {
      // Get current user ID
      final userId = widget.auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Start with base query for current user
      Query query = widget.firestore
          .collection('loans')
          .where('userId', isEqualTo: userId);

      // Apply status filter if not 'all'
      if (widget.loanFilter != 'all') {
        query = query.where('status', isEqualTo: widget.loanFilter);
      }

      // Apply search filter if query exists
      if (widget.searchQuery.isNotEmpty) {
        query = query.where(
          'searchKeywords',
          arrayContains: widget.searchQuery.toLowerCase(),
        );
      }

      // Order by request date
      return query.orderBy('requestDate', descending: true);
    } catch (e) {
      debugPrint('Error building loan query: $e');
      // Return a simple query that will trigger the loading state
      return widget.firestore
          .collection('loans')
          .where('userId', isEqualTo: widget.auth.currentUser?.uid ?? '');
    }
  }

  Widget _buildLoanFilterRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Loans',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) => setState(() {}),
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'all', child: Text('All Loans')),
                const PopupMenuItem(value: 'pending', child: Text('Pending')),
                const PopupMenuItem(value: 'approved', child: Text('Approved')),
                const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                const PopupMenuItem(
                  value: 'disbursed',
                  child: Text('Disbursed'),
                ),
              ],
        ),
      ],
    );
  }
}

class LoanCard extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final String loanId;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const LoanCard({
    Key? key,
    required this.loanData,
    required this.loanId,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = loanData['status'] ?? 'pending';
    final requestDate = (loanData['requestDate'] as Timestamp?)?.toDate();
    final formattedDate = requestDate != null
        ? DateFormat('dd MMM yyyy').format(requestDate)
        : 'Unknown date';
    final startDate = (loanData['startDate'] as Timestamp?)?.toDate();
    final finishDate = (loanData['finishDate'] as Timestamp?)?.toDate();
    
    // Calculate loan details
    final amount = (loanData['amount'] ?? 0).toDouble();
    final termMonths = (loanData['termMonths'] ?? 1).toInt();
    final interestRate = (loanData['interestRate'] ?? 15.0).toDouble();
    final totalRepayment = amount * pow(1 + (interestRate / 100), termMonths);
    final monthlyRepayment = totalRepayment / termMonths;
    final paidAmount = (loanData['paidAmount'] ?? 0).toDouble();
    final remainingAmount = totalRepayment - paidAmount;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with loan ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Loan #${loanData['loanId'] ?? loanId.substring(0, 6)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildLoanStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),

            // Loan amount and repayment details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildLoanDetailRow(
                    'Loan Amount',
                    '${NumberFormat('#,##0.00').format(amount)} Tsh',
                    Icons.attach_money,
                  ),
                  const SizedBox(height: 8),
                  _buildLoanDetailRow(
                    'Total Repayment',
                    '${NumberFormat('#,##0.00').format(totalRepayment)} Tsh',
                    Icons.payments,
                  ),
                  const SizedBox(height: 8),
                  _buildLoanDetailRow(
                    'Monthly Payment',
                    '${NumberFormat('#,##0.00').format(monthlyRepayment)} Tsh',
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 8),
                  _buildLoanDetailRow(
                    'Interest Rate',
                    '${interestRate.toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Payment progress
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildLoanDetailRow(
                    'Amount Paid',
                    '${NumberFormat('#,##0.00').format(paidAmount)} Tsh',
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 8),
                  _buildLoanDetailRow(
                    'Remaining Amount',
                    '${NumberFormat('#,##0.00').format(remainingAmount)} Tsh',
                    Icons.pending,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: paidAmount / totalRepayment,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      paidAmount >= totalRepayment ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dates
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildLoanDetailRow(
                    'Applied Date',
                    formattedDate,
                    Icons.access_time,
                  ),
                  if (startDate != null) ...[
                    const SizedBox(height: 8),
                    _buildLoanDetailRow(
                      'Start Date',
                      DateFormat('dd/MM/yyyy').format(startDate),
                      Icons.event,
                    ),
                  ],
                  if (finishDate != null) ...[
                    const SizedBox(height: 8),
                    _buildLoanDetailRow(
                      'End Date',
                      DateFormat('dd/MM/yyyy').format(finishDate),
                      Icons.event,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Purpose
            if (loanData['purpose'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildLoanDetailRow(
                  'Purpose',
                  loanData['purpose'],
                  Icons.description,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanStatusChip(String status) {
    Color chipColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        displayText = 'Pending';
        break;
      case 'approved':
        chipColor = Colors.blue;
        displayText = 'Approved';
        break;
      case 'rejected':
        chipColor = Colors.red;
        displayText = 'Rejected';
        break;
      case 'disbursed':
        chipColor = Colors.green;
        displayText = 'Disbursed';
        break;
      case 'defaulted':
        chipColor = Colors.purple;
        displayText = 'Defaulted';
        break;
      default:
        chipColor = Colors.grey;
        displayText = 'Unknown';
    }

    return Chip(
      label: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLoanDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
