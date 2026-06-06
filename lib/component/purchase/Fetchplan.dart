import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vtubiz/config.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _searchQuery = '';

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
            '${AppConfig.liveUrl}/purchase/fetch-plan/${widget.type}/${widget.network}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

  void _openPlanSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredPlans = _plans.where((plan) {
              final name = (plan['plan_name'] ?? '').toString().toLowerCase();
              final price = (plan['admin_price'] ?? '').toString();
              return name.contains(_searchQuery.toLowerCase()) ||
                  price.contains(_searchQuery);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Data Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF001f3e),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() {
                            _searchQuery = val;
                          });
                        },
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF001f3e),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search bundles (e.g. 1GB, SME)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredPlans.isEmpty
                        ? Center(
                            child: Text(
                              'No matching plans found',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredPlans.length,
                            separatorBuilder: (_, __) => Divider(
                              color: const Color(0xFF001f3e).withOpacity(0.04),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final plan = filteredPlans[index];
                              final isSelectedPlan = _selectedPlan != null &&
                                  _selectedPlan!['plan_id'] == plan['plan_id'];

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPlan = plan;
                                    _searchQuery = '';
                                  });
                                  widget.onPlanSelected(plan);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isSelectedPlan
                                        ? const Color(0xFF00D2FF).withOpacity(0.05)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan['plan_name'] ?? '',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: isSelectedPlan
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: const Color(0xFF001f3e),
                                              ),
                                            ),
                                            if (plan['validity'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Validity: ${plan['validity']}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '₦${plan['admin_price']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF00D2FF),
                                            ),
                                          ),
                                          if (isSelectedPlan) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF00D2FF),
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _searchQuery = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF00D2FF),
          ),
        ),
      );
    }

    final hasSelection = _selectedPlan != null;

    return GestureDetector(
      onTap: _openPlanSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasSelection ? const Color(0xFF00D2FF).withOpacity(0.02) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection ? const Color(0xFF00D2FF).withOpacity(0.6) : const Color(0xFF001f3e).withOpacity(0.08),
            width: hasSelection ? 1.5 : 1.2,
          ),
          boxShadow: [
            if (hasSelection)
              BoxShadow(
                color: const Color(0xFF00D2FF).withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    color: hasSelection ? const Color(0xFF00D2FF) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSelection ? _selectedPlan!['plan_name'] : 'Choose Data Plan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF001f3e),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasSelection) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Validity: ${_selectedPlan!['validity'] ?? "30 Days"}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (hasSelection) ...[
                  Text(
                    '₦${_selectedPlan!['admin_price']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00D2FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF001f3e),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
