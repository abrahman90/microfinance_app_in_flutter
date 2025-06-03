import 'dart:async';
import 'dart:math';


import 'package:beststar/login_page.dart';
import 'package:beststar/pages/About_Us_Page.dart';
import 'package:beststar/pages/ApplyLoan.dart';
import 'package:beststar/pages/RepayLoan.dart';
import 'package:beststar/pages/Settings.dart';
import 'package:beststar/pages/TermsCondition.dart';
import 'package:beststar/pages/loanHistoryPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String?> getUserFirstName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return null;
      }

      debugPrint('Fetching user data for UID: ${user.uid}');
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      debugPrint('User document fetched: ${userDoc.data()}');

      if (!userDoc.exists) {
        debugPrint('User document does not exist');
        return null;
      }

      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('User data is null');
        return null;
      }

      if (!data.containsKey('firstName')) {
        debugPrint('firstName field is missing in user document');
        return null;
      }

      final firstName = data['firstName'] as String;
      debugPrint('Successfully fetched first name: $firstName');
      return firstName;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 20,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<String?>(
                future: getUserFirstName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('Error in FutureBuilder: ${snapshot.error}');
                    return const Text(
                      'Error loading name',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    );
                  }

                  final firstName = snapshot.data;
                  debugPrint('First name from snapshot: $firstName');
                  
                  final greeting = firstName?.isNotEmpty == true 
                      ? 'Habari, $firstName' 
                      : 'Habari';

                  return Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                },
              ),
            ),
          ],
        ),
        centerTitle: true,
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notification action
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      /*    drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'VertEditors',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
              title: const Text('Mkopo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
*/
      body: SingleChildScrollView(
        child: Column(
          children: [
            LoanCircleSection(),
            const SizedBox(height: 20),
            LoanActionsSection(),
            const SizedBox(height: 20),
            SalaryAdvanceInfoSection(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarSection(),
    );
  }
}

class ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;

  const ToggleTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? Colors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.grey),
      ),
    );
  }
}

class LoanCircleSection extends StatefulWidget {
  @override
  _LoanCircleSectionState createState() => _LoanCircleSectionState();
}

class _LoanCircleSectionState extends State<LoanCircleSection> {
  bool _isVisible = false;
  int availableLoan = 200000;
  int currentLoan = 0;
  int remainingLoan = 0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _loansSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _listenToLoans();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            availableLoan = data['availableLoan'] ?? 200000;
            currentLoan = data['currentLoan'] ?? 0;
          });
        }
      }
    }
  }

  void _listenToUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              Map<String, dynamic>? data =
                  snapshot.data() as Map<String, dynamic>?;
              if (data != null) {
                setState(() {
                  availableLoan = data['availableLoan'] ?? 200000;
                });
              }
            }
          });
    }
  }

  void _listenToLoans() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
  _loansSubscription = FirebaseFirestore.instance
      .collection('loans')
      .where('userId', isEqualTo: user.uid)
      .where('status', whereIn: ['approved', 'disbursed'])
      .snapshots()
      .listen((snapshot) {
        if (mounted) {
          int totalCurrentLoan = 0;
          int totalPaidAmount = 0;
          
          for (var doc in snapshot.docs) {
            try {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              
              // Calculate loan amount with interest
              int amount = (data['amount'] ?? 0).toInt();
              int term = (data['termMonths'] ?? 0).toInt();
              double interestRate = ((data['interestRate'] ?? 15).toDouble()) / 100;
              double totalWithInterest = amount * (pow(1 + interestRate, term) as double);
              totalCurrentLoan += totalWithInterest.round();
              
              // Handle paid amount with proper type conversion
              dynamic paidAmount = data['paidAmount'];
              if (paidAmount != null) {
                if (paidAmount is int) {
                  totalPaidAmount += paidAmount;
                } else if (paidAmount is double) {
                  totalPaidAmount += paidAmount.round();
                } else if (paidAmount is String) {
                  totalPaidAmount += int.tryParse(paidAmount) ?? 0;
                } else {
                  totalPaidAmount += 0;
                }
              }
            } catch (e) {
              debugPrint('Error processing loan document ${doc.id}: $e');
            }
          }
          
          if (mounted) {
            setState(() {
              currentLoan = totalCurrentLoan;
              remainingLoan = totalCurrentLoan - totalPaidAmount;
            });
          }
        }
      });
}
          
    }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _loansSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Bustisha kipato",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Unachoweza kukopa",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isVisible
                        ? 'Tsh ${NumberFormat('#,###').format(availableLoan)}'
                        : "********",
                    style: const TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
               /*  const Text(
                    "Mkopo ulionao",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isVisible
                        ? 'Tsh ${NumberFormat('#,###').format(currentLoan)}'
                        : "********",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),*/
                  if (_isVisible && remainingLoan > 0) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Mkopo uliobaki",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tsh ${NumberFormat('#,###').format(remainingLoan)}',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() => _isVisible = !_isVisible);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Onyesha",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanActionsSection extends StatelessWidget {
  final List<_LoanActionItem> actions = [
    _LoanActionItem('Omba Mkopo', Icons.attach_money, ApplyLoanPage()),
    _LoanActionItem('Rejesha', Icons.refresh, RepayLoanPage()),
    _LoanActionItem(
      'Historia ya Mikopo',
      Icons.receipt_long,
      LoanHistoryPage(
        loanFilter: 'all',
        searchQuery: '',
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      ),
    ),
    _LoanActionItem('Masharti', Icons.description, TermsConditionsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return _FancyAnimatedCard(item: actions[index]);
        },
      ),
    );
  }
}

class _FancyAnimatedCard extends StatefulWidget {
  final _LoanActionItem item;

  const _FancyAnimatedCard({required this.item});

  @override
  State<_FancyAnimatedCard> createState() => _FancyAnimatedCardState();
}

class _FancyAnimatedCardState extends State<_FancyAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPage(BuildContext context) async {
    try {
      if (widget.item.label == 'Historia ya Mikopo') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => LoanHistoryPage(
                  loanFilter: 'all',
                  searchQuery: '',
                  firestore: FirebaseFirestore.instance,
                  auth: FirebaseAuth.instance,
                ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => widget.item.page),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: () => _navigateToPage(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: Offset(4, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: Icon(widget.item.icon, color: Colors.white, size: 28),
                ),
                SizedBox(height: 14),
                Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanActionItem {
  final String label;
  final IconData icon;
  final Widget page;

  _LoanActionItem(this.label, this.icon, this.page);
}

class ActionIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ActionIcon({
    required this.label,
    required this.icon,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class BottomActionIcon extends StatelessWidget {
  final String label;
  final IconData icon;

  const BottomActionIcon({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 5),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class SalaryAdvanceInfoSection extends StatefulWidget {
  @override
  _SalaryAdvanceInfoSectionState createState() =>
      _SalaryAdvanceInfoSectionState();
}

class _SalaryAdvanceInfoSectionState extends State<SalaryAdvanceInfoSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> messages = [
    'Pata hadi TZS milioni 3',
    'Riba ni ndogo tu: 15%',
    'Lipa kwa siku 30',
    'Hakuna dhamana!',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _startTextRotation();
    });
  }

  void _startTextRotation() {
    _messageTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Advance',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child: Text(
                    messages[_currentMessageIndex],
                    key: ValueKey<String>(messages[_currentMessageIndex]),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavigationBarSection extends StatelessWidget {
  const BottomNavigationBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutUsPage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Home',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'AboutUs'),
      ],
    );
  }
}
