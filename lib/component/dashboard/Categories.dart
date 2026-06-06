import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vtubiz/pages/BuyCable.dart';
import 'package:vtubiz/pages/BuyData.dart';
import 'package:vtubiz/pages/BuyElectricity.dart';
import 'package:vtubiz/pages/BuyExamination.dart';
import 'package:vtubiz/pages/Referral.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final List<Map<String, dynamic>> categories = [
    {
      "icon": Icons.flash_on_rounded,
      "text": "Data",
      "color": const Color(0xFF0A84FF),
    },
    {
      "icon": Icons.phone_rounded,
      "text": "Airtime",
      "isDisabled": true,
      "color": const Color(0xFF00D2FF),
    },
    {
      "icon": Icons.electric_bolt_rounded,
      "text": "Electricity",
      "color": const Color(0xFFFFB300),
    },
    {
      "icon": Icons.message_rounded,
      "text": "Bulk SMS",
      "isDisabled": true,
      "color": const Color(0xFFFF9500),
    },
    {
      "icon": Icons.tv_rounded,
      "text": "Cable(TV)",
      "color": const Color(0xFFBF5AF2),
    },
    {
      "icon": Icons.school_rounded,
      "text": "Result",
      "color": const Color(0xFF5E5CE6),
    },
    {
      "icon": Icons.card_giftcard_rounded,
      "text": "Giveaways",
      "isDisabled": true,
      "color": const Color(0xFFFF2D55),
    },
    {
      "icon": Icons.people_rounded,
      "text": "Referral",
      "color": const Color(0xFF34C759),
    },
  ];

  void navigatePurchase(String title) {
    switch (title) {
      case 'Data':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BuyData()),
        );
        break;
      case 'Electricity':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BuyElectricity()),
        );
        break;
      case 'Cable(TV)':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BuyCable()),
        );
        break;
      case 'Result':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BuyExamination()),
        );
        break;
      case 'Referral':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Referral()),
        );
        break;
    }
  }

  void showNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming soon... 🚧"),
        backgroundColor: Color(0xFF001f3e),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 icons per row
        childAspectRatio: 0.85,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        return CategoryCircle(
          icon: item["icon"],
          text: item["text"],
          color: item["color"],
          isDisabled: item["isDisabled"] ?? false,
          press: () => item["isDisabled"] == true
              ? showNotAvailable()
              : navigatePurchase(item["text"]),
        );
      },
    );
  }
}

class CategoryCircle extends StatefulWidget {
  const CategoryCircle({
    Key? key,
    required this.icon,
    required this.text,
    required this.press,
    required this.color,
    this.isDisabled = false,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final GestureTapCallback press;
  final Color color;
  final bool isDisabled;

  @override
  State<CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<CategoryCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isDisabled ? Colors.grey : widget.color;

    return GestureDetector(
      onTapDown: (_) => widget.isDisabled ? null : _controller.forward(),
      onTapUp: (_) {
        if (!widget.isDisabled) {
          _controller.reverse();
          widget.press();
        }
      },
      onTapCancel: () => widget.isDisabled ? null : _controller.reverse(),
      onTap: widget.isDisabled ? widget.press : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDisabled
                      ? [
                          Colors.grey.withOpacity(0.08),
                          Colors.grey.withOpacity(0.04),
                        ]
                      : [
                          widget.color.withOpacity(0.14),
                          widget.color.withOpacity(0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.isDisabled
                      ? Colors.transparent
                      : widget.color.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.isDisabled
                    ? Colors.grey.shade500
                    : const Color(0xFF001f3e),
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
