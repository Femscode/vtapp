import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/FetchPlan.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/component/purchase/NetworkSelect.dart';
import 'package:vtubiz/component/purchase/RecentTransactions.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vtubiz/config.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';


class BuyData extends StatefulWidget {
  const BuyData({Key? key}) : super(key: key);

  @override
  State<BuyData> createState() => _BuyDataState();
}

class _BuyDataState extends State<BuyData> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _phoneHasFocus = false;
  int? _selectedNetwork;
  Map<String, dynamic>? _selectedPlan;
  bool beneficiary_toggle = false;
  String _phone = '';
  bool isSelected = false;
  bool _isProcessing = false;

  String normalizePhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+234')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('234')) {
      phone = '0${phone.substring(3)}';
    }
    return phone;
  }

  void detectAndSelectNetwork(String phoneNumber) {
    if (phoneNumber.isEmpty) return;

    String normalizedNumber = normalizePhoneNumber(phoneNumber);
    if (normalizedNumber.length >= 4) {
      String prefix = normalizedNumber.substring(0, 4);

      int? detectedNetwork;
      if (RegExp(r'^0(703|706|803|806|810|813|814|903|904|906)').hasMatch(prefix)) {
        detectedNetwork = 1;
      } else if (RegExp(r'^0(705|805|807|811|815|905)').hasMatch(prefix)) {
        detectedNetwork = 2;
      } else if (RegExp(r'^0(701|708|802|808|902)').hasMatch(prefix)) {
        detectedNetwork = 3;
      } else if (RegExp(r'^0(809|817|818|908|909)').hasMatch(prefix)) {
        detectedNetwork = 4;
      }

      if (detectedNetwork != null && detectedNetwork != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detectedNetwork;
          isSelected = true;
          _selectedPlan = null; // Clear plan if network switches
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _phone = _phoneController.text;
        detectAndSelectNetwork(_phone);
      });
    });

    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneHasFocus = _phoneFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void updateBeneficiaryToggle(bool value) {
    setState(() {
      beneficiary_toggle = value;
    });
  }

  void selectNetwork(String name, int id) {
    if (mounted) {
      setState(() {
        _selectedNetwork = id;
        isSelected = true;
        _selectedPlan = null; // Reset plan selection on network change
      });
    }
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

  void _showProcessingDialog() {
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
                      'Processing Transaction',
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

  Future<void> _handleDataPurchase({
    required String pin,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });
    _showProcessingDialog();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final Map<String, dynamic> requestBody = {
        'phone_number': _phoneController.text,
        'network': _selectedNetwork,
        'plan': _selectedPlan?['plan_id'],
        'pin': pin,
      };

      if (scheduledDate != null && scheduledTime != null) {
        requestBody['selectedDate'] = scheduledDate.toString().split(' ')[0];
        requestBody['selectedTime'] =
            '${scheduledTime.hour}:${scheduledTime.minute}';
      }

      final response = await http.post(
        Uri.parse('${AppConfig.liveUrl}/purchase/buydata'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      if (!mounted) return;
      final responseData = jsonDecode(response.body);

      if (scheduledDate != null && scheduledTime != null) {
        if (responseData == "schedule_saved") {
          _showResultDialog(
            'Success',
            'Purchase scheduled successfully!',
            true,
          );
        } else {
          _showResultDialog(
            'Schedule Failed',
            'Failed to schedule purchase. Please try again.',
            false,
          );
        }
      } else {
        if (response.statusCode == 200) {
          if (responseData['success'].toString() == 'true') {
            _showResultDialog(
              'Success',
              responseData['message'] ?? 'Purchase Successful!',
              true,
            );
          } else {
            _showResultDialog(
              'Transaction Failed',
              responseData['message'] ??
                  'Transaction failed. Please try again.',
              false,
            );
          }
        } else {
          _showResultDialog(
            'Network Error',
            'Failed to connect to server. Please check your connection and try again.',
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.of(context).pop(); // Dismiss loading dialog
      }

      if (!mounted) return;

      _showResultDialog(
        'Error',
        'An unexpected error occurred. Please try again later.',
        false,
      );
    }
  }

  Future<void> _showPinInputModal({
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    if (_phoneController.text.isEmpty ||
        _selectedPlan == null ||
        _selectedNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => InputPin(
        onProceed: (pin) => _handleDataPurchase(
          pin: pin,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
        ),
        onCancel: () {},
      ),
    );
  }

  Future<void> _schedulePurchase() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF001f3e),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF001f3e),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && mounted) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: const Color(0xFF001f3e),
                dialHandColor: const Color(0xFF001f3e),
                dialBackgroundColor: const Color(0xFF001f3e).withOpacity(0.1),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF001f3e),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null && mounted) {
        _showPinInputModal(
          scheduledDate: selectedDate,
          scheduledTime: selectedTime,
        );
      }
    }
  }

  Widget _buildSummaryCard() {
    final plan = _selectedPlan;
    if (plan == null) return const SizedBox.shrink();

    String networkName = 'Unknown';
    String networkLogo = 'assets/mtn.png';
    if (_selectedNetwork == 1) {
      networkName = 'MTN';
      networkLogo = 'assets/mtn.png';
    } else if (_selectedNetwork == 2) {
      networkName = 'GLO';
      networkLogo = 'assets/glo.png';
    } else if (_selectedNetwork == 3) {
      networkName = 'Airtel';
      networkLogo = 'assets/airtel.webp';
    } else if (_selectedNetwork == 4) {
      networkName = '9mobile';
      networkLogo = 'assets/nmobile.png';
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
              ClipOval(
                child: Image.asset(
                  networkLogo,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['plan_name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001f3e),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recipient: ${_phoneController.text}',
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
                'Operator',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                networkName,
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
                'Validity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                plan['validity'] ?? '30 Days',
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
                '₦${plan['admin_price']}',
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
                  isEnabled: !_isProcessing,
                  onConfirm: () => _showPinInputModal(),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isProcessing ? null : _schedulePurchase,
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
          'Buy Data Bundle',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF001f3e),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF001f3e)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text(
                    'Data Bundle Info',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF001f3e),
                    ),
                  ),
                  content: Text(
                    'Purchase data bundles for any network. You can buy for yourself or others.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[700],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF001f3e),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            splashRadius: 24,
          ),
        ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecentTransactions(
                        recentType: 'Data Purchase',
                      ),
                      const SizedBox(height: 20),

                      // Card 1: Select Network
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
                                        Icons.sim_card_rounded,
                                        color: Color(0xFF001f3e),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Select Network',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF001f3e),
                                      ),
                                    ),
                                  ],
                                ),
                                BeneficiarySelector(
                                  type: 'data',
                                  phoneController: _phoneController,
                                  isToggled: beneficiary_toggle,
                                  updateToggle: updateBeneficiaryToggle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: NetworkSelect(
                                    imageUrl: 'assets/mtn.png',
                                    name: 'MTN',
                                    isSelected: _selectedNetwork == 1,
                                    onTap: () => selectNetwork('MTN', 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: NetworkSelect(
                                    imageUrl: 'assets/glo.png',
                                    name: 'GLO',
                                    isSelected: _selectedNetwork == 2,
                                    onTap: () => selectNetwork('GLO', 2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: NetworkSelect(
                                    imageUrl: 'assets/airtel.webp',
                                    name: 'Airtel',
                                    isSelected: _selectedNetwork == 3,
                                    onTap: () => selectNetwork('Airtel', 3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: NetworkSelect(
                                    imageUrl: 'assets/nmobile.png',
                                    name: '9mobile',
                                    isSelected: _selectedNetwork == 4,
                                    onTap: () => selectNetwork('9mobile', 4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card 2: Phone Number Input Card
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
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001f3e).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.phone_rounded,
                                    color: Color(0xFF001f3e),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Phone Number',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF001f3e),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (_phoneHasFocus)
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
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  color: const Color(0xFF001f3e),
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter phone number',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: _phoneHasFocus ? Colors.white : const Color(0xFFF8FAFC),
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
                            const SizedBox(height: 12),
                            BeneficiaryToggle(
                              phone: _phone,
                              isToggled: beneficiary_toggle,
                              updateToggle: updateBeneficiaryToggle,
                              type: 'data',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card 3: Select Plan
                      if (isSelected)
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
                                          Icons.keyboard_option_key,
                                          color: Color(0xFF001f3e),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Select Plan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF001f3e),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D2FF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_offer_rounded,
                                          size: 14,
                                          color: Color(0xFF0088CC),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Available Plans',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: const Color(0xFF0088CC),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              FetchPlan(
                                type: 'data',
                                network: _selectedNetwork ?? 1,
                                onPlanSelected: (plan) {
                                  setState(() {
                                    _selectedPlan = plan;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      // Card 4: Summary Card and slide action
                      if (isSelected && _selectedPlan != null)
                        _buildSummaryCard(),
                    ],
                  ),
                ),
              );
            },
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
