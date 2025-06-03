import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=BestStar App Inquiry',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kuhusu BestStar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'lib/image/logo.jpg', // Replace with your actual logo path
                height: 120,
                width: 120,
              ),
              SizedBox(height: 16),
              Text(
                'BestStar - Mikopo ya Haraka na Rahisi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Tunatoa huduma ya mikopo ya haraka kwa wateja wetu kwa riba nafuu na mchakato rahisi wa maombi kupitia programu yetu ya simu.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // Key Features
              Text(
                'Vipengele Vyetu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFeatureChip(Icons.speed, 'Mikopo ya Haraka'),
                  _buildFeatureChip(Icons.phone_android, 'Maombi Kupitia Simu'),
                  _buildFeatureChip(Icons.security, 'Salama na Thabiti'),
                  _buildFeatureChip(Icons.money, 'Kiasi: 10,000 - 200,000 Tsh'),
                  _buildFeatureChip(Icons.percent, 'Riba: 15% kwa mwezi'),
                  _buildFeatureChip(Icons.access_time, 'Muda: Miezi 1-12'),
                ],
              ),
              SizedBox(height: 20),

              // Contact Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.green),
                      title: Text('Wasiliana Nasi'),
                      subtitle: Text('+255 616803336'),
                      onTap: () => _launchPhoneCall('+255 616803336'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.red),
                      title: Text('Barua Pepe'),
                      subtitle: Text('info@beststar.co.tz'),
                      onTap: () => _launchEmail('info@beststar.co.tz'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.location_on, color: Colors.blue),
                      title: Text('Ofisi Zetu'),
                      subtitle: Text('Dar es Salaam, Tanzania'),
                      onTap: () {
                        // Launch maps functionality would go here
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Team Section
              Text(
                'Timu Yetu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 10),
              _buildTeamMemberCard(
                'Ramadhan Poton',
                'Telecommunication Engineering',
                'lib/image/ramadhan.jpg',
                'ramadhanevpoton.me',
              ),
              _buildTeamMemberCard(
                'Sadik Abrahman',
                'Software Engineering ',
                'lib/image/sadik.jpg',
                'sadikdickson@gmail.com',
              ),
              SizedBox(height: 20),

              // Social Media
              Text(
                'Tufuatilie Mitandao',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    FontAwesomeIcons.facebook,
                    Colors.indigo,
                    'https://facebook.com/beststartz',
                  ),
                  SizedBox(width: 15),
                  _buildSocialButton(
                    FontAwesomeIcons.instagram,
                    Colors.pink,
                    'https://instagram.com/beststartz',
                  ),
                  SizedBox(width: 15),
                  _buildSocialButton(
                    FontAwesomeIcons.twitter,
                    Colors.lightBlue,
                    'https://twitter.com/beststartz',
                  ),
                  SizedBox(width: 15),
                  _buildSocialButton(
                    FontAwesomeIcons.linkedin,
                    Colors.blue.shade800,
                    'https://linkedin.com/company/beststartz',
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Footer
              Text(
                '© ${DateTime.now().year} Sadik. Haki zote zimehifadhiwa',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.blue),
      label: Text(label),
      backgroundColor: Colors.blue.shade50,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.blue.shade100),
      ),
    );
  }

  Widget _buildTeamMemberCard(
    String name,
    String position,
    String imagePath,
    String email,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(imagePath),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(position),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _launchEmail(email),
                    child: Text(
                      email,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
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

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not open $url';
        }
      },
      child: CircleAvatar(
        radius: 25,
        backgroundColor: color,
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}