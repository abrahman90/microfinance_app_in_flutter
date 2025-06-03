import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vigezo na Masharti'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Masharti ya Mkopo'),
            SizedBox(height: 10),
            _buildLoanTermItem(
              'Kiasi cha Mkopo:',
              'Kuanzia Tsh 10,000 hadi Tsh 200,000',
            ),
            _buildLoanTermItem(
              'Muda wa Mkopo:',
              'Miezi 1 hadi 12 (Kulingana na makubaliano)',
            ),
            _buildLoanTermItem('Kiwango cha Riba:', '15% kwa mwezi'),
            _buildLoanTermItem(
              'Ada ya Usimamizi:',
              '5% ya kiasi cha mkopo (Inatozwa mara moja)',
            ),
            _buildLoanTermItem(
              'Malipo ya Kila Mwezi:',
              'Riba + Kiasi cha msingi cha mkopo',
            ),

            Divider(height: 30),

            _buildSectionHeader('Mahitaji ya Msingi'),
            SizedBox(height: 10),
            _buildRequirementItem('Umri: Miaka 18 na kuendelea'),
            _buildRequirementItem(
              'Kitambulisho halali (NIDA, Leseni ya Udereva, n.k)',
            ),
            _buildRequirementItem(
              'Nambari ya Simu iliyosajiliwa kwa jina lako',
            ),
            _buildRequirementItem(
              'Akaunti ya Benki inayotumika kwa mwezi mmoja au zaidi',
            ),

            Divider(height: 30),

            _buildSectionHeader('Maelekezo ya Uombaji Mkopo'),
            SizedBox(height: 10),
            _buildStepItem('1. Fungua programu ya BestStar'),
            _buildStepItem('2. Bonyeza kitufe cha "Omba Mkopo"'),
            _buildStepItem('3. Jaza fomu kwa taarifa sahihi'),
            _buildStepItem('4. Subiri uthibitisho kwa dakika chache'),
            _buildStepItem('5. Pokea mkopo kwenye akaunti yako'),

            Divider(height: 30),

            _buildSectionHeader('Vikwazo na Majukumu'),
            SizedBox(height: 10),
            _buildWarningItem(
              'Mteja atalipwa fidia kwa kila siku ya ucheleweshaji wa malipo',
            ),
            _buildWarningItem(
              'Mikopo isiyolipwa itaenda kwa ukusanyaji wa deni',
            ),
            _buildWarningItem(
              'Ukiwa na madeni yasiyolipwa, hutaweza kupata mikopo zaidi',
            ),
            _buildWarningItem(
              'Taarifa za uwongo zinaweza kusababisha kukataliwa kwa maombi yako',
            ),

            SizedBox(height: 20),
            Center(
              child: Text(
                '© 2023 Sadik. Haki zote zimehifadhiwa',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildLoanTermItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStepItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.blue,
            child: Text(
              text.split('.')[0],
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(text.substring(2))),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
