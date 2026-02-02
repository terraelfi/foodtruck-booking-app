import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package
import '/database/database_helper.dart';
import '/utils/auth_manager.dart';
import 'ReviewPage.dart';

class AccountScreen extends StatefulWidget {
  final int userId;

  const AccountScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> previousBookings = [];
  List<Map<String, dynamic>> userReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchPreviousBookings();
    _fetchUserReviews();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await DatabaseHelper().getUserById(widget.userId);
      if (data != null) {
        setState(() {
          userData = data;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchPreviousBookings() async {
    try {
      final bookings = await DatabaseHelper().getUserBookings(widget.userId);
      setState(() {
        previousBookings = bookings;
      });
    } catch (e) {
      print('Error fetching previous bookings: $e');
    }
  }

  Future<void> _fetchUserReviews() async {
    try {
      final reviews = await DatabaseHelper().getReviewsByUser(widget.userId);
      setState(() {
        userReviews = reviews;
      });
    } catch (e) {
      print('Error fetching user reviews: $e');
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    if (userData == null) return;

    final updatedData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController(text: userData!['name']);
        final emailController = TextEditingController(text: userData!['email']);
        final phoneController = TextEditingController(text: userData!['phone']);

        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updatedData != null) {
      final updatedUser = {
        'userid': widget.userId,
        'name': updatedData['name'],
        'email': updatedData['email'],
        'phone': updatedData['phone'],
        'username': userData!['username'],
        'password': userData!['password'], // Keep the same password
      };

      await DatabaseHelper().updateUser(updatedUser);
      _fetchUserData(); // Refresh the updated profile data
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthManager.setUserLoggedIn(false);
    await AuthManager.setUserId(null);
    Navigator.pushReplacementNamed(context, '/login');
  }

  String formatDate(String isoDateString) {
    try {
      final DateTime date = DateTime.parse(isoDateString);
      return DateFormat('dd MMM yyyy').format(date); // Format to "03 Jan 2025"
    } catch (e) {
      print('Error formatting date: $e');
      return isoDateString; // Fallback to original string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: Colors.blueAccent,
        ),
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${userData!['name']}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Name', userData!['name']),
                                const Divider(),
                                _buildDetailRow('Email', userData!['email']),
                                const Divider(),
                                _buildDetailRow('Phone', userData!['phone']),
                                const Divider(),
                                _buildDetailRow('Username', userData!['username']),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _editProfile(context),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _logout(context),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    color: Colors.grey[100],
                    child: TabBar(
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.receipt_long),
                          text: 'Checkouts (${previousBookings.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.rate_review),
                          text: 'My Reviews (${userReviews.length})',
                        ),
                      ],
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Checkouts Tab
                        _buildCheckoutsTab(),
                        // Reviews Tab
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckoutsTab() {
    return Column(
      children: [
        Expanded(
          child: previousBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No previous checkouts found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: previousBookings.length,
                  itemBuilder: (context, index) {
                    final booking = previousBookings[index];
                    final truckFee = booking['truck_fee'] ?? booking['price'];
                    final dishesOrdered = booking['dishes_ordered'];
                    final totalPrice = booking['price'] ?? 0.0;

                    // Parse dishes if available
                    List<Map<String, dynamic>> dishes = [];
                    if (dishesOrdered != null && dishesOrdered.isNotEmpty) {
                      try {
                        // Format: "DishName:Price:Qty|DishName:Price:Qty"
                        final dishParts = dishesOrdered.split('|');
                        for (var part in dishParts) {
                          final details = part.split(':');
                          if (details.length == 3) {
                            dishes.add({
                              'name': details[0],
                              'price': double.parse(details[1]),
                              'quantity': int.parse(details[2]),
                            });
                          }
                        }
                      } catch (e) {
                        print('Error parsing dishes: $e');
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        title: Text(
                          'Food Truck: ${booking['foodtrucktype']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Booking Date: ${formatDate(booking['book_date'])}\n'
                          'Total: RM ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone: ${booking['phone'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Event Date: ${formatDate(booking['eventdate'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Divider(),
                                // Price Breakdown
                                const Text(
                                  'Price Breakdown:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Truck Booking Fee:'),
                                    Text(
                                      'RM ${truckFee.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                if (dishes.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Dishes Ordered:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...dishes
                                      .map((dish) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${dish['name']} (x${dish['quantity']})',
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                ),
                                                Text(
                                                  'RM ${(dish['price'] * dish['quantity']).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ],
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'RM ${totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (previousBookings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No bookings to review.'),
                    ),
                  );
                  return;
                }

                // Use last booking's foodtrucktype as the truck name
                final lastBooking = previousBookings.last;
                final truckName = lastBooking['foodtrucktype'] as String;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewPage(
                      userId: widget.userId,
                      foodTruckName: truckName,
                    ),
                  ),
                ).then((_) => _fetchUserReviews());
              },
              icon: const Icon(Icons.rate_review, color: Colors.white),
              label: const Text('Write a Review',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return userReviews.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t written any reviews yet.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book a food truck and share your experience!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userReviews.length,
            itemBuilder: (context, index) {
              final review = userReviews[index];
              final rating = review['userreviewstar'] as num;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Truck Name
                      Row(
                        children: [
                          Icon(Icons.local_shipping,
                              color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              review['foodtruck_name'] ?? 'Unknown Truck',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Star Rating
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              Icons.star,
                              size: 20,
                              color: i < rating.toInt()
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '(${rating.toStringAsFixed(1)})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Review Text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          review['userreview'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
