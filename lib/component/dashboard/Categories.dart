import 'package:flutter/material.dart';
import 'package:vtubiz/pages/BuyCable.dart';
import 'package:vtubiz/pages/BuyData.dart';
import 'package:vtubiz/pages/BuyElectricity.dart';
import 'package:vtubiz/pages/BuyExamination.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final List<Map<String, dynamic>> categories = [
    {
      "icon": Icons.flash_on,
      "text": "Data",
      "gradient": [Color(0xFFf98f29), Color(0xFFf98f29).withOpacity(0.8)]
    },
    {
      "icon": Icons.phone,
      "text": "Airtime",
      "gradient": [Color(0xFFf98f29), Color(0xFFf98f29).withOpacity(0.8)]
    },
    {
      "icon": Icons.electric_bolt,
      "text": "Electricity",
      "gradient": [Color(0xFFf98f29), Color(0xFF001f3e).withOpacity(0.8)]
    },
    {
      "icon": Icons.message_rounded,
      "text": "Bulk SMS",
      "gradient": [Color(0xFFf98f29), Color(0xFFf98f29).withOpacity(0.8)]
    },
    {
      "icon": Icons.tv_rounded,
      "text": "Cable(TV)",
      "gradient": [Color(0xFF001f3e), Color(0xFF001f3e).withOpacity(0.8)]
    },
    {
      "icon": Icons.school_rounded,
      "text": "Result",
      "gradient": [Color(0xFFf98f29), Color(0xFFf98f29).withOpacity(0.8)]
    },
    {
      "icon": Icons.card_giftcard,
      "text": "Giveaways",
      "gradient": [Color(0xFF001f3e), Color(0xFF001f3e).withOpacity(0.8)]
    },
    {
      "icon": Icons.people_rounded,
      "text": "Referral",
      "gradient": [Color(0xFFf98f29), Color(0xFFf98f29).withOpacity(0.8)]
    },
  ];

  void navigatePurchase(title) async {
    print(title);
    if (title == 'Data') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const BuyData()));
    }
    if (title == 'Electricity') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const BuyElectricity()));
    }
    if (title == 'Cable(TV)') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const BuyCable()));
    }
    if (title == 'Result') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const BuyExamination()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) => CategoryCard(
          icon: categories[index]["icon"],
          text: categories[index]["text"],
          gradient: categories[index]["gradient"],
          press: () => navigatePurchase(categories[index]["text"]),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.gradient,
    required this.press,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final List<Color> gradient;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF001f3e),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
