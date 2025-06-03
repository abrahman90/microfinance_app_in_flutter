import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class RepayLoanPage extends StatefulWidget {
  @override
  _RepayLoanPageState createState() => _RepayLoanPageState();
}

class _RepayLoanPageState extends State<RepayLoanPage> {
  Bank? selectedBank;
  final TextEditingController _accountController = TextEditingController();

  final List<Bank> banks = [
    Bank(
      name: 'Airtel Money',
      image: 'lib/image/airtel.jpg',
      paymentNumber: '255635252590',
      owner: 'Sadik',
    ),
    Bank(
      name: 'Vodacom M-Pesa',
      image: 'lib/image/vodacom.jpg',
      paymentNumber: '25574636352',
      owner: 'Saleh',
    ),
    Bank(
      name: 'CRDB',
      image: 'lib/image/crdb.jpg',
      paymentNumber: '135324673635',
      owner: 'John',
    ),
    Bank(
      name: 'NMB',
      image: 'lib/image/nmb.jpg',
      paymentNumber: '924535353253',
      owner: 'Georgy',
    ),
    Bank(
      name: 'YAS',
      image: 'lib/image/yas.jpg',
      paymentNumber: '255657472032',
      owner: 'Angle',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rejesha Mkopo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chagua Mfumo wa Malipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children:
                  banks.map((bank) {
                    return BankCard(
                      bank: bank,
                      isSelected: selectedBank == bank,
                      onTap: () {
                        setState(() {
                          selectedBank = bank;
                          _accountController.text = '';
                        });
                      },
                    );
                  }).toList(),
            ),

            SizedBox(height: 20),

            if (selectedBank != null) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namba ya Malipo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              selectedBank!.paymentNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              'Mmiliki: ${selectedBank!.owner}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: selectedBank!.paymentNumber),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Namba imenakiliwa!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text('Ingiza Namba ya Akaunti', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                //  border: OutlineInputBorder(),
               //   hintText: 'Ingiza namba yako ya akaunti',
                //  prefixIcon: Icon(Icons.credit_card),
                ),
              //  keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
            ],

            Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedBank != null && _accountController.text.isNotEmpty
                        ? () {
                          _processPayment();
                        }
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('Rudi Nyumban', style: TextStyle(fontSize: 14)),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hakiki Malipo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Benki: ${selectedBank!.name}'),
                Text('Mmiliki: ${selectedBank!.owner}'),
                Text('Namba ya Malipo: ${selectedBank!.paymentNumber}'),
                Text('Namba ya Akaunti: ${_accountController.text}'),
                SizedBox(height: 20),
                Text('Una uhakika unataka kufanya malipo haya?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ghairi'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                  /*  await FirebaseFirestore.instance
                        .collection('payments')
                        .add({
                          'bank': selectedBank!.name,
                          'owner': selectedBank!.owner,
                          'paymentNumber': selectedBank!.paymentNumber,
                          'accountNumber': _accountController.text,
                          'timestamp': FieldValue.serverTimestamp(),
                        });*/

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Malipo yamehifadhiwa kwenye Firebase!'),
                      ),
                    );

                    // Clear form
                    setState(() {
                      selectedBank = null;
                      _accountController.clear();
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hitilafu: ${e.toString()}')),
                    );
                  }
                },
                child: Text('Thibitisha'),
              ),
            ],
          ),
    );
  }
}

class Bank {
  final String name;
  final String image;
  final String paymentNumber;
  final String owner;

  Bank({
    required this.name,
    required this.image,
    required this.paymentNumber,
    required this.owner,
  });
}

class BankCard extends StatelessWidget {
  final Bank bank;
  final bool isSelected;
  final VoidCallback onTap;

  const BankCard({
    Key? key,
    required this.bank,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              isSelected
                  ? BorderSide(color: Colors.blue, width: 2)
                  : BorderSide.none,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              bank.image,
              height: 40,
              width: 40,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.account_balance, size: 40),
            ),
            SizedBox(height: 8),
            Text(
              bank.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
