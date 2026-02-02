import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../screens/ReviewPage.dart';
import '../screens/dish_selection_screen.dart';

class FoodTruckSelectionPage extends StatefulWidget {
  final int userId;

  const FoodTruckSelectionPage({Key? key, required this.userId})
      : super(key: key);

  @override
  State<FoodTruckSelectionPage> createState() => _FoodTruckSelectionPageState();
}

class _FoodTruckSelectionPageState extends State<FoodTruckSelectionPage> {
  List<Map<String, dynamic>> foodTrucks = [];

  // truckName -> average rating
  final Map<String, double> _avgRatings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dbHelper = DatabaseHelper();

    // Load all food trucks from database
    final trucks = await dbHelper.getAllFoodTrucks();

    // Load all ratings in a single query (more efficient)
    final allRatings = await dbHelper.getAllAverageRatings();

    if (mounted) {
      setState(() {
        foodTrucks = trucks;
        _avgRatings.clear();
        _avgRatings.addAll(allRatings);
        _isLoading = false;
      });
    }
  }

  void _showTruckDetails(BuildContext context, Map<String, dynamic> truck) async {
    // Fetch reviews for this truck
    final dbHelper = DatabaseHelper();
    final reviews = await dbHelper.getReviewsForTruck(truck['name']);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    truck['image'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    cacheHeight: 400,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  truck['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      truck['type'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: truck['availability'] == 'Available'
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: truck['availability'] == 'Available'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        truck['availability'] ?? 'Available',
                        style: TextStyle(
                          fontSize: 12,
                          color: truck['availability'] == 'Available'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  truck['description'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Available Packages:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...truck['packages'].map<Widget>((package) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              package,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                Text(
                  'Booking Fee: RM${truck['price'].toString()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to dish selection - truck fee will be added automatically
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DishSelectionScreen(
                            userId: widget.userId,
                            foodTruck: truck,
                          ),
                        ),
                      );
                    },
                    icon:
                        const Icon(Icons.restaurant_menu, color: Colors.white),
                    label: const Text(
                      'Select This Truck & Order Dishes',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPage(
                            userId: widget.userId,
                            foodTruckName: truck['name'],
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.rate_review, color: Colors.white),
                    label: const Text(
                      'Write Review',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Previous Reviews Section with Filter
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.reviews, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Previous Reviews (${reviews.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Star Rating Filter Section
                Builder(
                  builder: (context) {
                    // Count reviews by star rating
                    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
                    for (var review in reviews) {
                      int star = (review['userreviewstar'] as num).round();
                      if (star >= 1 && star <= 5) {
                        starCounts[star] = (starCounts[star] ?? 0) + 1;
                      }
                    }
                    
                    return _ReviewsWithFilter(
                      reviews: reviews,
                      starCounts: starCounts,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Food Trucks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : foodTrucks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Food Trucks Available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for available food trucks',
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
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: foodTrucks.length,
                  itemBuilder: (context, index) {
                    final truck = foodTrucks[index];
                    final name = truck['name'] as String;
                    final avg = _avgRatings[name] ?? 0.0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _showTruckDetails(context, truck),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.asset(
                                  truck['image'],
                                  fit: BoxFit.cover,
                                  cacheWidth: 400, // Optimize image loading
                                  cacheHeight: 400,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    truck['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          truck['type'],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Availability Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          truck['availability'] == 'Available'
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      truck['availability'] ?? 'Available',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            truck['availability'] == 'Available'
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) {
                                          final filled = avg >= i + 1;
                                          return Icon(
                                            Icons.star,
                                            size: 13,
                                            color: filled
                                                ? Colors.amber
                                                : Colors.grey,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Widget to display reviews with star rating filter
class _ReviewsWithFilter extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final Map<int, int> starCounts;

  const _ReviewsWithFilter({
    required this.reviews,
    required this.starCounts,
  });

  @override
  State<_ReviewsWithFilter> createState() => _ReviewsWithFilterState();
}

class _ReviewsWithFilterState extends State<_ReviewsWithFilter> {
  int? selectedStar; // null means "All"

  List<Map<String, dynamic>> get filteredReviews {
    if (selectedStar == null) {
      return widget.reviews;
    }
    return widget.reviews.where((review) {
      int star = (review['userreviewstar'] as num).round();
      return star == selectedStar;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star Filter Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // "All" button
              _buildFilterChip(
                label: 'All',
                count: widget.reviews.length,
                isSelected: selectedStar == null,
                onTap: () => setState(() => selectedStar = null),
              ),
              const SizedBox(width: 8),
              // Star buttons (5 to 1)
              for (int star = 5; star >= 1; star--) ...[
                _buildFilterChip(
                  label: '$star',
                  count: widget.starCounts[star] ?? 0,
                  isSelected: selectedStar == star,
                  onTap: () => setState(() => selectedStar = star),
                  showStar: true,
                ),
                if (star > 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Filtered Reviews List
        filteredReviews.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedStar == null
                            ? 'No reviews yet'
                            : 'No $selectedStar-star reviews',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (selectedStar == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to review this truck!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : Column(
                children: filteredReviews.map((review) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  review['username'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['username'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          final rating =
                                              review['userreviewstar'] as num;
                                          return Icon(
                                            Icons.star,
                                            size: 16,
                                            color: i < rating.toInt()
                                                ? Colors.amber
                                                : Colors.grey[300],
                                          );
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${review['userreviewstar']})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            review['userreview'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool showStar = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.amber[700]! : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStar) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.amber,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber[700]
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
