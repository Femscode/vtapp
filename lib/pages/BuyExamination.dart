import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuyExamination extends StatefulWidget {
  const BuyExamination({Key? key}) : super(key: key);

  @override
  State<BuyExamination> createState() => _BuyExaminationState();
}

class _BuyExaminationState extends State<BuyExamination> {
  // Selected exam details
  Map<String, dynamic>? _selectedExam;
  int _numberOfPins = 1;
  double _totalAmount = 0;

  // UI states
  bool _showPurchasedPins = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Data
  List<Map<String, dynamic>> _examinations = [];
  List<String> _purchasedPins = [];
  String _purchasedCode = ''; // Add this line for single token
  bool _showPurchasedCode = false; // A

  @override
  void initState() {
    super.initState();
    _fetchExamTypes();
  }

  Future<void> _fetchExamTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://vtubiz.com/api/purchase/get_exam_types'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      setState(() {
        _examinations = List<Map<String, dynamic>>.from(data['examinations']);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _calculateTotalAmount() {
    if (_selectedExam != null) {
      setState(() {
        _totalAmount = double.parse(_selectedExam!['real_amount'].toString()) *
            _numberOfPins;
      });
    }
  }

  Future<void> _buyExamination(String pin) async {
    try {
      if (_selectedExam == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/purchase/buyExamination'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'exam_type': _selectedExam!['exam_type'],
          'no_of_pins': _numberOfPins,
          'amount': _totalAmount,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);
      print(data);

      if (data['success'].toString() == 'true') {
        setState(() {
          _showPurchasedCode = true;
          _purchasedCode = data['purchased_code'] ?? ''; // Update this line

          // _showPurchasedPins = true;
          // _purchasedPins = List<String>.from(data['pins'] ?? []);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } 
       else if (data['success'].toString() == 'false') {
        // Handle specific error codes
        String errorMessage = 'Transaction failed: ';

        errorMessage += data['message'].toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Transaction failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buy Examination Pin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF001f3e),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Examination Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<Map<String, dynamic>>(
                                  value: _selectedExam,
                                  decoration: InputDecoration(
                                    labelText: 'Exam Type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _examinations.map((exam) {
                                    return DropdownMenuItem(
                                      value: exam,
                                      child: Text(exam['exam_type']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedExam = value;
                                      _calculateTotalAmount();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<int>(
                                  value: _numberOfPins,
                                  decoration: InputDecoration(
                                    labelText: 'Number of Pins',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: List.generate(10, (index) => index + 1)
                                      .map((number) {
                                    return DropdownMenuItem(
                                      value: number,
                                      child: Text(number.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _numberOfPins = value!;
                                      _calculateTotalAmount();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: const Icon(Icons.attach_money),
                                  ),
                                  controller: TextEditingController(
                                    text: _totalAmount.toString(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showPurchasedCode &&
                            _purchasedCode.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            color: const Color(0xFF001f3e),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Your Token',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _purchasedCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _selectedExam != null
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        title: const Text('Enter PIN'),
                                        content: InputPin(
                                          onProceed: (pin) {
                                            // Navigator.of(context).pop();
                                            _buyExamination(pin);
                                          },
                                          onCancel: () {
                                            // Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001f3e),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
