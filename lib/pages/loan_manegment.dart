import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoanManagement extends StatefulWidget {

  
  final String loanFilter;
  final String searchQuery;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  
  const LoanManagement({
    Key? key,
    required this.loanFilter,
    required this.searchQuery,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  @override
  _LoanManagementTabState createState() => _LoanManagementTabState();
}

class _LoanManagementTabState extends State<LoanManagement> {
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
    return Padding(
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

                if (snapshot.data!.docs.isEmpty) {
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
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading loans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
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
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Query _buildLoanQuery() {
    Query query = widget.firestore.collection('loans');

    if (widget.loanFilter != 'all') {
      query = query.where('status', isEqualTo: widget.loanFilter);
    }

    if (widget.searchQuery.isNotEmpty) {
      query = query.where(
        'searchKeywords',
        arrayContains: widget.searchQuery.toLowerCase(),
      );
    }

    return query.orderBy('requestDate', descending: true);
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
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'all', child: Text('All Loans')),
            const PopupMenuItem(value: 'pending', child: Text('Pending')),
            const PopupMenuItem(value: 'approved', child: Text('Approved')),
            const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            const PopupMenuItem(value: 'disbursed', child: Text('Disbursed')),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 24,
        ),
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 8),
            
            // User info
            Text(
              '${loanData['userName'] ?? 'Unknown user'}',
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Loan details (amount, term, rate)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLoanDetail(
                  'Amount',
                  '${NumberFormat('#,###').format(loanData['amount'])} Tsh',
                ),
                _buildLoanDetail('Term', '${loanData['termMonths']} months'),
                _buildLoanDetail(
                  'Rate',
                  '${loanData['interestRate']?.toStringAsFixed(1) ?? '0.0'}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dates
            if (startDate != null && finishDate != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLoanDetail(
                        'Start Date',
                        DateFormat('dd/MM/yyyy').format(startDate),
                      ),
                      _buildLoanDetail(
                        'End Date',
                        DateFormat('dd/MM/yyyy').format(finishDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            
            // Applied date and purpose
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Applied: $formattedDate',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (loanData['purpose'] != null)
                  Flexible(
                    child: Text(
                      loanData['purpose'],
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            if (status == 'pending') _buildPendingLoanActions(context),
            if (status == 'approved') _buildApprovedLoanActions(context),
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
      default:
        chipColor = Colors.grey;
        displayText = 'Unknown';
    }

    return Chip(
      label: Text(
        displayText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLoanDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLoanActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectLoan(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _approveLoan(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedLoanActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _disburseLoan(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.green),
            ),
            child: const Text(
              'Disburse',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _viewLoanDetails(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('View Details'),
          ),
        ),
      ],
    );
  }

  void _approveLoan(BuildContext context) {
    final amountController = TextEditingController(
      text: loanData['amount']?.toString() ?? '',
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Loan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Verify loan details before approval:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Loan Amount (Tsh)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Approval Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                await firestore.collection('loans').doc(loanId).update({
                  'status': 'approved',
                  'approvalDate': DateTime.now(),
                  'approvedBy': auth.currentUser?.uid,
                  'approvalNotes': notesController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan approved successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _rejectLoan(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;

              try {
                await firestore.collection('loans').doc(loanId).update({
                  'status': 'rejected',
                  'rejectionReason': reasonController.text,
                  'rejectedBy': auth.currentUser?.uid,
                  'rejectionDate': DateTime.now(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan rejected successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _disburseLoan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disburse Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm loan disbursement details:'),
            const SizedBox(height: 16),
            Text(
              'Amount: ${NumberFormat('#,###').format(loanData['amount'])} Tsh',
            ),
            const SizedBox(height: 8),
            Text('Term: ${loanData['termMonths']} months'),
            const SizedBox(height: 8),
            Text('Interest: ${loanData['interestRate']}%'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Transaction Reference',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestore.collection('loans').doc(loanId).update({
                  'status': 'disbursed',
                  'disbursementDate': DateTime.now(),
                  'disbursedBy': auth.currentUser?.uid,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan disbursed successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Confirm Disbursement'),
          ),
        ],
      ),
    );
  }

  void _viewLoanDetails(BuildContext context) {
    final startDate = (loanData['startDate'] as Timestamp?)?.toDate();
    final finishDate = (loanData['finishDate'] as Timestamp?)?.toDate();
    final dueDate = (loanData['dueDate'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Loan Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLoanDetailCard('Basic Information', [
                _buildDetailItem('Loan ID', loanData['loanId'] ?? loanId),
                _buildDetailItem('User', loanData['userName'] ?? 'Unknown'),
                _buildDetailItem('Status', loanData['status'] ?? 'pending'),
                _buildDetailItem(
                  'Amount',
                  '${NumberFormat('#,###').format(loanData['amount'])} Tsh',
                ),
                _buildDetailItem(
                  'Term',
                  '${loanData['termMonths']} months',
                ),
                _buildDetailItem(
                  'Interest Rate',
                  '${loanData['interestRate']}%',
                ),
              ]),
              _buildLoanDetailCard('Dates', [
                if (startDate != null)
                  _buildDetailItem(
                    'Start Date',
                    DateFormat('dd/MM/yyyy HH:mm').format(startDate),
                  ),
                if (finishDate != null)
                  _buildDetailItem(
                    'End Date',
                    DateFormat('dd/MM/yyyy HH:mm').format(finishDate),
                  ),
                if (dueDate != null)
                  _buildDetailItem(
                    'Due Date',
                    DateFormat('dd/MM/yyyy').format(dueDate),
                  ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanDetailCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}