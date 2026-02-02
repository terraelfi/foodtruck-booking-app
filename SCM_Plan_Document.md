# SOFTWARE CONFIGURATION MANAGEMENT PLAN

## Food Truck Booking Application

**Version:** 1.0  
**Date:** January 2, 2026  
**Project:** Food Truck Booking App v2  
**Platform:** Flutter Cross-Platform Mobile Application  

---

## 1. INTRODUCTION

### 1.1 Purpose

This Software Configuration Management Plan establishes the policies, procedures, and standards for managing configuration items throughout the lifecycle of the Food Truck Booking Application. The plan defines how configuration items will be identified, controlled, and maintained to ensure product integrity and traceability from development through deployment and maintenance phases.

### 1.2 Scope

This SCM Plan applies to all software components, documentation, and supporting artifacts associated with the Food Truck Booking Application. The application is developed using Flutter framework version 3.5.3 and targets Android, iOS, Web, Windows, Linux, and macOS platforms. The scope encompasses source code management, database schema versioning, asset management, build configuration, and release management activities.

### 1.3 Definitions and Acronyms

SCM refers to Software Configuration Management. CI refers to Configuration Item. CCB refers to Configuration Control Board. VCS refers to Version Control System. SDK refers to Software Development Kit. API refers to Application Programming Interface. UI refers to User Interface. DB refers to Database.

### 1.4 References

IEEE Standard 828-2012 for Software Configuration Management Plans serves as the primary reference for this document. Additional references include Flutter Framework Documentation version 3.5.3, Dart Programming Language Specification, SQLite Database Documentation, and the Android and iOS Platform Development Guidelines.

---

## 2. SCM MANAGEMENT

### 2.1 Organization

The SCM organization consists of the Project Manager who holds overall responsibility for SCM activities, the Configuration Manager who implements and maintains SCM procedures, the Development Team Lead who ensures compliance with SCM procedures during development, and individual Developers who follow established SCM procedures and maintain configuration item integrity.

### 2.2 SCM Responsibilities

The Configuration Manager is responsible for establishing and maintaining the configuration management environment, managing the version control repository, coordinating baseline establishment and releases, maintaining configuration status accounting records, and conducting configuration audits.

### 2.3 Applicable Policies and Procedures

All configuration items shall be placed under version control before being incorporated into any baseline. Changes to baselined items require formal change request approval. All builds shall be reproducible from version-controlled sources. Configuration status shall be reported at defined project milestones.

---

## 3. SCM ACTIVITIES

### 3.1 Configuration Identification

Configuration identification establishes and maintains the definitive basis for control and status accounting of configuration items throughout the software lifecycle. This section identifies all items that comprise the Food Truck Booking Application and defines the naming conventions, labeling schemes, and baseline definitions.

#### 3.1.1 Configuration Items

The Food Truck Booking Application consists of configuration items organized into the following categories.

**3.1.1.1 Application Source Code**

The primary application entry point is contained in lib/main.dart which initializes the Flutter application, configures the MaterialApp widget, establishes routing, and implements the HomePage and CarouselWithText components for the welcome screen experience.

The authentication module comprises lib/login_page.dart which implements user and administrator login functionality, lib/register_page.dart which handles new user registration with form validation, and lib/utils/auth_manager.dart which manages authentication state persistence using SharedPreferences for session management.

The screen components include lib/screens/main_navigation_screen.dart which provides the primary navigation structure with bottom navigation bar, lib/screens/home_screen.dart which displays the main dashboard with news and featured content, lib/screens/food_truck_selection_page_screen.dart which presents available food trucks with filtering and selection capabilities, lib/screens/dish_selection_screen.dart which displays menu items for selected food trucks with quantity selection, lib/screens/cart_screen.dart which manages the shopping cart with item quantity modification and removal, lib/screens/account_screen.dart which provides user profile management and booking history, lib/screens/ReviewPage.dart which implements the review submission and display functionality, and lib/screens/AdminScreen.dart which provides administrative functions including user management, food truck management, dish management, and sales reporting.

The booking and payment modules include lib/booking_details_page.dart which displays booking confirmation and details, lib/payment_page.dart which handles payment processing and order completion, and lib/user_details_page.dart which manages user information display and editing.

The data access layer is implemented in lib/database/database_helper.dart which provides the DatabaseHelper singleton class managing SQLite database operations including table creation, schema migrations across six versions, and CRUD operations for users, bookings, cart items, reviews, administrators, food trucks, and dishes.

**3.1.1.2 Platform Configuration Files**

The Flutter project configuration is defined in pubspec.yaml which specifies the application name as food_truck_booking_app, version 0.1.0, Dart SDK constraint of version 3.5.3 or higher, and declares dependencies including flutter SDK, carousel_slider version 5.0.0, intl version 0.19.0, sqflite version 2.4.1, path version 1.8.3, ionicons version 0.2.2, shared_preferences version 2.3.4, font_awesome_flutter version 10.8.0, pdf version 3.10.4, and path_provider version 2.1.1. Development dependencies include flutter_test SDK and flutter_lints version 4.0.0. The file also declares asset directories for images.

The dependency lock file pubspec.lock contains the resolved versions of all direct and transitive dependencies ensuring reproducible builds across development environments.

The analysis configuration analysis_options.yaml defines Dart analyzer rules and linting configuration for code quality enforcement.

The Android platform configuration includes android/app/build.gradle which defines the application namespace as com.example.food_truck_booking_app, build settings, and signing configurations. The file android/build.gradle provides project-level Gradle configuration. The file android/settings.gradle defines the Gradle project structure. The file android/gradle.properties contains Gradle build properties. The manifest file android/app/src/main/AndroidManifest.xml declares application permissions and components.

The iOS platform configuration includes ios/Runner/Info.plist which contains application metadata and permissions, ios/Runner.xcodeproj/project.pbxproj which defines Xcode project settings, and ios/Flutter/AppFrameworkInfo.plist which contains Flutter framework configuration.

The web platform configuration includes web/index.html which serves as the web application entry point, and web/manifest.json which defines the progressive web application manifest.

The Windows platform configuration includes windows/CMakeLists.txt which defines the CMake build configuration for Windows deployment.

The Linux platform configuration includes linux/CMakeLists.txt which defines the CMake build configuration for Linux deployment.

The macOS platform configuration includes macos/Runner/Info.plist and macos/Runner.xcodeproj/project.pbxproj which define macOS application settings.

**3.1.1.3 Database Schema**

The database schema is implemented within lib/database/database_helper.dart and currently resides at version 6. The schema includes the users table with columns userid as integer primary key autoincrement, name as text not null, email as text not null unique, phone as text not null, username as text not null unique, and password as text not null.

The cart table contains columns cartid as integer primary key autoincrement, userid as integer not null with foreign key reference to users, dishid as integer not null with foreign key reference to dishes, dish_name as text not null, foodtruck_name as text not null, quantity as integer not null defaulting to 1, price as real not null, and booking_date as text not null.

The truckbook table contains columns bookid as integer primary key autoincrement, userid as integer not null with foreign key reference to users, book_date as text not null, booktime as text not null, eventdate as text not null, eventtime as text not null, foodtrucktype as text not null, numberofdays as integer not null, price as real not null, truck_fee as real not null defaulting to 0, and dishes_ordered as text.

The review table contains columns reviewid as integer primary key autoincrement, userid as integer not null with foreign key reference to users, userreview as text not null, userreviewstar as real not null, and foodtruck_name as text.

The administrator table contains columns adminid as integer primary key autoincrement, username as text not null unique, and password as text not null.

The food_trucks table contains columns truckid as integer primary key autoincrement, name as text not null, image as text not null, type as text not null, description as text not null, packages as text not null, price as real not null, and availability as text not null defaulting to Available.

The dishes table contains columns dishid as integer primary key autoincrement, truckid as integer not null with foreign key reference to food_trucks with cascade delete, name as text not null, description as text not null, price as real not null, quantity as integer not null, and image as text not null.

**3.1.1.4 Static Assets**

Image assets are organized in the assets/images directory structure. The foodTruckImages subdirectory contains food truck promotional images including guatemala.jpg, steelWheel.jpg, iceCream.jpg, asianFoodie.jpg, and mediterranean.jpg among others totaling eight image files. The newsImage subdirectory contains promotional and news-related images totaling three files.

Application icons are maintained in platform-specific directories including android/app/src/main/res for Android icons in multiple densities, ios/Runner/Assets.xcassets for iOS icons and launch images, web/icons for web application icons, and windows/runner/resources for Windows application icons.

**3.1.1.5 Build Artifacts**

Generated build artifacts are stored in the build directory and are excluded from version control. These include the Android APK files located in build/app/outputs/flutter-apk, intermediate compilation artifacts, and platform-specific generated code.

**3.1.1.6 Documentation**

Project documentation includes this SCM_Plan_Document.md and the project README.md file. Additional documentation may include user guides, API documentation, and technical specifications as the project evolves.

#### 3.1.2 Baselines

Baselines represent formally approved versions of configuration items that serve as the foundation for further development. All changes to baselined items must follow the established change control procedures.

**3.1.2.1 Functional Baseline**

The Functional Baseline establishes the approved functional requirements for the Food Truck Booking Application. This baseline encompasses the user registration and authentication functionality enabling users to create accounts and securely log into the application, the food truck browsing capability allowing users to view available food trucks with descriptions, images, types, packages, and pricing, the dish selection and ordering feature enabling users to browse menus and add items to their cart, the cart management functionality allowing users to modify quantities and remove items before checkout, the booking and payment processing enabling users to complete food truck reservations with event details, the review and rating system allowing users to submit and view reviews for food trucks, and the administrative functions providing administrators with user management, food truck management, dish inventory management, and sales reporting capabilities.

**3.1.2.2 Allocated Baseline**

The Allocated Baseline defines the approved system architecture and design specifications. The application architecture follows the Flutter framework patterns with a widget-based UI hierarchy. The data layer utilizes SQLite for local persistent storage through the DatabaseHelper singleton pattern. State management employs StatefulWidget components with SharedPreferences for authentication state persistence. Navigation follows the MaterialApp routing system with named routes for login and admin screens and direct navigation for other screens.

The technology stack allocation includes Flutter SDK version 3.5.3 or higher as the cross-platform development framework, Dart as the programming language, SQLite version 2.4.1 via sqflite package for local database storage, SharedPreferences version 2.3.4 for key-value persistent storage, and platform-specific build tools including Gradle for Android, Xcode for iOS and macOS, and CMake for Windows and Linux.

**3.1.2.3 Product Baseline**

The Product Baseline represents the approved, tested, and deliverable version of the Food Truck Booking Application. The current product baseline is version 0.1.0 as specified in pubspec.yaml. This baseline includes all source code configuration items under the lib directory, platform configurations for Android, iOS, Web, Windows, Linux, and macOS, database schema at version 6, static assets including images and icons, and dependency specifications in pubspec.yaml and pubspec.lock.

**3.1.2.4 Baseline Naming Convention**

Baselines shall be identified using the following naming convention. Major releases follow the format FTBA-vX.0.0-BASELINE where X represents the major version number. Minor releases follow the format FTBA-vX.Y.0-BASELINE where Y represents the minor version number. Patch releases follow the format FTBA-vX.Y.Z-BASELINE where Z represents the patch version number. Development builds follow the format FTBA-vX.Y.Z-BUILD-NNNN where NNNN represents the sequential build number.

**3.1.2.5 Baseline Establishment Process**

The establishment of a new baseline requires completion of all planned development activities for the release, successful execution of all test cases with no critical or high-severity defects remaining, completion of code review for all modified configuration items, approval from the Configuration Control Board, tagging of all configuration items in the version control system with the baseline identifier, and archival of build artifacts and release notes.

**3.1.2.6 Database Schema Baseline**

Database schema versions are tracked within the DatabaseHelper implementation and follow an incremental versioning scheme. The current schema baseline is version 6 which includes support for dish details in bookings through the truck_fee and dishes_ordered columns in the truckbook table. Schema migrations are implemented in the _upgradeDb method which handles incremental updates from any previous version to the current version ensuring data preservation during application updates.

---

## 4. SCM SCHEDULES

### 4.1 Baseline Schedule

Baseline establishment shall occur at the completion of each development sprint or iteration. Release baselines shall be established prior to deployment to any production environment.

### 4.2 Audit Schedule

Configuration audits shall be conducted prior to each baseline establishment to verify completeness and consistency of configuration items.

---

## 5. SCM RESOURCES

### 5.1 Tools

Version control shall be maintained using Git distributed version control system. Build automation shall utilize Flutter command-line tools and platform-specific build systems. Dependency management shall be handled through the Dart pub package manager.

### 5.2 Personnel

SCM activities require personnel with knowledge of Flutter development, Git version control, and mobile application deployment procedures.

---

## 6. SCM PLAN MAINTENANCE

This SCM Plan shall be reviewed and updated at the beginning of each major release cycle or when significant changes to the project scope or development environment occur. All changes to this plan require approval from the Project Manager.

---

**Document Approval**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Manager | | | |
| Configuration Manager | | | |
| Development Lead | | | |

---

**Revision History**

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | January 2, 2026 | | Initial SCM Plan Document |



