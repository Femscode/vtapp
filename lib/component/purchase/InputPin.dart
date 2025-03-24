import 'package:flutter/material.dart';

class InputPin extends StatelessWidget {
  final Function(String) onProceed;
  final VoidCallback onCancel;

  const InputPin({
    Key? key,
    required this.onProceed,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _pinController = TextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter PIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _pinController,
              maxLength: 4,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                hintText: '••••',
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    onCancel();
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final pin = _pinController.text;
                    if (pin.length == 4) {
                      onProceed(pin);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid 4-digit PIN'),
                        ),
                      );
                    }
                  },
                  child: Text('Proceed'),
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }
}
