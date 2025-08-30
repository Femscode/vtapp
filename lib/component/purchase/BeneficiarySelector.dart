import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vtubiz/providers/authprovider.dart';

class BeneficiarySelector extends ConsumerStatefulWidget {
  const BeneficiarySelector({
    super.key, 
    required this.type, 
    required this.phoneController, 
    required this.isToggled, 
    required this.updateToggle,
  });

  final String type;
  final TextEditingController phoneController;
  final bool isToggled;
  final ValueChanged<bool> updateToggle;

  @override
  _BeneficiarySelectorState createState() => _BeneficiarySelectorState();
}

class _BeneficiarySelectorState extends ConsumerState<BeneficiarySelector> {
  String? selectedBeneficiary;

  void _showBeneficiaryModal(BuildContext context) async {
    final allBeneficiaries = await ref.read(fetchBeneficiaryProvider(widget.type).future);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Beneficiary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedBeneficiary,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    border: InputBorder.none,
                    hintText: 'Choose a beneficiary',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                  items: allBeneficiaries.map((beneficiary) {
                    return DropdownMenuItem<String>(
                      value: beneficiary['phone'],
                      child: Text(
                        '${beneficiary['name']} (${beneficiary['phone']})',
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBeneficiary = value;
                      widget.updateToggle(true);
                    });
                  },
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedBeneficiary != null) {
                        widget.phoneController.text = selectedBeneficiary!;
                        widget.updateToggle(true);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001f3e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Select', style : TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBeneficiaryModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF001f3e).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
         
          children: [
            Icon(
              Icons.person_add_rounded,
              color: const Color(0xFF001f3e),
              size: 20,
            ),
            //  SizedBox(width: 8),
            Text(
              'Pick Beneficiary',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF001f3e),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}