import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FetchPlan extends StatefulWidget {
  final String type;
  final int network;
  final Function(Map<String, dynamic>) onPlanSelected;

  const FetchPlan({
    Key? key,
    required this.type,
    required this.network,
    required this.onPlanSelected,
  }) : super(key: key);

  @override
  State<FetchPlan> createState() => _FetchPlanState();
}

class _FetchPlanState extends State<FetchPlan> {
  List<dynamic> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  @override
  void didUpdateWidget(FetchPlan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.network != widget.network) {
      setState(() {
        _selectedPlan = null;
        _plans = [];
      });
      fetchPlans();
    }
  }

  Future<void> fetchPlans() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _plans = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
            'https://vtubiz.com/api/purchase/fetch-plan/${widget.type}/${widget.network}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          _plans = List.from(data['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _plans = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plans = [];
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedPlan,
              underline: const SizedBox(),
              hint: Text(
                'Select a plan',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF001f3e),
              ),
              items: _plans.map<DropdownMenuItem<Map<String, dynamic>>>((plan) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: plan,
                  child: Text(
                    '${plan['plan_name']} - ₦${plan['admin_price']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF001f3e),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPlan = newValue;
                  });
                  widget.onPlanSelected(newValue);
                }
              },
            ),
    );
  }
}
