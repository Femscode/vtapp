import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vtubiz/config.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class BuyElectricity extends StatefulWidget {
  const BuyElectricity({Key? key}) : super(key: key);

  @override
  State<BuyElectricity> createState() => _BuyElectricityState();
}

class _BuyElectricityState extends State<BuyElectricity> {
  final TextEditingController _meterController = TextEditingController();
  final FocusNode _meterFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  bool _meterHasFocus = false;
  bool _amountHasFocus = false;

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
  bool _isLoadingDetails = false;
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

  @override
  void initState() {
    super.initState();
    _meterFocusNode.addListener(() {
      setState(() {
        _meterHasFocus = _meterFocusNode.hasFocus;
      });
    });
    _amountFocusNode.addListener(() {
      setState(() {
        _amountHasFocus = _amountFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _meterFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (!mounted) return;

    Future.microtask(() {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF001f3e).withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF001f3e),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            foregroundColor: const Color(0xFF001f3e),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF001f3e).withOpacity(0.4),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00D2FF),
                            ),
                            backgroundColor: const Color(0xFF00D2FF).withOpacity(0.15),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF001f3e).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            color: Color(0xFF001f3e),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001f3e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please do not close this window or press back.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
    _showProcessingDialog('Verifying Meter Details');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${AppConfig.liveUrl}/purchase/fetch_meter_details'),
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

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss verification loader
      }

      final data = jsonDecode(response.body);
      if (data['success'].toString() == 'true' && data['message'] != null) {
        final content = data['message']['content'] as Map<String, dynamic>;
        setState(() {
          _showDetails = true;
          _customerName = content['Customer_Name']?.toString() ?? '';
          _customerAddress = content['Address']?.toString() ?? '';
          _customerArrears = content['Customer_Arrears']?.toString() ?? '0.00';
        });
      } else {
        _showResultDialog(
          'Verification Failed',
          'Could not fetch meter details. Please verify and try again.',
          false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss verification loader
      }
      _showResultDialog(
        'Error',
        'An error occurred. Please check your network and try again.',
        false,
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
    _showProcessingDialog('Processing Purchase');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${AppConfig.liveUrl}/purchase/buyElectricity'),
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

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loader
      }

      final data = jsonDecode(response.body);

      if (data['success'].toString() == 'true' && data['message'] != null) {
        final content = data['message']['content'] as Map<String, dynamic>;
        setState(() {
          _showPurchasedCode = true;
          _purchasedCode = content['token'] ?? content['purchased_code'] ?? 'N/A';

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

        _showResultDialog(
          'Success',
          'Token purchase successful!',
          true,
        );
      } else {
        String errorMessage = data['message']?.toString() ?? 'Transaction failed. Please try again.';
        _showResultDialog(
          'Transaction Failed',
          errorMessage,
          false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loader
      }
      _showResultDialog(
        'Error',
        'Network error. Please check your connection and try again.',
        false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF001f3e),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_amount <= 0) return const SizedBox.shrink();

    String serviceName = 'Unknown';
    for (var service in _serviceTypes) {
      if (service['value'] == _selectedServiceType) {
        serviceName = service['label']!;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF00D2FF).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2FF).withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRANSACTION SUMMARY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF001f3e).withOpacity(0.4),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D2FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Swipe to Confirm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0088CC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF001f3e).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  color: Color(0xFF001f3e),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001f3e),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Meter: ${_meterController.text}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            color: const Color(0xFF001f3e).withOpacity(0.06),
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _customerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF001f3e),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meter Type',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _selectedMeterType == '01' ? 'Prepaid' : 'Postpaid',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF001f3e),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount to Pay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₦$_amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  color: const Color(0xFF00D2FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SlideToConfirm(
                  text: 'Slide to Purchase',
                  isEnabled: !_isProcessingPurchase,
                  onConfirm: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => InputPin(
                        onProceed: (pin) {
                          Navigator.of(context).pop();
                          _buyElectricity(pin);
                        },
                        onCancel: () {},
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Schedule functionality mock or trigger
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF001f3e).withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF001f3e),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buy Later',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF001f3e).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF001f3e).withOpacity(0.06),
            height: 1.0,
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF001f3e)),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        title: Text(
          'Buy Electricity Token',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF001f3e),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background mesh gradient circles
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D2FF).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF001f3e).withOpacity(0.03),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_showDetails) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF001f3e).withOpacity(0.06),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001f3e).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.electric_bolt_rounded,
                                      color: Color(0xFF001f3e),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Meter Details',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF001f3e),
                                    ),
                                  ),
                                ],
                              ),
                              BeneficiarySelector(
                                type: 'electricity',
                                phoneController: _meterController,
                                isToggled: beneficiary_toggle,
                                updateToggle: updateBeneficiaryToggle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedServiceType.isEmpty
                                ? null
                                : _selectedServiceType,
                            decoration: InputDecoration(
                              labelText: 'Select Distributor',
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFF001f3e).withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00D2FF),
                                  width: 1.8,
                                ),
                              ),
                            ),
                            items: _serviceTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(
                                  type['label']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF001f3e),
                                  ),
                                ),
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
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFF001f3e).withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00D2FF),
                                  width: 1.8,
                                ),
                              ),
                            ),
                            items: _meterTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(
                                  type['label']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF001f3e),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMeterType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (_meterHasFocus)
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withOpacity(0.12),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: TextField(
                              controller: _meterController,
                              focusNode: _meterFocusNode,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: const Color(0xFF001f3e),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter meter number',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                filled: true,
                                fillColor: _meterHasFocus ? Colors.white : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF001f3e).withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00D2FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _fetchMeterDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001f3e),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Confirm Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
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
                  if (_showDetails) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF001f3e).withOpacity(0.06),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Information',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Name', _customerName),
                          _buildInfoRow('Address', _customerAddress),
                          _buildInfoRow('Arrears', '₦$_customerArrears'),
                          const SizedBox(height: 20),
                          Text(
                            'Enter Amount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001f3e).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (_amountHasFocus)
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withOpacity(0.12),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: TextField(
                              focusNode: _amountFocusNode,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: const Color(0xFF001f3e),
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter amount to purchase',
                                prefixText: '₦ ',
                                prefixStyle: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF001f3e),
                                ),
                                filled: true,
                                fillColor: _amountHasFocus ? Colors.white : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF001f3e).withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00D2FF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _amount = double.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          BeneficiaryToggle(
                            phone: _meterController.text.trim(),
                            isToggled: beneficiary_toggle,
                            updateToggle: updateBeneficiaryToggle,
                            type: 'electricity',
                          ),
                        ],
                      ),
                    ),
                    _buildSummaryCard(),
                  ],
                  if (_showPurchasedCode) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF001f3e), Color(0xFF0A3663)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF001f3e).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.vpn_key_rounded, color: Color(0xFF00D2FF), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Your Token / Details',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _purchasedCode,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SlideToConfirm custom slider widget
class SlideToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  final bool isEnabled;

  const SlideToConfirm({
    Key? key,
    required this.onConfirm,
    required this.text,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - 56.0 - 8.0;
        return Container(
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.isEnabled ? const Color(0xFF001f3e).withOpacity(0.04) : Colors.grey[200],
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: widget.isEnabled ? const Color(0xFF001f3e).withOpacity(0.08) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.isEnabled ? const Color(0xFF001f3e).withOpacity(0.6) : Colors.grey[400],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: _dragPosition == 0.0 || _isConfirmed ? 200 : 0),
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.isEnabled || _isConfirmed) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!widget.isEnabled || _isConfirmed) return;
                    if (_dragPosition >= maxDrag * 0.85) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirm();
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                            _isConfirmed = false;
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF001f3e), Color(0xFF0A3663)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF001f3e).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
