import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'cart_screen.dart';

class DishSelectionScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> foodTruck;

  const DishSelectionScreen({
    Key? key,
    required this.userId,
    required this.foodTruck,
  }) : super(key: key);

  @override
  _DishSelectionScreenState createState() => _DishSelectionScreenState();
}

class _DishSelectionScreenState extends State<DishSelectionScreen> {
  List<Map<String, dynamic>> dishes = [];
  bool _isLoading = true;
  int _cartItemCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDishes();
      _loadCartItemCount();
    });
  }

  Future<void> _loadCartItemCount() async {
    try {
      final cartItems = await _dbHelper.getCartItems(widget.userId);
      if (mounted) {
        setState(() {
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      print('Error loading cart item count: $e');
    }
  }

  Future<void> _loadDishes() async {
    try {
      // Load ALL dishes (global inventory, not per-truck)
      final loadedDishes = await _dbHelper.getAllDishesGlobal();
      if (mounted) {
        setState(() {
          dishes = loadedDishes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dishes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart(Map<String, dynamic> dish, int quantity) async {
    try {
      // Check if this is the first item from this truck
      final existingCartItems = await _dbHelper.getCartItems(widget.userId);
      final hasTruckBooking = existingCartItems.any((item) =>
          item['foodtruck_name'] == widget.foodTruck['name'] &&
          item['dish_name'] == '__TRUCK_BOOKING__');

      // If no truck booking exists, add it first
      if (!hasTruckBooking) {
        await _dbHelper.addDishToCart({
          'userid': widget.userId,
          'dishid': 0, // Special ID for truck booking
          'dish_name': '__TRUCK_BOOKING__', // Special marker
          'foodtruck_name': widget.foodTruck['name'],
          'quantity': 1,
          'price': widget.foodTruck['price'], // Truck booking fee
          'booking_date': DateTime.now().toIso8601String(),
        });
      }

      // Add the dish to cart
      await _dbHelper.addDishToCart({
        'userid': widget.userId,
        'dishid': dish['dishid'],
        'dish_name': dish['name'],
        'foodtruck_name': widget.foodTruck['name'],
        'quantity': quantity,
        'price': dish['price'],
        'booking_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _loadCartItemCount(); // Reload cart count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${dish['name']} added to cart with ${widget.foodTruck['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDishDetails(Map<String, dynamic> dish) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dish Image (placeholder)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dish Name
                    Text(
                      dish['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      'RM ${dish['price'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      dish['description'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Availability
                    Row(
                      children: [
                        Icon(
                          dish['quantity'] > 0
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              dish['quantity'] > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dish['quantity'] > 0
                              ? 'Available (${dish['quantity']} left)'
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 16,
                            color: dish['quantity'] > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quantity Selector
                    if (dish['quantity'] > 0) ...[
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setModalState(() {
                                  quantity--;
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 32,
                            color: Colors.blueAccent,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (quantity < dish['quantity']) {
                                setModalState(() {
                                  quantity++;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 32,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToCart(dish, quantity);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Add to Cart - RM ${(dish['price'] * quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.foodTruck['name'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Cart button in app bar
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(userId: widget.userId),
                    ),
                  ).then((_) =>
                      _loadCartItemCount()); // Reload count when returning
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : dishes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Dishes Available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This food truck hasn\'t added any dishes yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Food Truck Info Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.foodTruck['type'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: widget.foodTruck['availability'] ==
                                        'Available'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.foodTruck['availability'] ?? 'Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.foodTruck['availability'] ==
                                          'Available'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Dishes List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: dishes.length,
                        itemBuilder: (context, index) {
                          final dish = dishes[index];
                          final isAvailable = dish['quantity'] > 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 60,
                                height: 60,
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
                                dish['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isAvailable ? Colors.black : Colors.grey,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    dish['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isAvailable
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'RM ${dish['price'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAvailable
                                            ? '(${dish['quantity']} left)'
                                            : '(Out of stock)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isAvailable
                                              ? Colors.grey
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                color: isAvailable
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                onPressed: isAvailable
                                    ? () => _showDishDetails(dish)
                                    : null,
                              ),
                              onTap: isAvailable
                                  ? () => _showDishDetails(dish)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(userId: widget.userId),
                  ),
                ).then(
                    (_) => _loadCartItemCount()); // Reload count when returning
              },
              backgroundColor: Colors.blueAccent,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Go to Cart ($_cartItemCount)',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
