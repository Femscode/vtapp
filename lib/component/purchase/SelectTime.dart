import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vtubiz/component/purchase/InputPin.dart'; // For formatting date and time

class SelectTime extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(DateTime date, TimeOfDay time) onProceed;

  const SelectTime({
    Key? key,
    required this.onCancel,
    required this.onProceed,
  }) : super(key: key);

  @override
  _SelectTimeState createState() => _SelectTimeState();
}

class _SelectTimeState extends State<SelectTime> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  void _pickDate(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void _pickTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Select Date and Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              readOnly: true,
              onTap: () => _pickDate(context),
              decoration: InputDecoration(
                hintText: selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                    : 'Select Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              readOnly: true,
              onTap: () => _pickTime(context),
              decoration: InputDecoration(
                hintText: selectedTime != null
                    ? selectedTime!.format(context)
                    : 'Select Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    widget.onCancel();
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDate != null && selectedTime != null) {
                      widget.onProceed(selectedDate!, selectedTime!);
                      // Navigator.pop(context);
                      InputPin(
                        onProceed: (pin) {
                          print('Proceeded with PIN: $pin');
                          // Add your logic for proceeding with the PIN
                        },
                        onCancel: () {
                          print('PIN input canceled');
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select both date and time')),
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
