import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuyCable extends StatefulWidget {
  const BuyCable({Key? key}) : super(key: key);

  @override
  State<BuyCable> createState() => _BuyCableState();
}

class _BuyCableState extends State<BuyCable> {
  final TextEditingController _decoderController = TextEditingController();
  String _selectedCableType = '';
  String _selectedPlan = '';
  bool _showDetails = false;
  bool beneficiary_toggle = false;
  String _customerName = '';
  double _amount = 0;
  String _bouquet = '';
  String _status = '';
  bool _showPurchasedCode = false;

  List<Map<String, dynamic>> _availablePlans = [];
  Map<String, dynamic>? _selectedPlanDetails;
  bool _isLoadingPlans = false;

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

  final List<Map<String, String>> _cableTypes = [
    {"value": "01", "label": "DSTV"},
    {"value": "02", "label": "GOTV"},
    {"value": "03", "label": "STARTIMES"},
  ];

  Future<void> _fetchAvailablePlans() async {
    if (_selectedCableType.isEmpty) return;

    setState(() {
      _isLoadingPlans = true;
      _availablePlans = [];
      _selectedPlanDetails = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
            'https://vtubiz.com/api/purchase/fetch_cable_plan/$_selectedCableType'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      print(data);
      setState(() {
        _availablePlans = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print('Error fetching plans: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load available plans'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingPlans = false;
      });
    }
  }

  void updateBeneficiaryToggle(bool value) {
    setState(() {
      beneficiary_toggle = value;
    });
  }

  Future<void> _fetchDecoderDetails() async {
    if (_selectedCableType.isEmpty || _decoderController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all necessary fields')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/purchase/fetch_decoder_details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cable_type': _selectedCableType,
          'decoder_number': _decoderController.text,
        }),
      );

      final data = jsonDecode(response.body);
      print(data);
      if (data['success'].toString() == 'true' && data['message'] != null) {
        final content = data['message']['content'] as Map<String, dynamic>;
        setState(() {
          _showDetails = true;
          _customerName = content['Customer_Name']?.toString() ?? '';
          _bouquet = content['Current_Bouquet']?.toString() ?? '';
          _status = content['Status']?.toString() ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch decoder details. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _buyCable(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/purchase/buyCable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cable_type': _selectedCableType,
          'decoder_number': _decoderController.text,
          'plan': _selectedPlan,
          'amount': _amount,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);
      print(data);

      if (data['success'].toString() == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription successful!'),
            backgroundColor: Colors.green,
          ),
        );

        _showResultDialog(
          'Subscription Successful!',
          'Your subscription has been completed successfully.',
          true,
        );
      } else {
        _showResultDialog(
          'Transaction Failed',
          data['message']?.toString() ?? 'Transaction failed',
          false,
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Network error. Please check your connection and try again.'),
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
          'Buy Cable TV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF001f3e),
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF001f3e),
              height: 5,
              width: double.infinity,
            ),
            Padding(
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
                          Row(
                            children: [
                              
                              BeneficiarySelector(
                                type: 'cable',
                                phoneController: _decoderController,
                                isToggled: beneficiary_toggle,
                                updateToggle: updateBeneficiaryToggle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCableType.isEmpty
                                ? null
                                : _selectedCableType,
                            decoration: InputDecoration(
                              labelText: 'Cable Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _cableTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(type['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCableType = value!;
                                _selectedPlan = '';
                                _selectedPlanDetails = null;
                              });
                              _fetchAvailablePlans();
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _decoderController,
                            decoration: InputDecoration(
                              labelText: 'Decoder Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          BeneficiaryToggle(
                            phone: _decoderController.text.trim(),
                            isToggled: beneficiary_toggle,
                            updateToggle: updateBeneficiaryToggle,
                            type: 'cable',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showDetails) ...[
                    const SizedBox(height: 16),
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
                              'Customer Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.person,
                                  color: Color(0xFF001f3e)),
                              title: const Text('Customer Name'),
                              subtitle: Text(_customerName),
                            ),
                            ListTile(
                              leading: const Icon(Icons.tv,
                                  color: Color(0xFF001f3e)),
                              title: const Text('Current Bouquet'),
                              subtitle: Text(_bouquet),
                            ),
                            ListTile(
                              leading: const Icon(
                                  Icons.signal_wifi_statusbar_4_bar_outlined,
                                  color: Color(0xFF001f3e)),
                              title: const Text('Status'),
                              subtitle: Text(_status),
                            ),
                            const SizedBox(height: 16),
                            if (_availablePlans.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Select Plan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: _selectedPlan.isEmpty
                                            ? null
                                            : _selectedPlan,
                                        decoration: InputDecoration(
                                          labelText: 'Available Plans',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                        items: _availablePlans.map((plan) {
                                          return DropdownMenuItem(
                                            value: plan['plan_id'].toString(),
                                            child: Text(
                                                '${plan['plan_name']} - ₦${plan['admin_price']}'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPlan = value ?? '';
                                            _selectedPlanDetails =
                                                _availablePlans.firstWhere(
                                              (plan) =>
                                                  plan['plan_id'].toString() ==
                                                  value,
                                              orElse: () => {},
                                            );
                                            _amount = double.tryParse(
                                                    _selectedPlanDetails?[
                                                                'admin_price']
                                                            .toString() ??
                                                        '0') ??
                                                0;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                      onPressed: _showDetails
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (context) => InputPin(
                                  onProceed: (pin) => _buyCable(pin),
                                  onCancel: () {
                                    // if (mounted) Navigator.of(context).pop();
                                  },
                                ),
                              );
                            }
                          : _fetchDecoderDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001f3e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _showDetails ? 'Subscribe Now' : 'Confirm Details',
                        style: const TextStyle(
                          fontSize: 16,
                          color : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
}
