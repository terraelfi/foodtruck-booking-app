import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class ReviewPage extends StatefulWidget {
  final int userId;
  final String foodTruckName; // identify which truck is being reviewed

  const ReviewPage({
    Key? key,
    required this.userId,
    required this.foodTruckName,
  }) : super(key: key);

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      // currently fetches all reviews with usernames
      final reviewData = await DatabaseHelper().getAllReviewsWithUsernames();
      setState(() {
        reviews = reviewData;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isNotEmpty &&
        double.tryParse(_ratingController.text) != null) {
      try {
        final review = {
          'userid': widget.userId,
          'userreview': _reviewController.text,
          'userreviewstar': double.parse(_ratingController.text),
          'foodtruck_name': widget.foodTruckName, // link to truck
        };
        await DatabaseHelper().insertReview(review);
        _reviewController.clear();
        _ratingController.clear();
        _fetchReviews();
      } catch (e) {
        print('Error submitting review: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid review and rating.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews - ${widget.foodTruckName}'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Submit a Review:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Enter your review',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Enter your rating (0-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: _submitReview,
            child: const Text('Submit Review'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Existing Reviews:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: reviews.isEmpty
                ? const Center(child: Text('No reviews yet.'))
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(
                            'Username : ${review['username']}'
                            '\nRating : ${review['userreviewstar']}',
                          ),
                          subtitle: Text(review['userreview']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
