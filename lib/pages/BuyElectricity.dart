import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuyElectricity extends StatefulWidget {
  const BuyElectricity({Key? key}) : super(key: key);

  @override
  State<BuyElectricity> createState() => _BuyElectricityState();
}

class _BuyElectricityState extends State<BuyElectricity> {
  final TextEditingController _meterController = TextEditingController();
  String _selectedServiceType = '';
  String _selectedMeterType = '';
  bool _showDetails = false;
  bool beneficiary_toggle = false;
  String _customerName = '';
  String _customerAddress = '';
  String _customerArrears = '';
  double _amount = 0;
  String _purchasedCode = '';
  bool _showPurchasedCode = false;
  bool _isLoadingDetails = false; // Add this
  bool _isProcessingPurchase = false;

  final List<Map<String, String>> _serviceTypes = [
    {"value": "01", "label": "Eko Electricity - EKEDC(PHCN)"},
    {"value": "02", "label": "Ikeja Electricity - IKEDC(PHCN)"},
    {"value": "03", "label": "PortHarcourt Electricity - PHEDC"},
    {"value": "04", "label": "Kaduna Electricity - KAEDC"},
    {"value": "05", "label": "Abuja Electricity - AEDC"},
    {"value": "06", "label": "Ibadan Electricity - IBEDC"},
    {"value": "07", "label": "Kano Electricity - KEDC"},
    {"value": "08", "label": "Jos Electricity - JEDC"},
    {"value": "09", "label": "Enugu Electricity - EEDC"},
    {"value": "10", "label": "Benin Electricity - BEDC"},
  ];

  final List<Map<String, String>> _meterTypes = [
    {"value": "01", "label": "Prepaid"},
    {"value": "02", "label": "Postpaid"},
  ];

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

  void updateBeneficiaryToggle(bool value) {
    setState(() {
      beneficiary_toggle = value;
    });
  }

  Future<void> _fetchMeterDetails() async {
    if (_selectedServiceType.isEmpty ||
        _selectedMeterType.isEmpty ||
        _meterController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all necessary fields')),
      );
      return;
    }
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/purchase/fetch_meter_details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_type': _selectedServiceType,
          'meter_type': _selectedMeterType,
          'meter_number': _meterController.text,
        }),
      );

      // ... existing code ...

      final data = jsonDecode(response.body);
      print(data);
      if (data['success'].toString() == 'true' && data['message'] != null) {
        final content = data['message']['content'] as Map<String, dynamic>;
        setState(() {
          _showDetails = true;
          _customerName = content['Customer_Name']?.toString() ?? '';
          _customerAddress = content['Address']?.toString() ?? '';
          _customerArrears = content['Customer_Arrears']?.toString() ?? '0.00';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Could not fetch meter details. Please try again.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please try again later.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _buyElectricity(String pin) async {
    setState(() {
      _isProcessingPurchase = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/purchase/buyElectricity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'company': _selectedServiceType,
          'meter_type': _selectedMeterType,
          'meter_number': _meterController.text,
          'amount': _amount,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);
      print(data); // For debugging

      if (data['success'].toString() == 'true' && data['message'] != null) {
        final content = data['message']['content'] as Map<String, dynamic>;
        setState(() {
          _showPurchasedCode = true;
          _purchasedCode =
              content['token'] ?? content['purchased_code'] ?? 'N/A';

          // Store additional details if available
          if (content['unit'] != null) {
            _purchasedCode += '\nUnits: ${content['unit']}';
          }
          if (content['tariff'] != null) {
            _purchasedCode += '\nTariff: ${content['tariff']}';
          }
          if (content['address'] != null) {
            _purchasedCode += '\nAddress: ${content['address']}';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token Purchase successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _showResultDialog(
          'Your Token Purchase Was Successful',
          'Click OK to view token!',
          true,
        );
      } else if (data['success'].toString() == 'false') {
        // Handle specific error codes
        String errorMessage = 'Transaction failed: ';

        errorMessage += data['message'].toString();

        _showResultDialog(
          'Transaction Failed',
          errorMessage ?? 'Transaction failed. Please try again.',
          false,
        );
      } else if (data['message'] != null && data['message']['code'] != null) {
        // Handle specific error codes
        String errorMessage = 'Transaction failed: ';
        switch (data['message']['code'].toString()) {
          case '000':
            errorMessage += 'Invalid PIN';
            break;
          case '001':
            errorMessage += 'Insufficient balance';
            break;
          case '002':
            errorMessage += 'Invalid meter number';
            break;
          default:
            errorMessage += data['message']['content']?.toString() ??
                data['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Transaction failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Network error. Please check your connection and try again.'),
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
          'Buy Electricity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF001f3e),
        // elevation: 0,
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
                    color: Colors.white,
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
                                type: 'electricity',
                                phoneController: _meterController,
                                isToggled: beneficiary_toggle,
                                updateToggle: updateBeneficiaryToggle,
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedServiceType.isEmpty
                                ? null
                                : _selectedServiceType,
                            decoration: InputDecoration(
                              labelText: 'Service Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _serviceTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(type['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedServiceType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedMeterType.isEmpty
                                ? null
                                : _selectedMeterType,
                            decoration: InputDecoration(
                              labelText: 'Meter Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _meterTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(type['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMeterType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _meterController,
                            decoration: InputDecoration(
                              labelText: 'Meter Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_showDetails) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
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
                              leading: const Icon(Icons.location_on,
                                  color: Color(0xFF001f3e)),
                              title: const Text('Address'),
                              subtitle: Text(_customerAddress),
                            ),
                            ListTile(
                              leading: const Icon(Icons.account_balance_wallet,
                                  color: Color(0xFF001f3e)),
                              title: const Text('Arrears'),
                              subtitle: Text(_customerArrears),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _amount = double.tryParse(value) ?? 0;
                                });
                              },
                            ),
                            BeneficiaryToggle(
                              phone: _meterController.text.trim().isEmpty
                                  ? ''
                                  : _meterController.text.trim(),
                              isToggled: beneficiary_toggle,
                              updateToggle: updateBeneficiaryToggle,
                              type: 'electricity',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_showPurchasedCode) ...[
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
                      onPressed: (_isLoadingDetails || _isProcessingPurchase)
                          ? null
                          : _showDetails
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) => InputPin(
                                      onProceed: (pin) => _buyElectricity(pin),
                                      onCancel: () {
                                        // if (mounted) Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                }
                              : _fetchMeterDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001f3e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoadingDetails || _isProcessingPurchase
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _showDetails ? 'Buy Token' : 'Confirm Details',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
