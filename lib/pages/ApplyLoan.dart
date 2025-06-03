//import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';

class ApplyLoanPage extends StatefulWidget {
  const ApplyLoanPage({super.key});

  @override
  _ApplyLoanPageState createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final maxLoanAmount = 200000;
  final minLoanAmount = 10000;
  int availableLoan = 200000;
  int _selectedMonths = 1;
  double _interestRate = 15.0;
  double _totalRepayment = 0.0;
  double _monthlyPayment = 0.0;
  double _totalInterest = 0.0;
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  String? _userName;
  String? _userId;
  bool _showReceiptOptions = false;
  String? _receiptPath;
  String? _loanId;
  DateTime? _startDate;
  DateTime? _finishDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          availableLoan =
              (userDoc.data() as Map<String, dynamic>)['availableLoan'] ??
              200000;
          _userName = (userDoc.data() as Map<String, dynamic>)['firstName'];
        });
      }
    }
  }

  void _calculateRepayment() {
    if (_amountController.text.isEmpty) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount == 0) return;

    setState(() {
      // Calculate interest and payments
      _monthlyPayment = amount * 0.15;
      _totalInterest = _monthlyPayment * _selectedMonths;
      _totalRepayment = amount + _totalInterest;

      // Calculate dates
      _startDate = DateTime.now();
      _finishDate = _startDate!.add(Duration(days: 30 * _selectedMonths));
    });
  }

  Future<void> _submitLoanRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payment date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final amount = int.parse(_amountController.text.replaceAll(',', ''));
      final loanId = FirebaseFirestore.instance.collection('loans').doc().id;
      _loanId = loanId;

      await FirebaseFirestore.instance.collection('loans').doc(loanId).set({
        'loanId': loanId,
        'userId': user.uid,
        'userName': _userName,
        'amount': amount,
        'monthlyInterest': _monthlyPayment,
        'totalInterest': _totalInterest,
        'totalRepayment': _totalRepayment,
        'interestRate': _interestRate,
        'termMonths': _selectedMonths,
        'requestDate': DateTime.now(),
        'startDate': _startDate,
        'finishDate': _finishDate,
        'dueDate': _selectedDate,
        'status': 'pending',
        'isActive': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan application submitted successfully'),
        ),
      );

      final receiptPath = await _generateReceipt(loanId, amount);
      setState(() {
        _receiptPath = receiptPath;
        _showReceiptOptions = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<String> _generateReceipt(String loanId, int amount) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/loan_receipt_$loanId.pdf');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('Risiti ya Ombi la Mkopo')),
                pw.SizedBox(height: 20),
                pw.Text('Jina: $_userName'),
                pw.Text('Namba ya Ombi: $loanId'),
                pw.Divider(),

                // Loan Details
                pw.Text(
                  'MAELEZO YA MKOPO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kiasi cha Mkopo:'),
                    pw.Text('${NumberFormat('#,###').format(amount)} Tsh'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Muda wa Mkopo:'),
                    pw.Text('$_selectedMonths miezi'),
                  ],
                ),

                // Interest Details
                pw.SizedBox(height: 10),
                pw.Text(
                  'MAELEZO YA RIBA:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kiwango cha Ribaa:'),
                    pw.Text('15% kwa mwezi'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ribaa kwa mwezi:'),
                    pw.Text(
                      '${NumberFormat('#,###').format(_monthlyPayment)} Tsh',
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Jumla ya Ribaa:'),
                    pw.Text(
                      '${NumberFormat('#,###').format(_totalInterest)} Tsh',
                    ),
                  ],
                ),

                // Payment Summary
                pw.SizedBox(height: 10),
                pw.Text(
                  'MUHTASARI WA MALIPO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Jumla ya Kulipa:'),
                    pw.Text(
                      '${NumberFormat('#,###').format(_totalRepayment)} Tsh',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),

                // Payment Schedule
                pw.SizedBox(height: 20),
                pw.Text(
                  'RATIBA YA MALIPO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Tarehe ya Kuanza: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                ),
                pw.Text(
                  'Tarehe ya Kukamilika: ${DateFormat('dd/MM/yyyy').format(_finishDate!)}',
                ),

                // Payment Instructions
                pw.SizedBox(height: 20),
                pw.Text(
                  'MAELEKEZO YA MALIPO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '1. Malipo yanaanza siku moja baada ya mkopo kukubaliwa',
                ),
                pw.Text('2. Ribaa inakokotwa kila mwezi'),
                pw.Text('3. Unaweza kulipa mapema bila adhabu'),

                // Footer
                pw.SizedBox(height: 20),
                pw.Text('Imetolewa na:'),
                pw.Text('Kampuni Yetu ya Mikopo'),
                pw.Text(
                  'Tarehe: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                ),
              ],
            ),
      ),
    );

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chagua Tarehe ya Malipo'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SfDateRangePicker(
                minDate: DateTime.now().add(const Duration(days: 30)),
                maxDate: DateTime.now().add(const Duration(days: 365)),
                initialSelectedDate: DateTime.now().add(
                  Duration(days: 30 * _selectedMonths),
                ),
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is DateTime) {
                    setState(() {
                      _selectedDate = args.value;
                      _selectedMonths =
                          ((args.value as DateTime)
                                      .difference(DateTime.now())
                                      .inDays /
                                  30)
                              .ceil();
                      _calculateRepayment();
                    });
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Funga'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omba Mkopo'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!_showReceiptOptions) ...[
                // Loan Amount Input
                const Text(
                  'Kiasi cha Mkopo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Weka kiasi kati ya 10,000 - 200,000 Tsh',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.grey,
                    ),
                    suffixText: 'Tsh',
                    suffixStyle: const TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) => _calculateRepayment(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tafadhali weka kiasi cha mkopo';
                    }
                    final amount = int.tryParse(value.replaceAll(',', '')) ?? 0;
                    if (amount == 0) return 'Tafadhali weka nambari sahihi';
                    if (amount > maxLoanAmount)
                      return 'Kiasi hakizidi Tsh 200,000';
                    if (amount < minLoanAmount)
                      return 'Kiasi hakipungui Tsh 10,000';
                    if (amount > availableLoan)
                      return 'Kiasi kimezidi kile kilichobaki';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  "Unachoweza kukopa: ${NumberFormat('#,###').format(availableLoan)} Tsh",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Loan Term Selection
                const Text(
                  'Muda wa Mkopo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedMonths,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                  ),
                  items:
                      List.generate(12, (index) => index + 1)
                          .map(
                            (months) => DropdownMenuItem<int>(
                              value: months,
                              child: Text(
                                '$months Mwezi${months > 1 ? 's' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonths = value!;
                      _interestRate = 15.0 * _selectedMonths;
                      _calculateRepayment();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Payment Breakdown
                const Text(
                  'Maelezo ya Malipo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 113, 112, 112),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kiasi cha Mkopo:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)} Tsh',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ribaa:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(_monthlyPayment)} Tsh/mwezi',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumla ya Ribaa:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(_totalInterest)} Tsh',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumla ya Kulipa:',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(_totalRepayment)} Tsh',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Date Selection
                const Text(
                  'Tarehe ya Malipo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Chagua tarehe ya malipo',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitLoanRequest,
                    child:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Omba Mkopo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                  ),
                ),
              ] else ...[
                // Receipt Confirmation Section
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'Ombi Lako Limewasilishwa!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ombi lako la mkopo limepokelewa na linakaguliwa na timu yetu. '
                  'Utapokea ujumbe wa uthibitisho baada ya ombi lako kupitiwa.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Improved Loan ID Display with Copy Feature
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Namba ya Ombi:',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _loanId ?? '--',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Nakili Namba'),
                        onPressed: () {
                          if (_loanId != null) {
                            Clipboard.setData(ClipboardData(text: _loanId!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Namba imenakiliwa!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enhanced Loan Details Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Muhtasari wa Mkopo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Kiasi cha Mkopo:',
                        '${NumberFormat('#,###').format(int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)} Tsh',
                        Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Jumla ya Kulipa:',
                        '${NumberFormat('#,###').format(_totalRepayment)} Tsh',
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Tarehe ya Kuanza:',
                        _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '--',
                        Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Tarehe ya Kukamilika:',
                        _finishDate != null ? DateFormat('dd/MM/yyyy').format(_finishDate!) : '--',
                        Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.preview),
                        label: const Text('Ona Risiti'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (_receiptPath != null) {
                            OpenFile.open(_receiptPath!);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Shiriki'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _showShareOptions(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Rudi Nyumbani'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Shiriki Risiti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  'WhatsApp',
                  Icons.insert_chart,
                  Colors.green,
                  () => _shareViaWhatsApp(),
                ),
                _buildShareOption(
                  context,
                  'Bluetooth',
                  Icons.bluetooth,
                  Colors.blue,
                  () => _shareViaBluetooth(),
                ),
                _buildShareOption(
                  context,
                  'Zaidi',
                  Icons.more_horiz,
                  Colors.orange,
                  () => _shareViaOtherApps(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _shareViaWhatsApp() async {
    final text = 'Namba yangu ya ombi la mkopo ni: $_loanId\n'
        'Kiasi: ${NumberFormat('#,###').format(int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)} Tsh\n'
        'Jumla ya Kulipa: ${NumberFormat('#,###').format(_totalRepayment)} Tsh';
    
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(text)}";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp haipo kwenye simu yako')),
      );
    }
  }

  void _shareViaBluetooth() async {
    if (_receiptPath != null) {
      final result = await Share.shareXFiles(
        [XFile(_receiptPath!)],
        text: 'Risiti ya ombi la mkopo',
      );
      
      if (result.status == ShareResultStatus.dismissed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kushiriki kumeghairiwa')),
        );
      }
    }
  }

  void _shareViaOtherApps() async {
    if (_receiptPath != null) {
      await Share.shareXFiles(
        [XFile(_receiptPath!)],
        text: 'Risiti ya ombi la mkopo: $_loanId',
      );
    } else {
      final text = 'Namba yangu ya ombi la mkopo ni: $_loanId\n'
          'Kiasi: ${NumberFormat('#,###').format(int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)} Tsh\n'
          'Jumla ya Kulipa: ${NumberFormat('#,###').format(_totalRepayment)} Tsh';
      
      await Share.share(text);
    }
  }
}
