import 'package:flutter/material.dart';
import 'package:food_truck_booking_app/user_details_page.dart';
import 'package:ionicons/ionicons.dart';
import '/database/database_helper.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    // Defer heavy operations until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCartItems();
    });
  }

  Future<void> _fetchCartItems() async {
    try {
      final items = await _dbHelper.getCartItems(widget.userId);
      setState(() {
        cartItems = items;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> _deleteCartItem(int cartId) async {
    try {
      await _dbHelper.deleteCartItem(cartId);
      await _fetchCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from cart.')),
      );
    } catch (e) {
      print('Error deleting cart item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item.')),
      );
    }
  }

  Future<void> _updateQuantity(
      int cartId, int currentQuantity, int change) async {
    final newQuantity = currentQuantity + change;
    if (newQuantity < 1) return;

    try {
      await _dbHelper.updateCartItemQuantity(cartId, newQuantity);
      await _fetchCartItems();
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  void _showDeleteConfirmationDialog(int cartId, String dishName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove $dishName from cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCartItem(cartId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate truck bookings and dishes
    final truckBookings = cartItems
        .where((item) => item['dish_name'] == '__TRUCK_BOOKING__')
        .toList();
    final dishes = cartItems
        .where((item) => item['dish_name'] != '__TRUCK_BOOKING__')
        .toList();

    double total = cartItems.fold(
        0,
        (sum, item) =>
            sum + ((item['price'] as double) * (item['quantity'] as int)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.blueAccent,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Show truck bookings first
                      if (truckBookings.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Selected Food Truck${truckBookings.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        ...truckBookings.map((truck) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            color: Colors.blue[50],
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                truck['foodtruck_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Truck Booking Fee',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'RM ${truck['price'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Ionicons.trash_bin_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showDeleteConfirmationDialog(
                                      truck['cartid'],
                                      truck['foodtruck_name'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(thickness: 2),
                      ],

                      // Show dishes
                      if (dishes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Dishes Ordered',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        ...dishes.map((item) {
                          final itemTotal = (item['price'] as double) *
                              (item['quantity'] as int);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.grey,
                                ),
                              ),
                              title: Text(
                                item['dish_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From: ${item['foodtruck_name']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _updateQuantity(
                                            item['cartid'],
                                            item['quantity'],
                                            -1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '${item['quantity']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _updateQuantity(
                                            item['cartid'],
                                            item['quantity'],
                                            1),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'RM ${itemTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Ionicons.trash_bin_outline,
                                    color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  item['cartid'],
                                  item['dish_name'],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
                // Total and Checkout Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Breakdown
                      if (truckBookings.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Truck Booking:',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              'RM ${truckBookings.fold(0.0, (sum, item) => sum + (item['price'] as double)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (dishes.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dishes:',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              'RM ${dishes.fold(0.0, (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int))).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Extract selected truck if there's a truck booking in cart
                            Map<String, dynamic>? selectedTruck;
                            if (truckBookings.isNotEmpty) {
                              final truck = truckBookings.first;
                              selectedTruck = {
                                'name': truck['foodtruck_name'],
                                'price': truck['price'],
                              };
                            }
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailsPage(
                                  userId: widget.userId,
                                  cartItems: cartItems,
                                  selectedTruck: selectedTruck,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
