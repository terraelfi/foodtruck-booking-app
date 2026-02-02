import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> previousReviews = [];
  List<Map<String, String>> foodNews = [];

  @override
  void initState() {
    super.initState();
    // Defer heavy operations until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
      _fetchFoodNews();
    });
  }

  Future<void> _fetchReviews() async {
    try {
      // Simulate fetching reviews from database
      final reviews = await DatabaseHelper().getAllReviewsWithUsernames();
      setState(() {
        previousReviews = reviews.take(5).toList(); // Limit to 5 reviews
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> _fetchFoodNews() async {
    setState(() {
      foodNews = [
        {
          'title': 'Top Food Trucks in Your City',
          'description': 'Explore the best food trucks around you this month.',
          'image': 'assets/images/newsImage/food_truck_1.jpg',
        },
        {
          'title': 'How Food Trucks Are Revolutionizing Street Food',
          'description': 'A deep dive into the growing food truck culture.',
          'image': 'assets/images/newsImage/food_truck_2.jpg',
        },
        {
          'title': '5 Must-Try Street Foods This Week',
          'description':
              'Discover the tastiest dishes from food trucks near you.',
          'image': 'assets/images/newsImage/food_truck_3.jpg',
        },
      ]..shuffle(); // Shuffle newsss
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blueAccent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchReviews();
          await _fetchFoodNews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food News Section
                const Text(
                  'Food News:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: foodNews.length,
                  itemBuilder: (context, index) {
                    final news = foodNews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8.0),
                            ),
                            child: Image.asset(
                              news['image']!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              cacheWidth: 800, // Optimize image loading
                              cacheHeight: 400,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news['title']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  news['description']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Previous Reviews Section
                const Text(
                  'Previous Reviews:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                previousReviews.isEmpty
                    ? const Center(child: Text('No reviews available.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: previousReviews.length,
                        itemBuilder: (context, index) {
                          final review = previousReviews[index];
                          final truckName =
                              review['foodtruck_name'] ?? 'Unknown Truck';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Username: ${review['username']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Colors.blueAccent),
                                    ),
                                    child: Text(
                                      '🚚 $truckName',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        'Rating: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      ...List.generate(5, (i) {
                                        final rating =
                                            review['userreviewstar'] as num;
                                        return Icon(
                                          Icons.star,
                                          size: 14,
                                          color: i < rating.toInt()
                                              ? Colors.amber
                                              : Colors.grey[300],
                                        );
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${review['userreviewstar']})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    review['userreview'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
