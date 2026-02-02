# 🚚 Food Truck Booking App

A cross-platform mobile application built with Flutter that allows users to discover, browse, and book food trucks in their area.

## 📱 Features

- **Food Truck Discovery** — Browse available food trucks with images, cuisine types, availability status, and star ratings
- **Menu & Ordering** — View menus and select dishes from your favorite food trucks
- **Shopping Cart** — Add items to cart and manage your order
- **Booking System** — Book food trucks with detailed booking information
- **Payment Processing** — Secure payment flow for orders
- **Reviews & Ratings** — Read and write reviews with star rating filters
- **User Authentication** — Secure login and registration system
- **Admin Dashboard** — Administrative panel for managing the platform

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite (sqflite)
- **State Persistence:** Shared Preferences
- **UI Components:** Carousel Slider, Material Design
- **PDF Generation:** pdf package

## 📦 Platforms Supported

- Android

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.5.3)
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/food_truck_booking_app.git
   cd food_truck_booking_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── login_page.dart           # User login
├── register_page.dart        # User registration
├── booking_details_page.dart # Booking information
├── payment_page.dart         # Payment processing
├── user_details_page.dart    # User profile
├── database/
│   └── database_helper.dart  # SQLite database operations
├── screens/
│   ├── home_screen.dart              # Home feed with news & reviews
│   ├── food_truck_selection_page_screen.dart  # Browse food trucks
│   ├── dish_selection_screen.dart    # Menu & dish selection
│   ├── cart_screen.dart              # Shopping cart
│   ├── account_screen.dart           # User account
│   ├── AdminScreen.dart              # Admin dashboard
│   ├── ReviewPage.dart               # Write & view reviews
│   └── main_navigation_screen.dart   # Bottom navigation
└── utils/
    └── auth_manager.dart     # Authentication state management
```

## 📄 License

This project is for educational purposes.
