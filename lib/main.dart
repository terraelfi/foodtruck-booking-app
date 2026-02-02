import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/AdminScreen.dart';
import 'utils/auth_manager.dart';
import 'login_page.dart';
import 'database/database_helper.dart';

// =============================================================================
// TEST DATA SEEDING - Call these functions to populate test reviews
// =============================================================================
//
// To seed test reviews, uncomment the line in main() below or call manually:
//   await seedTestReviews();
//
// To clear test reviews:
//   await clearTestReviews();
// =============================================================================

/// Seeds test reviews for all food trucks (2-35 reviews per truck)
Future<void> seedTestReviews({int reviewsPerTruck = 15}) async {
  print('🌱 Starting to seed test reviews...');
  await DatabaseHelper().seedTestReviews(reviewsPerTruck: reviewsPerTruck);
  print('✅ Test reviews seeded successfully!');
}

/// Clears all test reviews and test users
Future<void> clearTestReviews() async {
  print('🧹 Clearing test reviews...');
  await DatabaseHelper().clearTestReviews();
  print('✅ Test reviews cleared!');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // UNCOMMENT THE LINE BELOW TO SEED TEST REVIEWS (run once, then comment out)
  // ==========================================================================
  // await seedTestReviews(reviewsPerTruck: 20); // Adds 20 reviews per truck
  // ==========================================================================
  // UNCOMMENT THE LINE BELOW TO CLEAR ALL TEST REVIEWS
  // ==========================================================================
  // await clearTestReviews();
  // ==========================================================================

  // Load auth state asynchronously but don't block rendering
  final bool isFirstTime = await AuthManager.isFirstTime();
  final bool isLoggedIn = await AuthManager.isUserLoggedIn();
  final int? userId = await AuthManager.getUserId();

  print(
      'Main: App started. isFirstTime: $isFirstTime, isLoggedIn: $isLoggedIn, userId: $userId');

  runApp(
    MaterialApp(
      // Performance optimizations
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isFirstTime
          ? const HomePage()
          : (isLoggedIn && userId != null)
              ? MainNavigationScreen(
                  userId: userId,
                  isAdmin: false,
                )
              : LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/admin': (context) => const AdminScreen(),
        // REMOVED the old '/reviews' route that didn't pass foodTruckName
        // You now open ReviewPage from FoodTruckSelectionPage using:
        // ReviewPage(userId: widget.userId, foodTruckName: truck['name'])
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _getStarted(BuildContext context) async {
    // Mark that the user has seen the welcome screen
    await AuthManager.setFirstTime(false);

    print('HomePage: Get Started clicked, redirecting to LoginPage.');

    // Always go to LoginPage from the welcome screen
    // Let the login process determine if user is admin or regular user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Food Truck Booking App",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: Column(
        children: [
          const Expanded(
            child: CarouselWithText(),
          ),
          // Get Started Button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _getStarted(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CarouselWithText extends StatefulWidget {
  const CarouselWithText({super.key});

  @override
  _CarouselWithTextState createState() => _CarouselWithTextState();
}

class _CarouselWithTextState extends State<CarouselWithText> {
  final List<String> images = [
    'assets/images/foodTruckImages/guatemala.jpg',
    'assets/images/foodTruckImages/steelWheel.jpg',
    'assets/images/foodTruckImages/iceCream.jpg',
  ];

  final List<String> titles = [
    'Find One Near You',
    'Discover Our Range',
    'Book Now!',
  ];

  final List<String> descriptions = [
    'Locate food trucks available near you and explore the latest models in your area.',
    'Explore a wide variety of food trucks tailored to meet your needs and preferences.',
    'Ready to find your perfect food truck? Book Now! Take the first step towards your culinary adventure on wheels!',
  ];

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                titles[currentIndex],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Carousel
              Center(
                child: CarouselSlider.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index, realIndex) {
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width * 0.8,
                            cacheWidth: 800,
                            cacheHeight: 600,
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 280,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                    onPageChanged: (index, reason) {
                      if (mounted) {
                        setState(() {
                          currentIndex = index;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: currentIndex == entry.key ? 12.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == entry.key
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  descriptions[currentIndex],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
