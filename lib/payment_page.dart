import 'package:flutter/material.dart';
import '/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'screens/main_navigation_screen.dart';

class PaymentPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic> bookingDetails;

  const PaymentPage({
    Key? key,
    required this.userId,
    required this.cartItems,
    required this.bookingDetails,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _discountController = TextEditingController();
  double totalPrice = 0.0;
  double discount = 0.0;
  double finalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    calculateTotalPrice();
  }

  void calculateTotalPrice() {
    totalPrice = widget.cartItems.fold(
      0,
      (sum, item) {
        final price = item['price'] as double? ?? 0.0;
        final quantity = item['quantity'] as int? ?? 1;
        return sum + (price * quantity);
      },
    );
    finalPrice = totalPrice - discount;
  }

  void applyDiscount() {
    setState(() {
      if (_discountController.text == 'DISCOUNT10') {
        discount = totalPrice * 0.1;
      } else if (_discountController.text == 'DISCOUNT20') {
        discount = totalPrice * 0.2;
      } else {
        discount = 0.0;
      }
      finalPrice = totalPrice - discount;
    });
  }

  Future<void> confirmPayment() async {
    try {
      if (widget.cartItems.isEmpty) {
        throw Exception('Cart is empty.');
      }

      // Validate booking details
      if (widget.bookingDetails['bookingDate'] == null ||
          widget.bookingDetails['bookingTime'] == null ||
          widget.bookingDetails['eventDate'] == null ||
          widget.bookingDetails['eventTime'] == null ||
          widget.bookingDetails['eventDateEnd'] == null ||
          widget.bookingDetails['eventTimeEnd'] == null) {
        throw Exception('Incomplete booking details.');
      }

      final String bookingDate =
          (widget.bookingDetails['bookingDate'] as DateTime).toIso8601String();
      final String eventDate =
          (widget.bookingDetails['eventDate'] as DateTime).toIso8601String();

      final String bookingTime =
          _formatTimeOfDay(widget.bookingDetails['bookingTime'] as TimeOfDay);
      final String eventTime =
          _formatTimeOfDay(widget.bookingDetails['eventTime'] as TimeOfDay);

      // Calculate number of days from event start to end
      final eventStart = widget.bookingDetails['eventDate'] as DateTime;
      final eventEnd = widget.bookingDetails['eventDateEnd'] as DateTime;
      final numberOfDays = eventEnd.difference(eventStart).inDays + 1; // +1 to include both start and end day

      // Group cart items by food truck
      Map<String, Map<String, dynamic>> truckBookings = {};

      for (var item in widget.cartItems) {
        if (item['foodtruck_name'] == null || item['price'] == null) {
          throw Exception('Invalid cart item: Missing required fields.');
        }

        final truckName = item['foodtruck_name'] as String;

        // Initialize truck booking if not exists
        if (!truckBookings.containsKey(truckName)) {
          truckBookings[truckName] = {
            'truckFee': 0.0,
            'dishes': [],
            'totalPrice': 0.0,
          };
        }

        // Check if it's a truck booking fee or a dish
        if (item['dish_name'] == '__TRUCK_BOOKING__') {
          // This is the truck booking fee
          truckBookings[truckName]!['truckFee'] = item['price'] as double;
          truckBookings[truckName]!['totalPrice'] =
              (truckBookings[truckName]!['totalPrice'] as double) +
                  (item['price'] as double);
        } else {
          // This is a dish
          final quantity = item['quantity'] as int? ?? 1;
          final dishPrice = item['price'] as double;
          final dishTotal = dishPrice * quantity;

          truckBookings[truckName]!['dishes'].add({
            'name': item['dish_name'],
            'price': dishPrice,
            'quantity': quantity,
          });

          truckBookings[truckName]!['totalPrice'] =
              (truckBookings[truckName]!['totalPrice'] as double) + dishTotal;
        }
      }

      // Create a booking for each truck and decrease dish quantities
      final dbHelper = DatabaseHelper();
      
      for (var entry in truckBookings.entries) {
        final truckName = entry.key;
        final bookingInfo = entry.value;

        // Format dishes as: "DishName:Price:Qty|DishName:Price:Qty"
        String dishesFormatted = '';
        if (bookingInfo['dishes'].isNotEmpty) {
          dishesFormatted = (bookingInfo['dishes'] as List)
              .map((dish) =>
                  '${dish['name']}:${dish['price']}:${dish['quantity']}')
              .join('|');
          
          // Decrease dish quantities in database
          for (var dish in bookingInfo['dishes']) {
            // Find dish in cart to get dishid
            final cartDish = widget.cartItems.firstWhere(
              (item) => item['dish_name'] == dish['name'] && 
                        item['foodtruck_name'] == truckName,
              orElse: () => {},
            );
            
            if (cartDish.isNotEmpty && cartDish['dishid'] != null && cartDish['dishid'] != 0) {
              // Get current dish from database
              final currentDish = await dbHelper.getDishById(cartDish['dishid']);
              if (currentDish != null) {
                final newQuantity = (currentDish['quantity'] as int) - (dish['quantity'] as int);
                // Update quantity (don't go below 0)
                await dbHelper.updateDishQuantity(
                  cartDish['dishid'], 
                  newQuantity > 0 ? newQuantity : 0
                );
              }
            }
          }
        }

        final bookingData = {
          'userid': widget.userId,
          'book_date': bookingDate,
          'booktime': bookingTime,
          'eventdate': eventDate,
          'eventtime': eventTime,
          'foodtrucktype': truckName,
          'numberofdays': numberOfDays, // Calculated from event start to end
          'price': bookingInfo['totalPrice'], // Total price (truck + dishes)
          'truck_fee': bookingInfo['truckFee'], // Truck booking fee only
          'dishes_ordered': dishesFormatted, // Formatted dishes string
        };

        await dbHelper.insertBooking(bookingData);
      }

      // Clear the cart after successful booking
      for (var item in widget.cartItems) {
        await DatabaseHelper().deleteCartItem(item['cartid']);
      }

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Payment Confirmed'),
          content: const Text('Your booking has been completed successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainNavigationScreen(
                            userId: widget.userId,
                            isAdmin: false,
                          )),
                  (route) => false, // Remove all routes
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error saving booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete the payment: $e')),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final int hour = time.hour;
    final int minute = time.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Details Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Booking Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Booking Date:',
                      DateFormat('dd MMM yyyy')
                          .format(widget.bookingDetails['bookingDate']),
                    ),
                    _buildDetailRow(
                      'Booking Time:',
                      widget.bookingDetails['bookingTime'].format(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event Details Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Event Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Start: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(widget.bookingDetails['eventDate']),
                        ),
                        const Text(' at '),
                        Text(widget.bookingDetails['eventTime'].format(context)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('End:   ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(widget.bookingDetails['eventDateEnd']),
                        ),
                        const Text(' at '),
                        Text(widget.bookingDetails['eventTimeEnd']
                            .format(context)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        'Duration: ${(widget.bookingDetails['eventDateEnd'] as DateTime).difference(widget.bookingDetails['eventDate'] as DateTime).inDays + 1} day(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Summary Section
            const Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    final isTruckBooking =
                        item['dish_name'] == '__TRUCK_BOOKING__';
                    final quantity = item['quantity'] as int? ?? 1;
                    final price = item['price'] as double? ?? 0.0;
                    final total = price * quantity;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isTruckBooking ? Colors.blue[50] : Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isTruckBooking
                                ? Colors.blueAccent
                                : Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTruckBooking
                                ? Icons.local_shipping
                                : Icons.restaurant,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isTruckBooking
                              ? '${item['foodtruck_name']} (Booking Fee)'
                              : item['dish_name'] ?? 'Unnamed Dish',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: isTruckBooking
                            ? null
                            : Text(
                                'From: ${item['foodtruck_name']} × $quantity',
                                style: const TextStyle(fontSize: 12),
                              ),
                        trailing: Text(
                          'RM ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isTruckBooking
                                ? Colors.blueAccent
                                : Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discount Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Apply Discount Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              hintText: 'Enter code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: applyDiscount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Apply',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '✓ Discount Applied: -RM${discount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Final Price',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (discount > 0)
                        Text(
                          'RM ${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        'RM ${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Payment Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: confirmPayment,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
