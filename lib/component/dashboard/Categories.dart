import 'package:flutter/material.dart';
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
    {"icon": Icons.flash_on, "text": "Data"},
    {"icon": Icons.phone, "text": "Airtime", "isDisabled": true},
    {"icon": Icons.electric_bolt, "text": "Electricity"},
    {"icon": Icons.message_rounded, "text": "Bulk SMS", "isDisabled": true},
    {"icon": Icons.tv_rounded, "text": "Cable(TV)"},
    {"icon": Icons.school_rounded, "text": "Result"},
    {"icon": Icons.card_giftcard, "text": "Giveaways", "isDisabled": true},
    {"icon": Icons.people_rounded, "text": "Referral"},
  ];

  void navigatePurchase(String title) {
    switch (title) {
      case 'Data':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const BuyData()));
        break;
      case 'Electricity':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const BuyElectricity()));
        break;
      case 'Cable(TV)':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const BuyCable()));
        break;
      case 'Result':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const BuyExamination()));
        break;
      case 'Referral':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Referral()));
        break;
    }
  }

  void showNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming soon... 🚧"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 icons per row
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        return CategoryCircle(
          icon: item["icon"],
          text: item["text"],
          isDisabled: item["isDisabled"] ?? false,
          press: () => item["isDisabled"] == true
              ? showNotAvailable()
              : navigatePurchase(item["text"]),
        );
      },
    );
  }
}

class CategoryCircle extends StatelessWidget {
  const CategoryCircle({
    Key? key,
    required this.icon,
    required this.text,
    required this.press,
    this.isDisabled = false,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final GestureTapCallback press;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                isDisabled ? Colors.grey.shade300 : const Color(0xFF001f3e),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey : const Color(0xFF001f3e),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
