
import 'package:beststar/pages/user_notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await _prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mipangilio'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserProfileSection(auth: _auth, firestore: _firestore),
              SizedBox(height: 24),
              _NotificationSettings(firestore: _firestore),
              SizedBox(height: 24),
              _SecuritySection(auth: _auth, firestore: _firestore),
              SizedBox(height: 24),
              _SupportSection(),
              SizedBox(height: 24),
              _AppSettingsSection(
                isDarkMode: _isDarkMode,
                onThemeChanged: _toggleTheme,
              ),
              SizedBox(height: 40),
            //  _LogoutButton(auth: _auth),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileSection extends StatelessWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const _UserProfileSection({
    required this.auth,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(auth.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final firstName = userData?['firstName'] ?? 'Unknown';
        final email = auth.currentUser?.email ?? 'No email';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=$firstName&background=random',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          // Navigate to profile edit page
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text('Badili Taarifa'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationSettings extends StatefulWidget {
  final FirebaseFirestore firestore;

  const _NotificationSettings({required this.firestore});

  @override
  __NotificationSettingsState createState() => __NotificationSettingsState();
}

class __NotificationSettingsState extends State<_NotificationSettings> {
  bool _loanUpdates = true;
  bool _paymentReminders = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
   // _loadNotificationSettings();
  }
/*
  Future<void> _loadNotificationSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await widget.firestore.collection('notification_settings').doc(userId).get();
      if (doc.exists) {
        setState(() {
          _loanUpdates = doc.data()?['loanUpdates'] ?? true;
          _paymentReminders = doc.data()?['paymentReminders'] ?? true;
          _promotions = doc.data()?['promotions'] ?? false;
        });
      }
    }
  }*/

  Future<void> _updateNotificationSettings(String type, bool value) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await widget.firestore.collection('notification_settings').doc(userId).set({
        type: value,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Arifa',
      children: [
        _NotificationSwitchItem(
          title: 'Sasisho la Mikopo',
          value: _loanUpdates,
          onToggle: (val) {
            setState(() => _loanUpdates = val);
            _updateNotificationSettings('loanUpdates', val);
          },
        ),
        _NotificationSwitchItem(
          title: 'Kumbusho la Malipo',
          value: _paymentReminders,
          onToggle: (val) {
            setState(() => _paymentReminders = val);
            _updateNotificationSettings('paymentReminders', val);
          },
        ),
        _NotificationSwitchItem(
          title: 'Matangazo na Promosheni',
          value: _promotions,
          onToggle: (val) {
            setState(() => _promotions = val);
            _updateNotificationSettings('promotions', val);
          },
        ),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const _SecuritySection({
    required this.auth,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Usalama',
      children: [
        _SettingsItem(
          icon: Icons.fingerprint,
          title: 'Kutumia Alama ya Kidole',
          onTap: () {
            // Navigate to fingerprint settings
          },
        ),
        _SettingsItem(
          icon: Icons.lock_outline,
          title: 'Badili Nenosiri',
          onTap: () => _showChangePasswordDialog(context),
        ),
        _SettingsItem(
          icon: Icons.phonelink_lock_outlined,
          title: 'Vifaa Vilivyounganishwa',
          onTap: () => _showConnectedDevices(context),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Badili Nenosiri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nenosiri la Sasa',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nenosiri Jipya',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Thibitisha Nenosiri Jipya',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nenosiri halifanani')),
                );
                return;
              }

              try {
                final user = auth.currentUser;
                if (user != null) {
                  // Reauthenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  
                  // Change password
                  await user.updatePassword(newPasswordController.text);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nenosiri limebadilishwa kikamilifu')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hitilafu: ${e.toString()}')),
                );
              }
            },
            child: Text('Badili'),
          ),
        ],
      ),
    );
  }

  void _showConnectedDevices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vifaa Vilivyounganishwa'),
        content: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('devices')
              .where('userId', isEqualTo: auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final devices = snapshot.data!.docs;
            if (devices.isEmpty) {
              return Text('Hakuna vifaa vilivyounganishwa');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: devices.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: Icon(Icons.devices),
                  title: Text(data['deviceName'] ?? 'Device'),
                  subtitle: Text(data['lastLogin']?.toDate().toString() ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.logout, color: Colors.red),
                    onPressed: () async {
                      await doc.reference.delete();
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Funga'),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const _AppSettingsSection({
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Mipangilio ya Programu',
      children: [
        _SettingsItem(
          icon: Icons.notifications,
          title: 'Arifa',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserNotificationPage(),
              ),
            );
          },
        ),
        _SettingsItem(
          icon: Icons.dark_mode_outlined,
          title: 'Mandhari',
          trailing: Switch(
            value: isDarkMode,
            onChanged: (value) => onThemeChanged(),
          ),
          onTap: () {},
        ),
        _SettingsItem(
          icon: Icons.info_outline,
          title: 'Kuhusu Programu',
          onTap: () {
            // Navigate to about page
          },
        ),
      ],
    );
  }
}

/*class _LogoutButton extends StatelessWidget {
  final FirebaseAuth auth;

  const _LogoutButton({required this.auth});

  @override
 Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          _showLogoutConfirmation(context);
        },
        child: Text('Toka kwenye Akaunti', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Toka kwenye Akaunti'),
        content: Text('Una uhakika unataka kutoka kwenye akaunti yako?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ghairi'),
          ),
          TextButton(
            onPressed: () async {
              await auth.signOut();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Toka', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}*/

// Reusable Components

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  top: 12,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                child: children[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _NotificationSwitchItem extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool) onToggle;

  const _NotificationSwitchItem({
    required this.title,
    required this.value,
    required this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
        FlutterSwitch(
          width: 50,
          height: 28,
          value: value,
          onToggle: onToggle,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300]!,
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Usaidizi',
      children: [
        _SettingsItem(
          icon: Icons.help_outline,
          title: 'Maswali Yanayoulizwa Mara kwa Mara',
          onTap: () {
            // Navigate to FAQ page
            // You can implement the navigation here
          },
        ),
        _SettingsItem(
          icon: Icons.headset_mic_outlined,
          title: 'Wasiliana na Wateja',
          onTap: () {
            // Navigate to customer support page
            // You can implement the navigation here
          },
        ),
        _SettingsItem(
          icon: Icons.description_outlined,
          title: 'Vigezo na Masharti',
          onTap: () {
            // Navigate to terms and conditions page
            // You can implement the navigation here
          },
        ),
        _SettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Sera ya Faragha',
          onTap: () {
            // Navigate to privacy policy page
            // You can implement the navigation here
          },
        ),
      ],
    );
  }
}
