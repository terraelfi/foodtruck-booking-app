import 'package:flutter/material.dart';
import 'screens/food_truck_selection_page_screen.dart';

class BookingDetailsPage extends StatefulWidget {
  final int userId; // ID of the logged-in user

  const BookingDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bookingDateController = TextEditingController();
  final TextEditingController _eventStartDateController =
      TextEditingController();
  final TextEditingController _eventEndDateController = TextEditingController();

  // Booking details
  DateTime? bookingDate;
  DateTime? eventStartDate;
  DateTime? eventEndDate;
  bool needsDecoration = false;

  void _selectDate(BuildContext context, TextEditingController controller,
      Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = picked.toString().split(' ')[0];
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _bookingDateController,
                decoration: const InputDecoration(
                  labelText: 'Booking Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () =>
                    _selectDate(context, _bookingDateController, (date) {
                  bookingDate = date;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventStartDateController,
                decoration: const InputDecoration(
                  labelText: 'Event Start Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () =>
                    _selectDate(context, _eventStartDateController, (date) {
                  eventStartDate = date;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventEndDateController,
                decoration: const InputDecoration(
                  labelText: 'Event End Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () =>
                    _selectDate(context, _eventEndDateController, (date) {
                  eventEndDate = date;
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Need Decoration'),
                value: needsDecoration,
                onChanged: (bool value) {
                  setState(() {
                    needsDecoration = value;
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodTruckSelectionPage(
                          userId: widget.userId,
                          // bookingDate: bookingDate!,
                          // eventStartDate: eventStartDate!,
                          // eventEndDate: eventEndDate!,
                          // needsDecoration: needsDecoration,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Next: Select Food Trucks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
