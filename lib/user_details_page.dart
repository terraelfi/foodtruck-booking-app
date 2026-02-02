import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/payment_page.dart';
import '/database/database_helper.dart';

class UserDetailsPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> cartItems; // Pass cart items from CartScreen
  final Map<String, dynamic>? selectedTruck; // Optional: selected food truck

  const UserDetailsPage({
    Key? key,
    required this.userId,
    required this.cartItems,
    this.selectedTruck,
  }) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _additionalRequestsController =
      TextEditingController();

  DateTime? bookingDate;
  TimeOfDay? bookingTime;
  DateTime? eventDate;
  TimeOfDay? eventTime;
  DateTime? eventDateEnd;
  TimeOfDay? eventTimeEnd;

  bool _isLoading = true;
  Set<DateTime> _bookedDates = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Fetch user data to pre-fill name
      final userData = await DatabaseHelper().getUserById(widget.userId);

      // Load booked dates if truck is selected
      if (widget.selectedTruck != null) {
        await _loadBookedDates();
      }

      if (mounted) {
        setState(() {
          // Pre-fill name
          _nameController.text = userData?['name'] ?? '';

          // Set booking date to today
          bookingDate = DateTime.now();

          // Set booking time to current time
          bookingTime = TimeOfDay.now();

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookedDates() async {
    if (widget.selectedTruck == null) {
      return;
    }

    try {
      final truckName = widget.selectedTruck!['name'];

      if (truckName == null) {
        return;
      }

      final db = await DatabaseHelper().database;

      // Query all bookings for this truck
      final rows = await db.query(
        'truckbook',
        where: 'foodtrucktype = ?',
        whereArgs: [truckName],
      );

      final bookedDates = <DateTime>{};
      for (var row in rows) {
        final eventDateStr = row['eventdate'] as String?;
        final numberOfDays = row['numberofdays'] is int
            ? row['numberofdays'] as int
            : (row['numberofdays'] is String ? int.tryParse(row['numberofdays'] as String) ?? 1 : 1);

        if (eventDateStr != null && eventDateStr.isNotEmpty) {
          try {
            final startDate = DateTime.parse(eventDateStr);
            // Add all dates in the booking range to bookedDates
            for (int i = 0; i < numberOfDays; i++) {
              final date = DateTime(
                startDate.year,
                startDate.month,
                startDate.day + i,
              );
              bookedDates.add(date);
            }
          } catch (e) {
            print('Error parsing date $eventDateStr: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _bookedDates = bookedDates;
        });
      }
    } catch (e) {
      print('ERROR loading booked dates: $e');
    }
  }

  // Helper to check if a date should be selectable in the date picker.
  // Allows passing an "allowIfEqual" date so that the currently-selected
  // date remains selectable when re-opening the picker.
  bool _isDateAvailableForPicker(DateTime date, {DateTime? allowIfEqual}) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (allowIfEqual != null) {
      final allowDateOnly = DateTime(
        allowIfEqual.year,
        allowIfEqual.month,
        allowIfEqual.day,
      );
      if (dateOnly == allowDateOnly) return true;
    }
    return !_bookedDates.contains(dateOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 2,
                      color: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Please review your booking information',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Information Section
                    const Text(
                      '📋 Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name (Pre-filled)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on,
                            color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Booking Date and Time Section
                    const Text(
                      '📅 Booking Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Booking Date (Auto-set to today)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        title: const Text('Booking Date'),
                        subtitle: Text(
                          bookingDate == null
                              ? 'Not set'
                              : DateFormat('EEEE, dd MMM yyyy')
                                  .format(bookingDate!),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.edit, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: bookingDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            selectableDayPredicate: (DateTime date) {
                              // Disable booked dates if truck is selected
                              if (widget.selectedTruck == null) return true;
                              return _isDateAvailableForPicker(date, allowIfEqual: bookingDate);
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              bookingDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Booking Time (Auto-set to current time)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.access_time,
                            color: Colors.blueAccent),
                        title: const Text('Booking Time'),
                        subtitle: Text(
                          bookingTime == null
                              ? 'Not set'
                              : bookingTime!.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.edit, size: 20),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: bookingTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              bookingTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Event Details Section
                    const Text(
                      '🎉 Event Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Event Start Date and Time
                    const Text(
                      'Event Start',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: eventDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  selectableDayPredicate: (DateTime date) {
                                    // Disable booked dates if truck is selected
                                    if (widget.selectedTruck == null) return true;
                                    return _isDateAvailableForPicker(date, allowIfEqual: eventDate);
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    eventDate = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      eventDate == null
                                          ? 'Select Date'
                                          : DateFormat('dd MMM yyyy')
                                              .format(eventDate!),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: eventTime ?? TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    eventTime = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Time',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      eventTime == null
                                          ? 'Select Time'
                                          : eventTime!.format(context),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Event End Date and Time
                    const Text(
                      'Event End',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: eventDateEnd ??
                                      (eventDate ?? DateTime.now())
                                          .add(const Duration(days: 1)),
                                  firstDate: eventDate ?? DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  selectableDayPredicate: (DateTime date) {
                                    // Disable booked dates if truck is selected
                                    if (widget.selectedTruck == null) return true;
                                    return _isDateAvailableForPicker(date, allowIfEqual: eventDateEnd);
                                  },
                                );
                                if (picked != null) {
                                  // Ensure start/end are consistent. If start is not set, set it to the same day.
                                  if (eventDate == null) {
                                    setState(() {
                                      eventDateEnd = picked;
                                      eventDate = picked;
                                    });
                                  } else if (eventDate!.isAfter(picked)) {
                                    // If user picked an end date before the start date, swap them for convenience
                                    final prevStart = eventDate!;
                                    setState(() {
                                      eventDate = picked;
                                      eventDateEnd = prevStart;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event start was after end date — dates were swapped.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      eventDateEnd = picked;
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      eventDateEnd == null
                                          ? 'Select Date'
                                          : DateFormat('dd MMM yyyy')
                                              .format(eventDateEnd!),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: eventTimeEnd ?? TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    eventTimeEnd = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Time',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      eventTimeEnd == null
                                          ? 'Select Time'
                                          : eventTimeEnd!.format(context),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Additional Requests Section
                    const Text(
                      '💬 Additional Requests (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _additionalRequestsController,
                      decoration: InputDecoration(
                        labelText: 'Special requests or notes',
                        hintText: 'E.g., allergies, dietary restrictions...',
                        prefixIcon: const Icon(Icons.note, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Proceed to Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!_formKey.currentState!.validate() ||
                              bookingDate == null ||
                              bookingTime == null ||
                              eventDate == null ||
                              eventTime == null ||
                              eventDateEnd == null ||
                              eventTimeEnd == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields and select all event dates/times.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          // Ensure eventDate (start) is not after eventDateEnd (end)
                          if (eventDate!.isAfter(eventDateEnd!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event start date must be on or before the end date.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                userId: widget.userId,
                                cartItems: widget.cartItems,
                                bookingDetails: {
                                  'bookingDate': bookingDate,
                                  'bookingTime': bookingTime,
                                  'eventDate': eventDate,
                                  'eventTime': eventTime,
                                  'eventDateEnd': eventDateEnd,
                                  'eventTimeEnd': eventTimeEnd,
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
