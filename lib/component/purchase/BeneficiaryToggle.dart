import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BeneficiaryToggle extends ConsumerStatefulWidget {
  const BeneficiaryToggle({
    super.key,
    required this.phone,
    required this.isToggled,
    required this.updateToggle,
    required this.type,
  });
  
  final String phone;
  final String type;
  final bool isToggled;
  final ValueChanged<bool> updateToggle;

  @override
  _BeneficiaryToggleState createState() => _BeneficiaryToggleState();
}

class _BeneficiaryToggleState extends ConsumerState<BeneficiaryToggle> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> addToBeneficiary(String name, String type) async {
   
    try {
      final token = await ref.read(tokenProvider.future);
      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/beneficiary/create_beneficiary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'phone': widget.phone,'type': type}),
      );
      print('pelumi');
      print(response);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name has been saved as a beneficiary!'),
          ),
        );
        widget.updateToggle(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save beneficiary'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while saving beneficiary'),
        ),
      );
    }
  }

  Future<void> removeBeneficiary() async {
    try {
      final token = await ref.read(tokenProvider.future);
      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/beneficiary/remove_beneficiary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'phone': widget.phone}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beneficiary removed')),
        );
        widget.updateToggle(false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove beneficiary')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while removing beneficiary')),
      );
    }
  }

  void _showSaveBeneficiaryModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Beneficiary'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter beneficiary name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.updateToggle(false); // Reset toggle if cancelled
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001f3e),
              ),
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  addToBeneficiary(_nameController.text, widget.type);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid name')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Save as Beneficiary',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF001f3e),
          ),
        ),
        Switch(
          value: widget.isToggled,
          activeColor: const Color(0xFF001f3e),
          onChanged: (value) {
            if (value) {
              _showSaveBeneficiaryModal(context);
            } else {
              removeBeneficiary();
            }
          },
        ),
      ],
    );
  }
}