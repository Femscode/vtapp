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
  bool _isProcessingPurchase = false;
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

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (!mounted) return;

    Future.microtask(() {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001f3e),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? Colors.green : const Color(0xFF001f3e),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
    setState(() {
      _isProcessingPurchase = true;
    });
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

        _showResultDialog(
          'Purchase Successful!',
          'Click OK to view your purchased pins',
          true,
        );
      } else if (data['success'].toString() == 'false') {
        // Handle specific error codes
        String errorMessage = 'Transaction failed: ';
        errorMessage += data['message'].toString();
        _showResultDialog(
          'Transaction Failed',
          errorMessage,
          false,
        );
      } else {
        _showResultDialog(
          'Transaction Failed',
          data['message'] ?? 'Transaction failed',
          false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                          color : Colors.white,
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
                                    prefixIcon: const Icon(Icons.money),
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
                            onPressed:
                                (_isProcessingPurchase || _selectedExam == null)
                                    ? null
                                    : () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          builder: (context) => InputPin(
                                            onProceed: (pin) =>
                                                _buyExamination(pin),
                                            onCancel: () {
                                              // if (mounted) Navigator.of(context).pop();
                                            },
                                          ),
                                        );
                                      },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001f3e),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isProcessingPurchase
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
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
