import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/FetchPlan.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/component/purchase/NetworkSelect.dart';
import 'package:vtubiz/component/purchase/RecentTransactions.dart';
import 'package:vtubiz/component/purchase/SelectTime.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class BuyData extends StatefulWidget {
  const BuyData({Key? key}) : super(key: key);

  @override
  State<BuyData> createState() => _BuyDataState();
}

class _BuyDataState extends State<BuyData> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  int? _selectedNetwork;
  Map<String, dynamic>? _selectedPlan;
  bool beneficiary_toggle = false;
  String _phone = '';
  bool isSelected = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Add this function to normalize phone number
  String normalizePhoneNumber(String phone) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Convert +234 to 0
    if (phone.startsWith('+234')) {
      phone = '0${phone.substring(4)}';
    }
    // Convert 234 to 0
    else if (phone.startsWith('234')) {
      phone = '0${phone.substring(3)}';
    }

    return phone;
  }

  void detectAndSelectNetwork(String phoneNumber) {
    if (phoneNumber.isEmpty) return;

    String normalizedNumber = normalizePhoneNumber(phoneNumber);
    if (normalizedNumber.length >= 4) {
      String prefix = normalizedNumber.substring(0, 4);

      setState(() {
        // MTN prefixes
        if (RegExp(r'^0(703|706|803|806|810|813|814|903|904|906)')
            .hasMatch(prefix)) {
          _selectedNetwork = 1;
          isSelected = true;
        }
        // GLO prefixes
        else if (RegExp(r'^0(705|805|807|811|815|905)').hasMatch(prefix)) {
          _selectedNetwork = 2;
          isSelected = true;
        }
        // Airtel prefixes
        else if (RegExp(r'^0(701|708|802|808|902)').hasMatch(prefix)) {
          _selectedNetwork = 3;
          isSelected = true;
        }
        // 9mobile prefixes
        else if (RegExp(r'^0(809|817|818|908|909)').hasMatch(prefix)) {
          _selectedNetwork = 4;
          isSelected = true;
        }
      });
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
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
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

  // Add this state variable at the top of the class
  bool _isProcessing = false;

  Future<void> _handleDataPurchase({
    required String pin,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    // Show loading dialog

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
        Uri.parse('https://vtubiz.com/api/purchase/buydata'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      // Update state before showing result
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Navigator.of(context).pop(); // Close loading dialog
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
      // ... existing response handling code ...
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Navigator.of(context).maybePop();
      }

      if (!mounted) return;

      _showResultDialog(
        'Error',
        'An unexpected error occurred. Please try again later.',
        false,
      );
    }
  }

  // Then update the buttons in the build method

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InputPin(
        onProceed: (pin) => _handleDataPurchase(
          pin: pin,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
        ),
        onCancel: () {
          // if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF001f3e),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF001f3e),
          statusBarIconBrightness: Brightness.light,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        title: const Text(
          'Buy Data Bundle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () {
              // Show info dialog about data bundles
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Bundle Info'),
                  content: const Text('Purchase data bundles for any network. You can buy for yourself or others.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: Color(0xFF001f3e))),
                    ),
                  ],
                ),
              );
            },
            splashRadius: 24,
          ),
        ],
      ),
      body: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF001f3e).withOpacity(0.05),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RecentTransactions(
                      recentType: 'Data Purchase',
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF001f3e).withOpacity(0.05),
                            const Color(0xFF001f3e).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Network Selection Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  // 👈 makes this section shrink/wrap properly
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF001f3e)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.sim_card_rounded,
                                          color: Color(0xFF001f3e),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        // 👈 ensures text doesn't overflow
                                        child: Text(
                                          'Select Network',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF001f3e),
                                          ),
                                          overflow: TextOverflow
                                              .ellipsis, // 👈 truncate if too long
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                BeneficiarySelector(
                                  type: 'data',
                                  phoneController: _phoneController,
                                  isToggled: beneficiary_toggle,
                                  updateToggle: updateBeneficiaryToggle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Network Options
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF001f3e).withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                NetworkSelect(
                                  imageUrl: 'assets/mtn.png',
                                  name: 'MTN',
                                  isSelected: _selectedNetwork == 1,
                                  onTap: () => selectNetwork('MTN', 1),
                                ),
                                NetworkSelect(
                                  imageUrl: 'assets/glo.png',
                                  name: 'GLO',
                                  isSelected: _selectedNetwork == 2,
                                  onTap: () => selectNetwork('GLO', 2),
                                ),
                                NetworkSelect(
                                  imageUrl: 'assets/airtel.webp',
                                  name: 'Airtel',
                                  isSelected: _selectedNetwork == 3,
                                  onTap: () => selectNetwork('Airtel', 3),
                                ),
                                NetworkSelect(
                                  imageUrl: 'assets/nmobile.png',
                                  name: '9mobile',
                                  isSelected: _selectedNetwork == 4,
                                  onTap: () => selectNetwork('9mobile', 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF001f3e).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  color: Color(0xFF001f3e),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF001f3e),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Phone Number Input Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF001f3e).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF001f3e),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter phone number',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 15,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF001f3e)
                                        .withOpacity(0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: const Color(0xFF001f3e)
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF001f3e),
                                      ),
                                    ),
                                  ),
                                ),
                                BeneficiaryToggle(
                                  phone: _phone,
                                  isToggled: beneficiary_toggle,
                                  updateToggle: updateBeneficiaryToggle,
                                  type: 'data',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ... rest of the widgets ...
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF001f3e).withOpacity(0.05),
                              const Color(0xFF001f3e).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
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
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001f3e)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_option_key,
                                      color: Color(0xFF001f3e),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Select Plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF001f3e),
                                    ),
                                  ),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001f3e)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_offer_rounded,
                                        size: 16,
                                        color: Color(0xFF001f3e),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Available Plans',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF001f3e),
                                          fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 24),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF001f3e)
                                          .withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _showPinInputModal(),
                                  icon: _isProcessing
                                      ? Container(
                                          width: 20,
                                          height: 20,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.flash_on_rounded,
                                          size: 20),
                                  label: Text(_isProcessing
                                      ? 'Processing...'
                                      : 'Buy Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001f3e),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF001f3e)
                                            .withOpacity(0.7),
                                    disabledForegroundColor:
                                        Colors.white.withOpacity(0.8),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () async {
                                          final DateTime? selectedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now()
                                                .add(const Duration(days: 30)),
                                            builder: (context, child) {
                                              return Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                    primary: Color(0xFF001f3e),
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface:
                                                        Color(0xFF001f3e),
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );

                                          if (selectedDate != null && mounted) {
                                            final TimeOfDay? selectedTime =
                                                await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context)
                                                      .copyWith(
                                                    timePickerTheme:
                                                        TimePickerThemeData(
                                                      backgroundColor:
                                                          Colors.white,
                                                      hourMinuteTextColor:
                                                          const Color(
                                                              0xFF001f3e),
                                                      dialHandColor:
                                                          const Color(
                                                              0xFF001f3e),
                                                      dialBackgroundColor:
                                                          const Color(
                                                                  0xFF001f3e)
                                                              .withOpacity(0.1),
                                                    ),
                                                    textButtonTheme:
                                                        TextButtonThemeData(
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFF001f3e),
                                                      ),
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );

                                            if (selectedTime != null &&
                                                mounted) {
                                              _showPinInputModal(
                                                scheduledDate: selectedDate,
                                                scheduledTime: selectedTime,
                                              );
                                            }
                                          }
                                        },
                                  icon: _isProcessing
                                      ? Container(
                                          width: 20,
                                          height: 20,
                                          child:
                                              const CircularProgressIndicator(
                                            color: const Color(0xFF001f3e),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.schedule_rounded,
                                          size: 20),
                                  label: Text(_isProcessing
                                      ? 'Processing...'
                                      : 'Buy Later'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF001f3e),
                                    disabledBackgroundColor:
                                        Colors.white.withOpacity(0.7),
                                    disabledForegroundColor:
                                        const Color(0xFF001f3e)
                                            .withOpacity(0.7),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _isProcessing
                                            ? const Color(0xFF001f3e)
                                                .withOpacity(0.3)
                                            : const Color(0xFF001f3e),
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 0,
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
          })),
    );
  }
}
