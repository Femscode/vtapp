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
      });
      fetchPlans();
    }
  }

  Future<void> fetchPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://vtubiz.com/api/purchase/fetch-plan/${widget.type}/${widget.network}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          _plans = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _plans = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _plans = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: _selectedPlan,
                hint: const Text('Select a plan'),
                items: _plans.map<DropdownMenuItem<Map<String, dynamic>>>((plan) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: plan,
                    child: Text(
                      '${plan['name']} - ₦${plan['amount']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedPlan = newValue;
                  });
                  if (newValue != null) {
                    widget.onPlanSelected(newValue);
                  }
                },
              ),
            ),
    );
  }
}