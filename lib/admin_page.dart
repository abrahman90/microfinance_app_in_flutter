import 'dart:math';


import 'package:beststar/login_page.dart';
import 'package:beststar/pages/admin_notification_page.dart';
import 'package:beststar/services/notification_service.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';


class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  int _currentIndex = 0;
  String _searchQuery = '';
  String _loanFilter = 'all';
  String _userFilter = 'all';
  bool _isAdmin = false;
    int _totalUsers = 0;
  double _totalLoanAmount = 0;
  double _totalWithInterest = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
      _loadSummaryData(); 
  }



  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdTokenResult(true);
        if (!mounted) return;
        setState(() {
          _isAdmin = idToken.claims?['admin'] == true;
        });

        if (!_isAdmin) {
          // If not admin, show error and optionally sign out
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin access required')),
          );
          //await _signOut();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking admin status: $e')),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isAdmin = false);
    }
  }

  Future<void> setupAdmin() async {
    try {
      HttpsCallable callable = _functions.httpsCallable(
        'setUserClaims',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'targetUserId': _auth.currentUser?.uid ?? '',
        'claims': {'admin': true},
      });

      if (result.data['success'] == true) {
        // Force token refresh to get new claims
        await _auth.currentUser?.getIdTokenResult(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin privileges set successfully')),
        );
        await _checkAdminStatus();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting admin: ${e.toString()}')),
      );
    }
  }
  Future<void> _loadSummaryData() async {
    try {
      // Get total users count
      final usersQuery = await _firestore.collection('users').get();
      final loansQuery = await _firestore.collection('loans')
          .where('status', whereIn: ['approved', 'disbursed'])
          .get();

      double totalPrincipal = 0;
      double totalWithInterest = 0;
      final now = DateTime.now();

      for (final loanDoc in loansQuery.docs) {
        final loanData = loanDoc.data() as Map<String, dynamic>;
        final amount = (loanData['amount'] as num).toDouble();
        final termMonths = (loanData['termMonths'] as num).toInt();
        final startDate = (loanData['startDate'] as Timestamp?)?.toDate();
        
        totalPrincipal += amount;
        
        if (startDate != null) {
          // Calculate months passed since loan start
          final monthsPassed = (now.difference(startDate).inDays / 30);
          final effectiveMonths = monthsPassed.clamp(0, termMonths.toDouble());
          
          // Calculate amount with 15% monthly compound interest
          totalWithInterest += amount * pow(1.15, effectiveMonths);
        } else {
          // If no start date, just use principal amount
          totalWithInterest += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalUsers = usersQuery.size;
        _totalLoanAmount = totalPrincipal;
        _totalWithInterest = totalWithInterest;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading summary data: $e')),
      );
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microfinance Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminNotificationPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAdminStatus();
              _loadSummaryData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add summary cards at the top
       //   _buildSummaryCards(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                UserManagementTab(
                  userFilter: _userFilter,
                  searchQuery: _searchQuery,
                  firestore: _firestore,
                  auth: _auth,
                ),
                LoanManagementTab(
                  loanFilter: _loanFilter,
                  searchQuery: _searchQuery,
                  firestore: _firestore,
                  auth: _auth,
                  functions: _functions,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Loans'),
        ],
      ),
    );
  }

  // New widget to display summary cards
 /* Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalUsers.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Loans',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat('#,###').format(_totalLoanAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'TZS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Due',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat('#,###').format(_totalWithInterest),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'TZS (15% monthly)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }*/

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Show logout success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));

      // Navigate to LoginPage
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: ${e.message}')));
    }
  }
}

class UserManagementTab extends StatefulWidget {
  final String userFilter;
  final String searchQuery;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const UserManagementTab({
    Key? key,
    required this.userFilter,
    required this.searchQuery,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  @override
  _UserManagementTabState createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchAndFilterRow(context),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildUserQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data!.docs[index];
                    return UserCard(
                      userData: user.data() as Map<String, dynamic>,
                      userId: user.id,
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

  Query _buildUserQuery() {
    Query query = widget.firestore.collection('users');

    if (widget.userFilter != 'all') {
      query = query.where('accountStatus', isEqualTo: widget.userFilter);
    }

    if (widget.searchQuery.isNotEmpty) {
      query = query.where(
        'searchKeywords',
        arrayContains: widget.searchQuery.toLowerCase(),
      );
    }

    return query.orderBy('createdAt', descending: true);
  }

  Widget _buildSearchAndFilterRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Users',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
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
                const PopupMenuItem(value: 'all', child: Text('All Users')),
                const PopupMenuItem(value: 'active', child: Text('Active')),
                const PopupMenuItem(
                  value: 'suspended',
                  child: Text('Suspended'),
                ),
                const PopupMenuItem(
                  value: 'unverified',
                  child: Text('Unverified'),
                ),
              ],
        ),
      ],
    );
  }
}

class UserCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const UserCard({
    Key? key,
    required this.userData,
    required this.userId,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.userData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['lastName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = (widget.userData['createdAt'] as Timestamp?)?.toDate();
    final formattedDate =
        createdAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
            : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isEditing)
                  Text(
                    '${widget.userData['firstName']} ${widget.userData['lastName']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (_isEditing)
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                  ),
                if (_isEditing)
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                _buildStatusChip(widget.userData['accountStatus'] ?? 'active'),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isEditing) ...[
              _buildInfoRow(
                Icons.email,
                widget.userData['email'] ?? 'No email',
              ),
              _buildInfoRow(
                Icons.phone,
                widget.userData['phone'] ?? 'No phone',
              ),
              _buildInfoRow(Icons.calendar_today, formattedDate),
            ],
            if (_isEditing) ...[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isEditing) ...[
                  if (widget.userData['accountStatus'] != 'suspended')
                    OutlinedButton(
                      onPressed: () => _suspendUser(context),
                      child: const Text(
                        'Suspend',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (widget.userData['accountStatus'] == 'suspended')
                    OutlinedButton(
                      onPressed: () => _activateUser(context),
                      child: const Text(
                        'Activate',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _deleteUser(context),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Edit'),
                  ),
                ],
                if (_isEditing) ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _saveUserDetails(context),
                    child: const Text('Save'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'suspended':
        chipColor = Colors.red;
        break;
      case 'unverified':
        chipColor = Colors.orange;
        break;
      case 'active':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _suspendUser(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Suspend User'),
            content: const Text('Are you sure you want to suspend this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await widget.firestore
                        .collection('users')
                        .doc(widget.userId)
                        .update({
                          'accountStatus': 'suspended',
                          'suspendedAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User suspended successfully'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text(
                  'Suspend',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _activateUser(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Activate User'),
            content: const Text('Are you sure you want to activate this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await widget.firestore
                        .collection('users')
                        .doc(widget.userId)
                        .update({
                          'accountStatus': 'active',
                          'activatedAt': FieldValue.serverTimestamp(),
                        });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User activated successfully'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text(
                  'Activate',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  void _deleteUser(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: const Text(
              'Are you sure you want to permanently delete this user? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // First delete user data
                    await widget.firestore
                        .collection('users')
                        .doc(widget.userId)
                        .delete();

                    // Then delete the auth user
                    final user = await widget.auth.fetchSignInMethodsForEmail(
                      widget.userData['email'],
                    );
                    if (user.isNotEmpty) {
                      await widget.auth.currentUser?.delete();
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _saveUserDetails(BuildContext context) async {
    try {
      await widget.firestore.collection('users').doc(widget.userId).update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: ${e.toString()}')),
      );
    }
  }
}

class LoanManagementTab extends StatefulWidget {
  final String loanFilter;
  final String searchQuery;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  const LoanManagementTab({
    Key? key,
    required this.loanFilter,
    required this.searchQuery,
    required this.firestore,
    required this.auth,
    required this.functions,
  }) : super(key: key);

  @override
  _LoanManagementTabState createState() => _LoanManagementTabState();
}

class _LoanManagementTabState extends State<LoanManagementTab> {
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildLoanFilterRow(context),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _createNewLoan(context),
                icon: const Icon(Icons.add),
                label: const Text('New Loan'),
              ),
              ElevatedButton.icon(
                onPressed: () => _showReports(context),
                icon: const Icon(Icons.assessment),
                label: const Text('Reports'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildLoanQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No loans found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
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
                      functions: widget.functions,
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
                const PopupMenuItem(
                  value: 'defaulted',
                  child: Text('Defaulted'),
                ),
              ],
        ),
      ],
    );
  }

  void _createNewLoan(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final termController = TextEditingController();
    final purposeController = TextEditingController();
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Loan'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<QuerySnapshot>(
                  future: widget.firestore.collection('users').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    
                    final users = snapshot.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                      ),
                      items: users.map((user) {
                        final data = user.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: user.id,
                          child: Text('${data['firstName']} ${data['lastName']}'),
                        );
                      }).toList(),
                      onChanged: (value) => selectedUserId = value,
                      validator: (value) => value == null ? 'Please select a user' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount (Tsh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: termController,
                  decoration: const InputDecoration(
                    labelText: 'Term (months)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter term';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter purpose' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final amount = double.parse(amountController.text);
                  final termMonths = int.parse(termController.text);
                  final totalRepayment = amount * pow(1.15, termMonths);
                  
                  // Create loan document with all necessary fields
                  await widget.firestore.collection('loans').add({
                    'userId': selectedUserId,
                    'amount': amount,
                    'termMonths': termMonths,
                    'purpose': purposeController.text,
                    'status': 'pending',
                    'requestDate': DateTime.now(),
                    'interestRate': 15.0,
                    'totalRepayment': totalRepayment,
                    'paidAmount': 0.0,
                    'monthlyPayment': totalRepayment / termMonths,
                    'searchKeywords': [
                      amount.toString(),
                      termMonths.toString(),
                      purposeController.text.toLowerCase(),
                    ],
                    'createdBy': widget.auth.currentUser?.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  // Update user's loan statistics
                  await widget.firestore.collection('users').doc(selectedUserId).update({
                    'hasActiveLoan': true,
                    'totalLoansCount': FieldValue.increment(1),
                    'lastLoanDate': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loan created successfully')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Create Loan'),
          ),
        ],
      ),
    );
  }

  void _showReports(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loan Reports'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<QuerySnapshot>(
                future: widget.firestore.collection('loans').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final loans = snapshot.data?.docs ?? [];
                  double totalDisbursed = 0;
                  double totalRepayment = 0;
                  double totalPaid = 0;
                  Map<String, double> userTotals = {};

                  for (final loan in loans) {
                    final data = loan.data() as Map<String, dynamic>;
                    if (data['status'] == 'disbursed') {
                      final amount = (data['amount'] ?? 0).toDouble();
                      final paidAmount = (data['paidAmount'] ?? 0).toDouble();
                      final userId = data['userId'] as String;
                      
                      totalDisbursed += amount;
                      totalPaid += paidAmount;
                      totalRepayment += (data['totalRepayment'] ?? 0).toDouble();
                      
                      userTotals[userId] = (userTotals[userId] ?? 0) + amount;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportCard(
                        'Total Statistics',
                        [
                          _buildReportItem('Total Disbursed', totalDisbursed),
                          _buildReportItem('Total Repayment Due', totalRepayment),
                          _buildReportItem('Total Paid', totalPaid),
                          _buildReportItem('Total Outstanding', totalRepayment - totalPaid),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Per User Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...userTotals.entries.map((entry) => FutureBuilder<DocumentSnapshot>(
                        future: widget.firestore.collection('users').doc(entry.key).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final userData = snapshot.data?.data() as Map<String, dynamic>?;
                          final userName = userData != null 
                              ? '${userData['firstName']} ${userData['lastName']}'
                              : 'Unknown User';
                          return _buildReportItem(userName, entry.value);
                        },
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${NumberFormat('#,##0.00').format(amount)} Tsh',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final String loanId;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  const LoanCard({
    Key? key,
    required this.loanData,
    required this.loanId,
    required this.firestore,
    required this.auth,
    required this.functions,
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
    
    // Calculate total repayment with 15% monthly interest
    final amount = (loanData['amount'] ?? 0).toDouble();
    final termMonths = (loanData['termMonths'] ?? 1).toInt();
    final totalRepayment = amount * pow(1.15, termMonths);
    final monthlyRepayment = totalRepayment / termMonths;
    final paidAmount = (loanData['paidAmount'] ?? 0).toDouble();
    final remainingAmount = totalRepayment - paidAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Loan #${loanData['loanId'] ?? loanId.substring(0, 6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _buildLoanStatusChip(status),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLoan(context),
                        tooltip: 'Delete Loan',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('users').doc(loanData['userId']).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading...');
                }
                
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('Unknown user');
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final firstName = userData['firstName'] ?? '';
                final lastName = userData['lastName'] ?? '';
                
                return Text(
                  '$firstName $lastName'.trim(),
                  style: TextStyle(color: Colors.grey[600]),
                );
              },
            ),
            const SizedBox(height: 12),
            // Updated amount display with total repayment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(amount)} Tsh',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total with 15% interest:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(totalRepayment)} Tsh',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (paidAmount > 0) ...[
                      Text(
                        'Paid amount:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(paidAmount)} Tsh',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Remaining amount:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(remainingAmount)} Tsh',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Term',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '$termMonths months',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Monthly payment:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(monthlyRepayment)} Tsh',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      '${loanData['interestRate']?.toStringAsFixed(1) ?? '15.0'}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (startDate != null && finishDate != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLoanDetail(
                    'Start Date',
                    value: DateFormat('dd/MM/yyyy').format(startDate),
                  ),
                  _buildLoanDetail(
                    'End Date',
                    value: DateFormat('dd/MM/yyyy').format(finishDate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied: $formattedDate',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (loanData['purpose'] != null)
                  Text(
                    loanData['purpose'],
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (status == 'pending') _buildPendingLoanActions(context),
            if (status == 'approved') _buildApprovedLoanActions(context),
            if (status == 'approved' || status == 'disbursed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Enter Payment Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        // Store the payment amount in a local variable
                        // This will be used when the payment button is pressed
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _recordPayment(context),
                    child: const Text('Record Payment'),
                  ),
                ],
              ),
            ],
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
          fontSize: 10,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLoanDetail(String label, {required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPendingLoanActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectLoan(context),
            style: OutlinedButton.styleFrom(
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
            child: const Text('View Details'),
          ),
        ),
      ],
    );
  }

  Future<void> _approveLoan(BuildContext context) async {
    // Show dialog to verify loan details
    final TextEditingController amountController = TextEditingController(
      text: loanData['amount']?.toString() ?? '',
    );
    final TextEditingController notesController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Loan Amount',
                prefixText: 'tsh',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Approval Notes (Optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate amount
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update loan amount if changed
      final newAmount = double.parse(amountController.text);
      if (newAmount != loanData['amount']) {
        await firestore.collection('loans').doc(loanId).update({
          'amount': newAmount,
          'totalRepayment': newAmount * (1 + loanData['interestRate'] / 100) * loanData['termMonths'],
        });
      }

      // Update loan status
      await firestore.collection('loans').doc(loanId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': auth.currentUser!.uid,
        'approvalNotes': notesController.text.trim(),
      });

      // Send notification to user
      final notificationService = NotificationService();
      await notificationService.sendNotificationToUser(
        userId: loanData['userId'],
        title: 'Loan Approved',
        body: 'Your loan application has been approved for ₦${NumberFormat('#,###').format(newAmount)}',
        data: {
          'type': 'loan_approved',
          'loanId': loanId,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving loan: $e')),
      );
    }
  }

  void _rejectLoan(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  validator: (value) => value!.isEmpty ? 'Required' : null,
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

                    await _sendNotification(
                      loanData['userId'],
                      'Loan Rejected',
                      'Your loan application was rejected. Reason: ${reasonController.text}',
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loan rejected successfully'),
                      ),
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
      builder:
          (context) => AlertDialog(
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

                    await firestore
                        .collection('users')
                        .doc(loanData['userId'])
                        .update({
                          'outstandingLoans': FieldValue.increment(
                            loanData['amount'],
                          ),
                        });

                    await _sendNotification(
                      loanData['userId'],
                      'Loan Disbursed',
                      'Your loan of ${NumberFormat('#,###').format(loanData['amount'])} Tsh has been disbursed',
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loan disbursed successfully'),
                      ),
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
      builder:
          (context) => SingleChildScrollView(
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
                    _buildDetailItem(
                      'Total Repayment',
                      '${NumberFormat('#,###').format(loanData['totalRepayment'])} Tsh',
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
                    _buildDetailItem(
                      'Application Date',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format((loanData['requestDate'] as Timestamp).toDate()),
                    ),
                    if (loanData['approvalDate'] != null)
                      _buildDetailItem(
                        'Approval Date',
                        DateFormat('dd/MM/yyyy').format(
                          (loanData['approvalDate'] as Timestamp).toDate(),
                        ),
                      ),
                  ]),
                  if (loanData['approvalNotes'] != null)
                    _buildLoanDetailCard('Approval Notes', [
                      Text(loanData['approvalNotes']),
                    ]),
                  if (loanData['rejectionReason'] != null)
                    _buildLoanDetailCard('Rejection Reason', [
                      Text(loanData['rejectionReason']),
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
        padding: const EdgeInsets.all(16.0),
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

  Future<void> _sendNotification(
    String userId,
    String title,
    String message,
  ) async {
    try {
      await firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'timestamp': DateTime.now(),
        'read': false,
        'loanId': loanId,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  void _recordPayment(BuildContext context) {
    final paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: paymentController,
              decoration: const InputDecoration(
                labelText: 'Payment Amount (Tsh)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
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
              final paymentAmount = double.tryParse(paymentController.text);
              if (paymentAmount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              try {
                final currentPaidAmount = (loanData['paidAmount'] ?? 0).toDouble();
                final newPaidAmount = currentPaidAmount + paymentAmount;
                final totalRepayment = loanData['amount'] * pow(1.15, loanData['termMonths']);
                
                await firestore.collection('loans').doc(loanId).update({
                  'paidAmount': newPaidAmount,
                  'lastPaymentDate': FieldValue.serverTimestamp(),
                  'lastPaymentAmount': paymentAmount,
                  'status': newPaidAmount >= totalRepayment ? 'completed' : 'disbursed',
                });

                // Send notification to user
                await _sendNotification(
                  loanData['userId'],
                  'Payment Recorded',
                  'Payment of ${NumberFormat('#,###').format(paymentAmount)} Tsh has been recorded for your loan.',
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _deleteLoan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this loan?'),
            const SizedBox(height: 8),
            Text(
              'Loan #${loanData['loanId'] ?? loanId.substring(0, 6)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${NumberFormat('#,##0.00').format(loanData['amount'])} Tsh',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${loanData['status']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. All loan data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                // Delete the loan document
                await firestore.collection('loans').doc(loanId).delete();

                // If the loan was disbursed, update user's outstanding loans
                if (loanData['status'] == 'disbursed') {
                  await firestore.collection('users').doc(loanData['userId']).update({
                    'outstandingLoans': FieldValue.increment(-(loanData['amount'] ?? 0)),
                  });
                }

                // Send notification to user
                await _sendNotification(
                  loanData['userId'],
                  'Loan Deleted',
                  'Your loan of ${NumberFormat('#,##0.00').format(loanData['amount'])} Tsh has been deleted by the admin.',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loan deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting loan: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}