import 'package:flutter/material.dart';
import '/database/database_helper.dart';
import '/utils/auth_manager.dart'; // Import AuthManager for logout functionality
import 'package:intl/intl.dart'; // For date formatting
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _userBookings = [];
  List<Map<String, dynamic>> _foodTrucks = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _dishes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Sales Report State
  DateTime _selectedReportDate = DateTime.now();
  Map<String, dynamic>? _salesReport;
  bool _isLoadingReport = false;
  Set<DateTime> _bookingDates = {};

  @override
  void initState() {
    super.initState();
    // Defer heavy operations until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Clean up any duplicate dishes first
    await _dbHelper.cleanupDuplicateDishes();

    // Then fetch all data
    _fetchUsers();
    _fetchUserBookings();
    _fetchFoodTrucks();
    _fetchReviews();
    _fetchDishes();
    _fetchBookingDates();
  }

  Future<void> _fetchBookingDates() async {
    try {
      final dates = await _dbHelper.getAllBookingDates();
      setState(() {
        _bookingDates = dates.map((dateStr) {
          final date = DateTime.parse(dateStr);
          // Normalize to midnight to match date picker dates
          return DateTime(date.year, date.month, date.day);
        }).toSet();
      });
    } catch (e) {
      print('Error fetching booking dates: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _dbHelper.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _fetchUserBookings() async {
    try {
      final bookings = await _dbHelper.getAllUserBookings();
      setState(() {
        _userBookings = bookings;
      });
    } catch (e) {
      print('Error fetching user bookings: $e');
    }
  }

  Future<void> _fetchFoodTrucks() async {
    try {
      final trucks = await _dbHelper.getAllFoodTrucks();
      setState(() {
        _foodTrucks = trucks;
      });
    } catch (e) {
      print('Error fetching food trucks: $e');
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await _dbHelper.getAllReviewsWithUsernames();
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> _fetchDishes() async {
    try {
      final dishes = await _dbHelper.getAllDishes();
      setState(() {
        _dishes = dishes;
      });
    } catch (e) {
      print('Error fetching dishes: $e');
    }
  }

  Future<void> _deleteUser(int userId, String username) async {
    final shouldDelete = await _showConfirmationDialog(username);
    if (shouldDelete) {
      try {
        await _dbHelper.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $username deleted successfully.')),
        );
        _fetchUsers(); // Refresh the user list
      } catch (e) {
        print('Error deleting user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user $username.')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String username) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content:
                  Text('Are you sure you want to delete $username\'s account?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteBooking(int bookingId, String foodTruckType) async {
    final shouldDelete = await _showBookingConfirmationDialog(foodTruckType);
    if (shouldDelete) {
      try {
        await _dbHelper.deleteBooking(bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Booking for $foodTruckType deleted successfully.')),
        );
        _fetchUserBookings(); // Refresh the bookings list
      } catch (e) {
        print('Error deleting booking: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete booking for $foodTruckType.')),
        );
      }
    }
  }

  Future<bool> _showBookingConfirmationDialog(String foodTruckType) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete the booking for $foodTruckType?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _logout() async {
    await AuthManager.setUserLoggedIn(false);
    await AuthManager.setUserId(null);
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _formatDate(String isoDateString) {
    try {
      final DateTime date = DateTime.parse(isoDateString);
      return DateFormat('dd MMM yyyy').format(date); // Example: "03 Jan 2025"
    } catch (e) {
      print('Error formatting date: $e');
      return isoDateString; // Fallback to the original string
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final TextEditingController nameController =
        TextEditingController(text: user['username']);
    final TextEditingController emailController =
        TextEditingController(text: user['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User Info'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedUser = {
                  'userid': user['userid'],
                  'username': nameController.text,
                  'email': emailController.text,
                };

                await _updateUserInfo(updatedUser);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserInfo(Map<String, dynamic> updatedUser) async {
    try {
      final rowsAffected = await _dbHelper.updateUser(updatedUser);

      if (rowsAffected > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User info updated successfully!')),
        );
        _fetchUsers(); // Refresh user list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user info!')),
        );
      }
    } catch (e) {
      print('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while updating user info.')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Review Management Methods
  // --------------------------------------------------------------------------

  Future<void> _deleteReview(int reviewId, String username) async {
    final shouldDelete = await _showReviewConfirmationDialog(username);
    if (shouldDelete) {
      try {
        await _dbHelper.deleteReview(reviewId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review by $username deleted successfully.')),
        );
        _fetchReviews(); // Refresh the reviews list
      } catch (e) {
        print('Error deleting review: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete review.')),
        );
      }
    }
  }

  Future<bool> _showReviewConfirmationDialog(String username) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete the review by $username?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // --------------------------------------------------------------------------
  // Dish Management Methods
  // --------------------------------------------------------------------------

  Future<void> _deleteDish(int dishId, String dishName) async {
    final shouldDelete = await _showDishConfirmationDialog(dishName);
    if (shouldDelete) {
      try {
        await _dbHelper.deleteDish(dishId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$dishName deleted successfully.')),
        );
        _fetchDishes();
      } catch (e) {
        print('Error deleting dish: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $dishName.')),
        );
      }
    }
  }

  Future<bool> _showDishConfirmationDialog(String dishName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete $dishName?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showAddDishDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text('Add New Dish (Global - Available to All Trucks)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Dish Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        quantityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    final newDish = {
                      'truckid':
                          1, // Default - dishes are global, not per-truck
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'image': 'assets/images/dishes/placeholder.jpg',
                    };

                    await _dbHelper.insertDish(newDish);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Dish added successfully! (Available to all trucks)')),
                    );
                    _fetchDishes();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDishDialog(Map<String, dynamic> dish) {
    final nameController = TextEditingController(text: dish['name']);
    final descriptionController =
        TextEditingController(text: dish['description']);
    final priceController =
        TextEditingController(text: dish['price'].toString());
    final quantityController =
        TextEditingController(text: dish['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Dish (Global - Available to All Trucks)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Dish Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final updatedDish = {
                      'truckid': dish['truckid'], // Keep existing truckid
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'image': dish['image'],
                    };

                    await _dbHelper.updateDish(dish['dishid'], updatedDish);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Dish updated successfully! (Available to all trucks)')),
                    );
                    _fetchDishes();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Sales Report Methods
  // --------------------------------------------------------------------------

  Future<void> _loadSalesReport() async {
    setState(() {
      _isLoadingReport = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedReportDate);
      final report = await _dbHelper.getSalesReportByDate(dateString);

      setState(() {
        _salesReport = report;
        _isLoadingReport = false;
      });
    } catch (e) {
      print('Error loading sales report: $e');
      setState(() {
        _isLoadingReport = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load sales report')),
      );
    }
  }

  Future<void> _selectReportDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _EnhancedDatePickerDialog(
          initialDate: _selectedReportDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          bookingDates: _bookingDates,
        );
      },
    );

    if (picked != null && picked != _selectedReportDate) {
      setState(() {
        _selectedReportDate = picked;
      });
      _loadSalesReport();
    }
  }

  Future<void> _exportReportAsPDF() async {
    if (_salesReport == null || _salesReport!['bookings'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      // No permission needed for app-specific directory on Android 13+

      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMM yyyy').format(_selectedReportDate);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Daily Sales Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Date: $dateStr',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Summary Section
              pw.Text(
                'Summary',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bookings:'),
                  pw.Text('${_salesReport!['totalBookings']}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Sales:'),
                  pw.Text(
                      'RM ${(_salesReport!['totalSales'] as double).toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Truck Booking Fees:'),
                  pw.Text(
                      'RM ${(_salesReport!['totalTruckFees'] as double).toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dish Sales:'),
                  pw.Text(
                      'RM ${(_salesReport!['totalDishSales'] as double).toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 20),

              // Truck Performance
              pw.Text(
                'Truck Performance',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ...(_salesReport!['truckRevenue'] as Map<String, double>)
                  .entries
                  .map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${entry.key}:'),
                          pw.Text(
                              'RM ${entry.value.toStringAsFixed(2)} (${(_salesReport!['truckBookingCount'] as Map<String, int>)[entry.key]} bookings)'),
                        ],
                      ),
                    ),
                  ),
              pw.SizedBox(height: 20),

              // Bookings Details
              pw.Text(
                'Booking Details',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Customer', 'Truck', 'Amount', 'Event Date'],
                data: (_salesReport!['bookings'] as List<Map<String, dynamic>>)
                    .map((booking) {
                  return [
                    booking['customer_name'] ?? 'N/A',
                    booking['foodtrucktype'] ?? 'N/A',
                    'RM ${((booking['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                    DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(booking['eventdate'])),
                  ];
                }).toList(),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerStyle:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      // Save PDF to Downloads folder
      final fileName =
          'sales_report_${DateFormat('yyyy_MM_dd').format(_selectedReportDate)}.pdf';
      final pdfBytes = await pdf.save();

      String? filePath;

      if (Platform.isAndroid) {
        // For Android, save to Downloads folder
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
      } else {
        // For iOS, save to documents directory
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
      }

      // Show success dialog with file location
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              const Text('PDF Saved Successfully!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your sales report has been saved to Downloads folder.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download,
                            size: 18, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Downloads Folder',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filePath ?? 'Download folder',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.insert_drive_file,
                            size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Open your Downloads folder to view the file.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error exporting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Food Truck Management Methods
  // --------------------------------------------------------------------------

  Future<void> _deleteFoodTruck(int truckId, String truckName) async {
    final shouldDelete = await _showFoodTruckConfirmationDialog(truckName);
    if (shouldDelete) {
      try {
        await _dbHelper.deleteFoodTruck(truckId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$truckName deleted successfully.')),
        );
        _fetchFoodTrucks(); // Refresh the food trucks list
      } catch (e) {
        print('Error deleting food truck: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $truckName.')),
        );
      }
    }
  }

  Future<bool> _showFoodTruckConfirmationDialog(String truckName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete $truckName?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showAddFoodTruckDialog() {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final packagesController = TextEditingController();
    String selectedImage = 'assets/images/foodTruckImages/malayTruck.jpg';
    String selectedAvailability = 'Available';

    final availableImages = [
      'assets/images/foodTruckImages/guatemala.jpg',
      'assets/images/foodTruckImages/steelWheel.jpg',
      'assets/images/foodTruckImages/iceCream.jpg',
      'assets/images/foodTruckImages/asianFoodie.jpg',
      'assets/images/foodTruckImages/mediterranean.jpg',
      'assets/images/foodTruckImages/malayTruck.jpg',
      'assets/images/foodTruckImages/indonesianFoodTruck.jpg',
      'assets/images/foodTruckImages/foodTruckGourmet.jpg',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Food Truck'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedImage,
                      decoration: const InputDecoration(labelText: 'Image'),
                      items: availableImages.map((img) {
                        return DropdownMenuItem(
                          value: img,
                          child: Text(img.split('/').last.split('.').first),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedImage = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          selectedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: packagesController,
                      decoration: const InputDecoration(
                        labelText: 'Packages (separate with |)',
                        hintText: 'Package 1|Package 2|Package 3',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedAvailability,
                      decoration:
                          const InputDecoration(labelText: 'Availability'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Available', child: Text('Available')),
                        DropdownMenuItem(
                            value: 'Unavailable', child: Text('Unavailable')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAvailability = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill required fields')),
                      );
                      return;
                    }

                    final newTruck = {
                      'name': nameController.text,
                      'image': selectedImage,
                      'type': typeController.text,
                      'description': descriptionController.text,
                      'packages': packagesController.text.split('|'),
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'availability': selectedAvailability,
                    };

                    await _dbHelper.insertFoodTruck(newTruck);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Food truck added successfully!')),
                    );
                    _fetchFoodTrucks();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditFoodTruckDialog(Map<String, dynamic> truck) {
    final nameController = TextEditingController(text: truck['name']);
    final typeController = TextEditingController(text: truck['type']);
    final descriptionController =
        TextEditingController(text: truck['description']);
    final priceController =
        TextEditingController(text: truck['price'].toString());
    final packages = truck['packages'] as List;
    final packagesController = TextEditingController(text: packages.join('|'));
    String selectedImage = truck['image'];
    String selectedAvailability = truck['availability'] ?? 'Available';

    final availableImages = [
      'assets/images/foodTruckImages/guatemala.jpg',
      'assets/images/foodTruckImages/steelWheel.jpg',
      'assets/images/foodTruckImages/iceCream.jpg',
      'assets/images/foodTruckImages/asianFoodie.jpg',
      'assets/images/foodTruckImages/mediterranean.jpg',
      'assets/images/foodTruckImages/malayTruck.jpg',
      'assets/images/foodTruckImages/indonesianFoodTruck.jpg',
      'assets/images/foodTruckImages/foodTruckGourmet.jpg',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Food Truck'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedImage,
                      decoration: const InputDecoration(labelText: 'Image'),
                      items: availableImages.map((img) {
                        return DropdownMenuItem(
                          value: img,
                          child: Text(img.split('/').last.split('.').first),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedImage = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          selectedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: packagesController,
                      decoration: const InputDecoration(
                        labelText: 'Packages (separate with |)',
                        hintText: 'Package 1|Package 2|Package 3',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedAvailability,
                      decoration:
                          const InputDecoration(labelText: 'Availability'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Available', child: Text('Available')),
                        DropdownMenuItem(
                            value: 'Unavailable', child: Text('Unavailable')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAvailability = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final updatedTruck = {
                      'name': nameController.text,
                      'image': selectedImage,
                      'type': typeController.text,
                      'description': descriptionController.text,
                      'packages': packagesController.text.split('|'),
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'availability': selectedAvailability,
                    };

                    await _dbHelper.updateFoodTruck(
                        truck['truckid'], updatedTruck);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Food truck updated successfully!')),
                    );
                    _fetchFoodTrucks();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Bookings'),
              Tab(text: 'Trucks'),
              Tab(text: 'Dishes'),
              Tab(text: 'Reviews'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Users Section
            _users.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              user['name'] != null && user['name'].isNotEmpty
                                  ? user['name'][0].toUpperCase()
                                  : user['username'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '@${user['username']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                      'Full Name', user['name'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                      'Username', '@${user['username']}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          user['email'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          user['phone'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.fingerprint,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'User ID: ${user['userid']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showEditUserDialog(user),
                                        icon: const Icon(Icons.edit,
                                            size: 18, color: Colors.blue),
                                        label: const Text('Edit',
                                            style:
                                                TextStyle(color: Colors.blue)),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.blue[50],
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _deleteUser(
                                            user['userid'], user['username']),
                                        icon: const Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        label: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red[50],
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
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
            // Bookings Section
            _userBookings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No bookings available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _userBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _userBookings[index];
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
                        margin: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text(
                            'User: ${booking['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Truck: ${booking['foodtrucktype']}\n'
                            'Total: RM ${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBooking(
                              booking['bookingid'],
                              booking['foodtrucktype'],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Email', booking['email']),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(
                                      'Phone', booking['phone'] ?? 'N/A'),
                                  const SizedBox(height: 4),
                                  _buildInfoRow('Booking Date',
                                      _formatDate(booking['book_date'])),
                                  const SizedBox(height: 4),
                                  _buildInfoRow('Event Date',
                                      _formatDate(booking['eventdate'])),
                                  const Divider(),
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
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
            // Food Trucks Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _showAddFoodTruckDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Food Truck'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _foodTrucks.isEmpty
                      ? const Center(
                          child: Text(
                            'No food trucks available.\nClick "Add New Food Truck" to get started.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _foodTrucks.length,
                          itemBuilder: (context, index) {
                            final truck = _foodTrucks[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    truck['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      );
                                    },
                                  ),
                                ),
                                title: Text(truck['name']),
                                subtitle: Text(
                                  '${truck['type']}\nRM ${truck['price']}\n${truck['availability']}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showEditFoodTruckDialog(truck),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteFoodTruck(
                                          truck['truckid'], truck['name']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Dishes Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _showAddDishDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Dish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _dishes.isEmpty
                      ? const Center(
                          child: Text(
                            'No dishes available.\nClick "Add New Dish" to get started.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _dishes.length,
                          itemBuilder: (context, index) {
                            final dish = _dishes[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.restaurant),
                                ),
                                title: Text(dish['name']),
                                subtitle: Text(
                                  'RM ${dish['price']} | Qty: ${dish['quantity']}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showEditDishDialog(dish),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteDish(
                                          dish['dishid'], dish['name']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Reviews Section
            _reviews.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No reviews available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final rating = (review['userreviewstar'] is int)
                          ? (review['userreviewstar'] as int).toDouble()
                          : (review['userreviewstar'] as double? ?? 0.0);

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              review['username'][0].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) {
                                  return Icon(
                                    Icons.star,
                                    size: 16,
                                    color:
                                        i < rating ? Colors.amber : Colors.grey,
                                  );
                                }),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (review['foodtruck_name'] != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, bottom: 4),
                                  child: Text(
                                    'Food Truck: ${review['foodtruck_name']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              Text(
                                review['userreview'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReview(
                              review['reviewid'],
                              review['username'],
                            ),
                            tooltip: 'Delete Review',
                          ),
                        ),
                      );
                    },
                  ),
            // Sales Reports Section
            _buildSalesReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assessment,
                          size: 32, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Daily Sales Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select a date to view sales report and export data',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date Selection Card
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
                  const Text(
                    'Report Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd MMMM yyyy')
                                    .format(_selectedReportDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _selectReportDate(context),
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Change'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingReport ? null : _loadSalesReport,
                      icon: _isLoadingReport
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                          _isLoadingReport ? 'Loading...' : 'Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Report Results
          if (_salesReport != null) ...[
            // Summary Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_salesReport!['totalBookings']} Bookings',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Total Sales',
                      'RM ${(_salesReport!['totalSales'] as double).toStringAsFixed(2)}',
                      Colors.green,
                      Icons.attach_money,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Truck Booking Fees',
                      'RM ${(_salesReport!['totalTruckFees'] as double).toStringAsFixed(2)}',
                      Colors.blue,
                      Icons.local_shipping,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Dish Sales',
                      'RM ${(_salesReport!['totalDishSales'] as double).toStringAsFixed(2)}',
                      Colors.orange,
                      Icons.restaurant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Truck Performance Card
            if ((_salesReport!['truckRevenue'] as Map<String, double>)
                .isNotEmpty)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Truck Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      ...(_salesReport!['truckRevenue'] as Map<String, double>)
                          .entries
                          .map((entry) {
                        final bookingCount = (_salesReport!['truckBookingCount']
                                as Map<String, int>)[entry.key] ??
                            0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.food_bank,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$bookingCount booking${bookingCount != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'RM ${entry.value.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Export Buttons
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
                    const Text(
                      'Export Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exportReportAsPDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export as PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bookings List
            if ((_salesReport!['bookings'] as List).isNotEmpty)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      ...(_salesReport!['bookings']
                              as List<Map<String, dynamic>>)
                          .map((booking) {
                        final price =
                            (booking['price'] as num?)?.toDouble() ?? 0.0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                booking['customer_name']?[0]?.toUpperCase() ??
                                    'N',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              booking['customer_name'] ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${booking['foodtrucktype']}\n'
                              'Event: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['eventdate']))}',
                            ),
                            trailing: Text(
                              'RM ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],

          // Empty State
          if (_salesReport == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No report generated yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a date and click "Generate Report"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // No Data State
          if (_salesReport != null &&
              (_salesReport!['bookings'] as List).isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There were no bookings on ${DateFormat('dd MMMM yyyy').format(_selectedReportDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Date Picker Dialog with Booking Date Highlights
class _EnhancedDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> bookingDates;

  const _EnhancedDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.bookingDates,
  });

  @override
  _EnhancedDatePickerDialogState createState() =>
      _EnhancedDatePickerDialogState();
}

class _EnhancedDatePickerDialogState extends State<_EnhancedDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _hasBooking(DateTime date) {
    return widget.bookingDates
        .any((bookingDate) => _isSameDay(bookingDate, date));
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDayOfMonth = _displayedMonth;
    final lastDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

    List<DateTime> days = [];

    // Add empty slots for days before the first day of the month
    final firstWeekday =
        firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sun-Sat)
    for (int i = 0; i < firstWeekday; i++) {
      days.add(DateTime(1900, 1, 1)); // Placeholder for empty cells
    }

    // Add all days in the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month, day));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Report Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Date Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.edit, size: 20, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Month Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _displayedMonth.isAfter(widget.firstDate)
                      ? _previousMonth
                      : null,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_displayedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _displayedMonth.isBefore(DateTime(
                          widget.lastDate.year, widget.lastDate.month, 1))
                      ? _nextMonth
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];

                // Empty cell for padding
                if (date.year == 1900) {
                  return const SizedBox();
                }

                final isSelected = _isSameDay(date, _selectedDate);
                final hasBooking = _hasBooking(date);
                final isToday = _isSameDay(date, DateTime.now());
                final isFuture = date.isAfter(widget.lastDate);

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple
                          : hasBooking
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isToday && !isSelected
                          ? Border.all(color: Colors.deepPurple, width: 1.5)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || hasBooking
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isFuture
                                  ? Colors.grey[400]
                                  : isSelected
                                      ? Colors.white
                                      : hasBooking
                                          ? Colors.green[800]
                                          : Colors.black87,
                            ),
                          ),
                        ),
                        // Booking indicator dot
                        if (hasBooking && !isSelected)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.green[700]!, width: 1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Days with bookings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
