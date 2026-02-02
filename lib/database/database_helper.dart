import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'foodtruck.db');
    return await openDatabase(
      path,
      version: 6, // CHANGED: 5 -> 6 (adding dish details to bookings)
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
      readOnly: false,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users(
        userid INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Cart Table
    await db.execute('''
      CREATE TABLE cart(
        cartid INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER NOT NULL,
        dishid INTEGER NOT NULL,
        dish_name TEXT NOT NULL,
        foodtruck_name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price REAL NOT NULL,
        booking_date TEXT NOT NULL,
        FOREIGN KEY (userid) REFERENCES users (userid),
        FOREIGN KEY (dishid) REFERENCES dishes (dishid)
      )
    ''');

    // Truck Bookings Table
    await db.execute('''
      CREATE TABLE truckbook(
        bookid INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER NOT NULL,
        book_date TEXT NOT NULL,
        booktime TEXT NOT NULL,
        eventdate TEXT NOT NULL,
        eventtime TEXT NOT NULL,
        foodtrucktype TEXT NOT NULL,
        numberofdays INTEGER NOT NULL,
        price REAL NOT NULL,
        truck_fee REAL NOT NULL DEFAULT 0,
        dishes_ordered TEXT,
        FOREIGN KEY (userid) REFERENCES users (userid)
      )
    ''');

    // Reviews Table
    await db.execute('''
      CREATE TABLE review(
        reviewid INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER NOT NULL,
        userreview TEXT NOT NULL,
        userreviewstar REAL NOT NULL,
        foodtruck_name TEXT,
        FOREIGN KEY (userid) REFERENCES users (userid)
      )
    ''');

    // Administrators Table
    await db.execute('''
      CREATE TABLE administrator(
        adminid INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Food Trucks Table
    await db.execute('''
      CREATE TABLE food_trucks(
        truckid INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        packages TEXT NOT NULL,
        price REAL NOT NULL,
        availability TEXT NOT NULL DEFAULT 'Available'
      )
    ''');

    // Dishes Table
    await db.execute('''
      CREATE TABLE dishes(
        dishid INTEGER PRIMARY KEY AUTOINCREMENT,
        truckid INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image TEXT NOT NULL,
        FOREIGN KEY (truckid) REFERENCES food_trucks (truckid) ON DELETE CASCADE
      )
    ''');

    // Insert default admin
    await db
        .insert('administrator', {'username': 'admin', 'password': 'admin123'});

    // Insert default food trucks
    await _insertDefaultFoodTrucks(db);

    // Insert default dishes
    await _insertDefaultDishes(db);
  }

  // Insert default food trucks
  Future<void> _insertDefaultFoodTrucks(Database db) async {
    final defaultTrucks = [
      {
        'name': 'Guatemala Food Truck',
        'image': 'assets/images/foodTruckImages/guatemala.jpg',
        'type': 'Mexican & Central American',
        'description':
            'Authentic Central American cuisine with modern amenities.',
        'packages': 'Basic Display Counter|Custom Banner|LED Lighting',
        'price': 997.0,
        'availability': 'Available',
      },
      {
        'name': 'Steel Wheel Truck',
        'image': 'assets/images/foodTruckImages/steelWheel.jpg',
        'type': 'American Street Food',
        'description': 'Classic American street food with a modern twist.',
        'packages': 'Premium Counter Setup|Digital Menu Board|Awning',
        'price': 2230.0,
        'availability': 'Available',
      },
      {
        'name': 'Ice Cream Delight',
        'image': 'assets/images/foodTruckImages/iceCream.jpg',
        'type': 'Desserts & Ice Cream',
        'description': 'Gourmet ice cream and frozen treats.',
        'packages': 'Freezer Display|Toppings Station|Customizable Lighting',
        'price': 1780.0,
        'availability': 'Available',
      },
      {
        'name': 'Asian Fusion Express',
        'image': 'assets/images/foodTruckImages/asianFoodie.jpg',
        'type': 'Asian Fusion',
        'description': 'Modern Asian fusion cuisine with traditional flavors.',
        'packages': 'Wok Station|Steam Table|LED Menu Display',
        'price': 875.0,
        'availability': 'Available',
      },
      {
        'name': 'Mediterranean Wheels',
        'image': 'assets/images/foodTruckImages/mediterranean.jpg',
        'type': 'Mediterranean',
        'description': 'Authentic Mediterranean street food experience.',
        'packages': 'Gyro Station|Salad Bar|Custom Signage',
        'price': 1034.0,
        'availability': 'Available',
      },
    ];

    for (var truck in defaultTrucks) {
      await db.insert('food_trucks', truck);
    }
  }

  // Insert default dishes (10 per truck)
  // NOTE: This is ONLY used for initial database seeding
  // Once inserted, quantities are stored in database and decrease on orders
  Future<void> _insertDefaultDishes(Database db) async {
    // Check if dishes already exist
    final existingDishes = await db.query('dishes', limit: 1);
    if (existingDishes.isNotEmpty) {
      print('Dishes already exist, skipping default insertion');
      return; // Skip if dishes already exist
    }

    // Generic placeholder dishes that work for all trucks
    // These are inserted ONCE into the database
    final defaultDishes = [
      {
        'name': 'Signature Special',
        'description': 'Our most popular dish with authentic flavors',
        'price': 12.99,
        'quantity': 50, // Starting quantity - will decrease as users order
        'image': 'assets/images/dishes/dish1.jpg',
      },
    ];

    // Insert dishes only for the first truck (truck ID 1)
    // Admin can add more dishes for other trucks manually
    for (var dish in defaultDishes) {
      await db.insert('dishes', {
        'truckid': 1, // Only insert for first truck
        'name': dish['name'],
        'description': dish['description'],
        'price': dish['price'],
        'quantity': dish['quantity'],
        'image': dish['image'],
      });
    }
  }

  // ADDED: upgrade hook to add new column for existing databases
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE review ADD COLUMN foodtruck_name TEXT;',
      );
    }
    if (oldVersion < 4) {
      // Create food_trucks table
      await db.execute('''
        CREATE TABLE food_trucks(
          truckid INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          image TEXT NOT NULL,
          type TEXT NOT NULL,
          description TEXT NOT NULL,
          packages TEXT NOT NULL,
          price REAL NOT NULL
        )
      ''');
      // Insert default food trucks
      await _insertDefaultFoodTrucks(db);
    }
    if (oldVersion < 5) {
      // Add availability column to food_trucks
      await db.execute(
        'ALTER TABLE food_trucks ADD COLUMN availability TEXT NOT NULL DEFAULT "Available";',
      );

      // Create dishes table
      await db.execute('''
        CREATE TABLE dishes(
          dishid INTEGER PRIMARY KEY AUTOINCREMENT,
          truckid INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          image TEXT NOT NULL,
          FOREIGN KEY (truckid) REFERENCES food_trucks (truckid) ON DELETE CASCADE
        )
      ''');

      // Insert default dishes
      await _insertDefaultDishes(db);

      // Recreate cart table with new structure
      await db.execute('DROP TABLE IF EXISTS cart');
      await db.execute('''
        CREATE TABLE cart(
          cartid INTEGER PRIMARY KEY AUTOINCREMENT,
          userid INTEGER NOT NULL,
          dishid INTEGER NOT NULL,
          dish_name TEXT NOT NULL,
          foodtruck_name TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          price REAL NOT NULL,
          booking_date TEXT NOT NULL,
          FOREIGN KEY (userid) REFERENCES users (userid),
          FOREIGN KEY (dishid) REFERENCES dishes (dishid)
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add truck_fee and dishes_ordered columns to truckbook
      await db.execute(
        'ALTER TABLE truckbook ADD COLUMN truck_fee REAL NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE truckbook ADD COLUMN dishes_ordered TEXT;',
      );
    }
  }

  // --------------------------------------------------------------------------
  // User Operations
  // --------------------------------------------------------------------------

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users',
        columns: ['userid', 'name', 'username', 'email', 'phone']);
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'userid = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Insert a new user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Update user information
  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'userid = ?',
      whereArgs: [user['userid']],
    );
  }

  // Delete a user
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete('users', where: 'userid = ?', whereArgs: [userId]);
  }

  // Authenticate user by username and password
  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // --------------------------------------------------------------------------
  // Booking Operations
  // --------------------------------------------------------------------------

  // Get all bookings
  Future<List<Map<String, dynamic>>> getAllUserBookings() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.bookid AS bookingid, u.name, u.email, u.phone, t.foodtrucktype, 
             t.book_date, t.eventdate, t.price, t.truck_fee, t.dishes_ordered
      FROM users u
      INNER JOIN truckbook t ON u.userid = t.userid
      ORDER BY t.book_date DESC
    ''');
  }

  // Insert a new booking
  Future<int> insertBooking(Map<String, dynamic> booking) async {
    final db = await database;
    return await db.insert('truckbook', booking);
  }

  // Get bookings for a specific user
  Future<List<Map<String, dynamic>>> getUserBookings(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, u.name, u.email, u.phone
      FROM truckbook t
      INNER JOIN users u ON t.userid = u.userid
      WHERE t.userid = ?
      ORDER BY t.book_date DESC
    ''', [userId]);
  }

  // Delete a booking
  Future<int> deleteBooking(int bookingId) async {
    final db = await database;
    return await db
        .delete('truckbook', where: 'bookid = ?', whereArgs: [bookingId]);
  }

  // Save multiple bookings
  Future<void> saveTruckBook(List<Map<String, dynamic>> bookings) async {
    final db = await database;
    for (var booking in bookings) {
      await db.insert('truckbook', booking);
    }
  }

  // --------------------------------------------------------------------------
  // Cart Operations
  // --------------------------------------------------------------------------

  // Get cart items for a user with dish details
  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT c.*, d.image as dish_image, d.description as dish_description
        FROM cart c
        LEFT JOIN dishes d ON c.dishid = d.dishid
        WHERE c.userid = ?
        ORDER BY c.cartid DESC
      ''', [userId]);
    } catch (e) {
      print('Error getting cart items: $e');
      return [];
    }
  }

  // Add dish to cart
  Future<int> addDishToCart(Map<String, dynamic> cartItem) async {
    try {
      if (cartItem['dishid'] == null ||
          cartItem['dish_name'] == null ||
          cartItem['foodtruck_name'] == null ||
          cartItem['price'] == null) {
        throw Exception('Invalid cart item: Missing required fields');
      }
      final db = await database;
      return await db.insert('cart', cartItem);
    } catch (e) {
      print('Error adding dish to cart: $e');
      return -1;
    }
  }

  // Delete a cart item
  Future<int> deleteCartItem(int cartId) async {
    try {
      final db = await database;
      return await db.delete('cart', where: 'cartid = ?', whereArgs: [cartId]);
    } catch (e) {
      print('Error deleting cart item: $e');
      return 0;
    }
  }

  // Update cart item quantity
  Future<int> updateCartItemQuantity(int cartId, int quantity) async {
    try {
      final db = await database;
      return await db.update(
        'cart',
        {'quantity': quantity},
        where: 'cartid = ?',
        whereArgs: [cartId],
      );
    } catch (e) {
      print('Error updating cart item quantity: $e');
      return 0;
    }
  }

  // --------------------------------------------------------------------------
  // Review Operations
  // --------------------------------------------------------------------------

  // Insert a review
  Future<int> insertReview(Map<String, dynamic> review) async {
    final db = await database;
    return await db.insert('review', review);
  }

  // Get all reviews with usernames
  Future<List<Map<String, dynamic>>> getAllReviewsWithUsernames() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT r.reviewid, r.userreview, r.userreviewstar, r.foodtruck_name, u.username
      FROM review r
      INNER JOIN users u ON r.userid = u.userid
      ORDER BY r.reviewid DESC
    ''');
  }

  // Get reviews for a specific food truck with usernames
  Future<List<Map<String, dynamic>>> getReviewsForTruck(
      String truckName) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT r.reviewid, r.userreview, r.userreviewstar, r.foodtruck_name, u.username
      FROM review r
      INNER JOIN users u ON r.userid = u.userid
      WHERE r.foodtruck_name = ?
      ORDER BY r.reviewid DESC
    ''', [truckName]);
  }

  // Delete a review (Admin function)
  Future<int> deleteReview(int reviewId) async {
    try {
      final db = await database;
      return await db.delete(
        'review',
        where: 'reviewid = ?',
        whereArgs: [reviewId],
      );
    } catch (e) {
      print('Error deleting review: $e');
      return 0;
    }
  }

  // Get reviews by a specific user
  Future<List<Map<String, dynamic>>> getReviewsByUser(int userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT r.reviewid, r.userreview, r.userreviewstar, r.foodtruck_name, u.username
        FROM review r
        INNER JOIN users u ON r.userid = u.userid
        WHERE r.userid = ?
        ORDER BY r.reviewid DESC
      ''', [userId]);
    } catch (e) {
      print('Error getting reviews by user: $e');
      return [];
    }
  }

  // ADDED: get average rating per food truck
  Future<double> getAverageRatingForTruck(String truckName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT AVG(userreviewstar) AS avgRating '
        'FROM review WHERE foodtruck_name = ?',
        [truckName],
      );
      if (result.isEmpty || result.first['avgRating'] == null) return 0.0;
      return (result.first['avgRating'] as num).toDouble();
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  // ADDED: get all average ratings at once (more efficient)
  Future<Map<String, double>> getAllAverageRatings() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT foodtruck_name, AVG(userreviewstar) AS avgRating '
        'FROM review '
        'WHERE foodtruck_name IS NOT NULL '
        'GROUP BY foodtruck_name',
      );

      final Map<String, double> ratings = {};
      for (final row in result) {
        final name = row['foodtruck_name'] as String?;
        final avg = row['avgRating'] as num?;
        if (name != null && avg != null) {
          ratings[name] = avg.toDouble();
        }
      }
      return ratings;
    } catch (e) {
      print('Error getting all average ratings: $e');
      return {};
    }
  }

  // --------------------------------------------------------------------------
  // Admin Operations
  // --------------------------------------------------------------------------

  // Authenticate admin
  Future<Map<String, dynamic>?> getAdmin(
      String username, String password) async {
    final db = await database;
    final result = await db.query(
      'administrator',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Get admin by ID
  Future<Map<String, dynamic>?> getAdminById(int userId) async {
    final db = await database;
    final result = await db.query(
      'administrator',
      where: 'adminid = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // --------------------------------------------------------------------------
  // Food Truck Operations
  // --------------------------------------------------------------------------

  // Get all food trucks
  Future<List<Map<String, dynamic>>> getAllFoodTrucks() async {
    try {
      final db = await database;
      final result = await db.query('food_trucks', orderBy: 'truckid ASC');

      // Convert packages from pipe-separated string to List
      return result.map((truck) {
        final Map<String, dynamic> truckMap = Map.from(truck);
        final packagesString = truck['packages'] as String;
        truckMap['packages'] = packagesString.split('|');
        return truckMap;
      }).toList();
    } catch (e) {
      print('Error getting all food trucks: $e');
      return [];
    }
  }

  // Get food truck by ID
  Future<Map<String, dynamic>?> getFoodTruckById(int truckId) async {
    try {
      final db = await database;
      final result = await db.query(
        'food_trucks',
        where: 'truckid = ?',
        whereArgs: [truckId],
      );

      if (result.isNotEmpty) {
        final truck = Map<String, dynamic>.from(result.first);
        final packagesString = truck['packages'] as String;
        truck['packages'] = packagesString.split('|');
        return truck;
      }
      return null;
    } catch (e) {
      print('Error getting food truck by ID: $e');
      return null;
    }
  }

  // Insert a new food truck
  Future<int> insertFoodTruck(Map<String, dynamic> truck) async {
    try {
      final db = await database;

      // Convert packages List to pipe-separated string
      final Map<String, dynamic> truckData = Map.from(truck);
      if (truck['packages'] is List) {
        truckData['packages'] = (truck['packages'] as List).join('|');
      }

      return await db.insert('food_trucks', truckData);
    } catch (e) {
      print('Error inserting food truck: $e');
      return -1;
    }
  }

  // Update food truck
  Future<int> updateFoodTruck(int truckId, Map<String, dynamic> truck) async {
    try {
      final db = await database;

      // Convert packages List to pipe-separated string
      final Map<String, dynamic> truckData = Map.from(truck);
      if (truck['packages'] is List) {
        truckData['packages'] = (truck['packages'] as List).join('|');
      }

      return await db.update(
        'food_trucks',
        truckData,
        where: 'truckid = ?',
        whereArgs: [truckId],
      );
    } catch (e) {
      print('Error updating food truck: $e');
      return 0;
    }
  }

  // Delete food truck
  Future<int> deleteFoodTruck(int truckId) async {
    try {
      final db = await database;
      return await db.delete(
        'food_trucks',
        where: 'truckid = ?',
        whereArgs: [truckId],
      );
    } catch (e) {
      print('Error deleting food truck: $e');
      return 0;
    }
  }

  // --------------------------------------------------------------------------
  // Dish Operations
  // --------------------------------------------------------------------------

  // Get all dishes for a specific food truck
  Future<List<Map<String, dynamic>>> getDishesByTruck(int truckId) async {
    try {
      final db = await database;
      return await db.query(
        'dishes',
        where: 'truckid = ?',
        whereArgs: [truckId],
        orderBy: 'dishid ASC',
      );
    } catch (e) {
      print('Error getting dishes by truck: $e');
      return [];
    }
  }

  // Get all dishes (for admin)
  Future<List<Map<String, dynamic>>> getAllDishes() async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT d.*, ft.name as truck_name
        FROM dishes d
        INNER JOIN food_trucks ft ON d.truckid = ft.truckid
        ORDER BY d.truckid, d.dishid
      ''');
    } catch (e) {
      print('Error getting all dishes: $e');
      return [];
    }
  }

  // Get all dishes globally (not filtered by truck) - for users
  Future<List<Map<String, dynamic>>> getAllDishesGlobal() async {
    try {
      final db = await database;
      return await db.query(
        'dishes',
        orderBy: 'dishid ASC',
      );
    } catch (e) {
      print('Error getting all dishes globally: $e');
      return [];
    }
  }

  // Get dish by ID
  Future<Map<String, dynamic>?> getDishById(int dishId) async {
    try {
      final db = await database;
      final result = await db.query(
        'dishes',
        where: 'dishid = ?',
        whereArgs: [dishId],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting dish by ID: $e');
      return null;
    }
  }

  // Insert a new dish
  Future<int> insertDish(Map<String, dynamic> dish) async {
    try {
      final db = await database;
      return await db.insert('dishes', dish);
    } catch (e) {
      print('Error inserting dish: $e');
      return -1;
    }
  }

  // Update dish
  Future<int> updateDish(int dishId, Map<String, dynamic> dish) async {
    try {
      final db = await database;
      return await db.update(
        'dishes',
        dish,
        where: 'dishid = ?',
        whereArgs: [dishId],
      );
    } catch (e) {
      print('Error updating dish: $e');
      return 0;
    }
  }

  // Delete dish
  Future<int> deleteDish(int dishId) async {
    try {
      final db = await database;
      return await db.delete(
        'dishes',
        where: 'dishid = ?',
        whereArgs: [dishId],
      );
    } catch (e) {
      print('Error deleting dish: $e');
      return 0;
    }
  }

  // Update dish quantity
  Future<int> updateDishQuantity(int dishId, int newQuantity) async {
    try {
      final db = await database;
      return await db.update(
        'dishes',
        {'quantity': newQuantity},
        where: 'dishid = ?',
        whereArgs: [dishId],
      );
    } catch (e) {
      print('Error updating dish quantity: $e');
      return 0;
    }
  }

  // Clean up duplicate dishes (keep only one per truck)
  Future<void> cleanupDuplicateDishes() async {
    try {
      final db = await database;

      // Get all dishes grouped by truck and name
      final dishes = await db.rawQuery('''
        SELECT MIN(dishid) as keep_id, truckid, name, COUNT(*) as count
        FROM dishes
        GROUP BY truckid, name
        HAVING count > 1
      ''');

      // Delete duplicates
      for (var dish in dishes) {
        await db.delete(
          'dishes',
          where: 'truckid = ? AND name = ? AND dishid != ?',
          whereArgs: [dish['truckid'], dish['name'], dish['keep_id']],
        );
      }

      print('Cleaned up duplicate dishes');
    } catch (e) {
      print('Error cleaning up duplicate dishes: $e');
    }
  }

  // --------------------------------------------------------------------------
  // Sales Report Operations
  // --------------------------------------------------------------------------

  // Get sales report for a specific date
  Future<Map<String, dynamic>> getSalesReportByDate(String date) async {
    try {
      final db = await database;

      // Get all bookings for the specified date
      final bookings = await db.rawQuery('''
        SELECT t.bookid, t.book_date, t.eventdate, t.foodtrucktype, 
               t.price, t.truck_fee, t.dishes_ordered,
               u.name as customer_name, u.email, u.phone
        FROM truckbook t
        INNER JOIN users u ON t.userid = u.userid
        WHERE DATE(t.book_date) = DATE(?)
        ORDER BY t.book_date DESC
      ''', [date]);

      // Calculate totals
      double totalSales = 0.0;
      double totalTruckFees = 0.0;
      double totalDishSales = 0.0;
      int totalBookings = bookings.length;
      Map<String, int> truckBookingCount = {};
      Map<String, double> truckRevenue = {};

      for (var booking in bookings) {
        final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
        final truckFee = (booking['truck_fee'] as num?)?.toDouble() ?? 0.0;
        final truckType = booking['foodtrucktype'] as String;

        totalSales += price;
        totalTruckFees += truckFee;
        totalDishSales += (price - truckFee);

        // Count bookings per truck
        truckBookingCount[truckType] = (truckBookingCount[truckType] ?? 0) + 1;
        truckRevenue[truckType] = (truckRevenue[truckType] ?? 0.0) + price;
      }

      return {
        'date': date,
        'bookings': bookings,
        'totalBookings': totalBookings,
        'totalSales': totalSales,
        'totalTruckFees': totalTruckFees,
        'totalDishSales': totalDishSales,
        'truckBookingCount': truckBookingCount,
        'truckRevenue': truckRevenue,
      };
    } catch (e) {
      print('Error getting sales report by date: $e');
      return {
        'date': date,
        'bookings': [],
        'totalBookings': 0,
        'totalSales': 0.0,
        'totalTruckFees': 0.0,
        'totalDishSales': 0.0,
        'truckBookingCount': {},
        'truckRevenue': {},
      };
    }
  }

  // Get sales report for a date range
  Future<Map<String, dynamic>> getSalesReportByDateRange(
      String startDate, String endDate) async {
    try {
      final db = await database;

      final bookings = await db.rawQuery('''
        SELECT t.bookid, t.book_date, t.eventdate, t.foodtrucktype, 
               t.price, t.truck_fee, t.dishes_ordered,
               u.name as customer_name, u.email, u.phone
        FROM truckbook t
        INNER JOIN users u ON t.userid = u.userid
        WHERE DATE(t.book_date) BETWEEN DATE(?) AND DATE(?)
        ORDER BY t.book_date DESC
      ''', [startDate, endDate]);

      double totalSales = 0.0;
      double totalTruckFees = 0.0;
      double totalDishSales = 0.0;
      int totalBookings = bookings.length;
      Map<String, int> truckBookingCount = {};
      Map<String, double> truckRevenue = {};

      for (var booking in bookings) {
        final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
        final truckFee = (booking['truck_fee'] as num?)?.toDouble() ?? 0.0;
        final truckType = booking['foodtrucktype'] as String;

        totalSales += price;
        totalTruckFees += truckFee;
        totalDishSales += (price - truckFee);

        truckBookingCount[truckType] = (truckBookingCount[truckType] ?? 0) + 1;
        truckRevenue[truckType] = (truckRevenue[truckType] ?? 0.0) + price;
      }

      return {
        'startDate': startDate,
        'endDate': endDate,
        'bookings': bookings,
        'totalBookings': totalBookings,
        'totalSales': totalSales,
        'totalTruckFees': totalTruckFees,
        'totalDishSales': totalDishSales,
        'truckBookingCount': truckBookingCount,
        'truckRevenue': truckRevenue,
      };
    } catch (e) {
      print('Error getting sales report by date range: $e');
      return {
        'startDate': startDate,
        'endDate': endDate,
        'bookings': [],
        'totalBookings': 0,
        'totalSales': 0.0,
        'totalTruckFees': 0.0,
        'totalDishSales': 0.0,
        'truckBookingCount': {},
        'truckRevenue': {},
      };
    }
  }

  // Get all unique booking dates (for quick date selection)
  Future<List<String>> getAllBookingDates() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT DISTINCT DATE(book_date) as booking_date
        FROM truckbook
        ORDER BY booking_date DESC
      ''');

      return result.map((row) => row['booking_date'] as String).toList();
    } catch (e) {
      print('Error getting all booking dates: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Test Data Seeding - For Development/Testing Only
  // --------------------------------------------------------------------------

  /// Seeds test reviews for all food trucks
  /// [reviewsPerTruck] - number of reviews to generate per truck (2-35 recommended)
  Future<void> seedTestReviews({int reviewsPerTruck = 15}) async {
    try {
      final db = await database;

      // Sample reviewer names for fake users
      final List<String> fakeNames = [
        'John Smith',
        'Maria Garcia',
        'David Lee',
        'Sarah Johnson',
        'Michael Brown',
        'Emily Davis',
        'James Wilson',
        'Jessica Martinez',
        'Robert Taylor',
        'Ashley Anderson',
        'William Thomas',
        'Sophia Jackson',
        'Daniel White',
        'Olivia Harris',
        'Matthew Martin',
        'Emma Thompson',
        'Christopher Garcia',
        'Ava Robinson',
        'Andrew Clark',
        'Isabella Lewis',
        'Joshua Walker',
        'Mia Hall',
        'Ethan Allen',
        'Charlotte Young',
        'Ryan King',
        'Amelia Wright',
        'Brandon Scott',
        'Harper Green',
        'Justin Adams',
        'Evelyn Baker',
        'Tyler Nelson',
        'Abigail Hill',
        'Kevin Ramirez',
        'Emily Campbell',
        'Aaron Mitchell',
      ];

      // Sample review texts - positive, neutral, and negative
      final List<Map<String, dynamic>> reviewTemplates = [
        // 5 star reviews
        {
          'text':
              'Absolutely amazing food! Best food truck experience ever. Will definitely come back!',
          'rating': 5.0
        },
        {
          'text':
              'The flavors were incredible and the service was top-notch. Highly recommend!',
          'rating': 5.0
        },
        {
          'text':
              'Perfect for our event! Everyone loved the food. Thank you so much!',
          'rating': 5.0
        },
        {
          'text': 'Outstanding quality and presentation. Worth every penny!',
          'rating': 5.0
        },
        {
          'text':
              'Best catering decision we ever made. The food was a huge hit!',
          'rating': 5.0
        },
        {
          'text':
              'Exceeded all expectations! Fresh ingredients and amazing taste.',
          'rating': 5.0
        },
        {
          'text':
              'Fantastic experience from start to finish. The team was professional and friendly.',
          'rating': 5.0
        },

        // 4 star reviews
        {
          'text': 'Great food and friendly staff. Would order again!',
          'rating': 4.0
        },
        {
          'text': 'Really enjoyed the meal. Portions were generous and tasty.',
          'rating': 4.0
        },
        {
          'text':
              'Good variety of options and quick service. Minor wait but worth it.',
          'rating': 4.0
        },
        {
          'text':
              'Solid food truck with authentic flavors. Recommend trying their signature dish!',
          'rating': 4.0
        },
        {
          'text': 'Very satisfied with our order. Fresh and delicious!',
          'rating': 4.0
        },
        {
          'text': 'Nice selection and reasonable prices. Will visit again.',
          'rating': 4.0
        },
        {
          'text':
              'Food was hot and fresh. Staff was helpful with recommendations.',
          'rating': 4.0
        },
        {
          'text': 'Great value for money. The special was particularly good.',
          'rating': 4.5
        },

        // 3 star reviews
        {
          'text': 'Decent food, nothing extraordinary but satisfying.',
          'rating': 3.0
        },
        {
          'text': 'Average experience. Food was okay, service could be faster.',
          'rating': 3.0
        },
        {
          'text': 'It was alright. Some dishes were better than others.',
          'rating': 3.0
        },
        {
          'text': 'Good but not great. Expected a bit more based on reviews.',
          'rating': 3.5
        },
        {
          'text':
              'Fair prices and okay food. Would try again to give it another chance.',
          'rating': 3.0
        },

        // 2 star reviews
        {
          'text': 'Food was lukewarm when it arrived. Taste was okay though.',
          'rating': 2.0
        },
        {
          'text': 'Long wait time and portions were smaller than expected.',
          'rating': 2.0
        },
        {
          'text':
              'Not what I expected. Might try something different next time.',
          'rating': 2.5
        },

        // 1 star reviews (rare)
        {
          'text': 'Had a bad experience. Food was cold and service was slow.',
          'rating': 1.0
        },
      ];

      // Get all food trucks
      final trucks = await db.query('food_trucks');
      if (trucks.isEmpty) {
        print('No food trucks found. Please add food trucks first.');
        return;
      }

      // Create test users if they don't exist
      List<int> testUserIds = [];
      for (int i = 0; i < fakeNames.length; i++) {
        final username = 'testuser${i + 1}';

        // Check if user already exists
        final existing = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: [username],
        );

        int userId;
        if (existing.isEmpty) {
          userId = await db.insert('users', {
            'name': fakeNames[i],
            'email': '${username}@test.com',
            'phone': '555-${(1000 + i).toString().padLeft(4, '0')}',
            'username': username,
            'password': 'test123',
          });
        } else {
          userId = existing.first['userid'] as int;
        }
        testUserIds.add(userId);
      }

      print('Created/found ${testUserIds.length} test users');

      // Generate reviews for each truck
      int totalReviews = 0;
      for (var truck in trucks) {
        final truckName = truck['name'] as String;

        // Check existing reviews for this truck
        final existingReviews = await db.query(
          'review',
          where: 'foodtruck_name = ?',
          whereArgs: [truckName],
        );

        final reviewsToAdd = reviewsPerTruck - existingReviews.length;
        if (reviewsToAdd <= 0) {
          print(
              '$truckName already has ${existingReviews.length} reviews, skipping...');
          continue;
        }

        // Shuffle users and review templates for variety
        final shuffledUserIds = List<int>.from(testUserIds)..shuffle();
        final shuffledTemplates =
            List<Map<String, dynamic>>.from(reviewTemplates)..shuffle();

        for (int i = 0; i < reviewsToAdd; i++) {
          final userId = shuffledUserIds[i % shuffledUserIds.length];
          final template = shuffledTemplates[i % shuffledTemplates.length];

          await db.insert('review', {
            'userid': userId,
            'userreview': template['text'],
            'userreviewstar': template['rating'],
            'foodtruck_name': truckName,
          });
          totalReviews++;
        }

        print('Added $reviewsToAdd reviews for $truckName');
      }

      print('Successfully seeded $totalReviews test reviews!');
    } catch (e) {
      print('Error seeding test reviews: $e');
    }
  }

  /// Clears all test reviews (reviews from test users)
  Future<void> clearTestReviews() async {
    try {
      final db = await database;

      // Delete reviews from test users
      await db.rawDelete('''
        DELETE FROM review 
        WHERE userid IN (
          SELECT userid FROM users WHERE username LIKE 'testuser%'
        )
      ''');

      // Optionally delete test users too
      await db
          .delete('users', where: 'username LIKE ?', whereArgs: ['testuser%']);

      print('Cleared all test reviews and test users');
    } catch (e) {
      print('Error clearing test reviews: $e');
    }
  }
}
