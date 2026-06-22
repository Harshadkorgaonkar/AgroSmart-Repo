📌 Project Overview

AgroSmart is a Flutter-based mobile application developed to help farmers sell, buy, and manage agricultural equipment efficiently. The platform connects equipment owners with farmers and provides a simple digital marketplace for agricultural machinery.

The application allows users to register, create profiles, post equipment details, browse available equipment, manage carts, and communicate through a modern mobile interface.

🚀 Features
Email OTP Authentication
User Registration and Login
Farmer Profile Creation
Equipment Listing
Equipment Search
Equipment Details Page
Add to Cart Functionality
Dashboard with Categories
User Profile Management
Supabase Database Integration
Persistent Login Session
Responsive Mobile Interface




🛠 Technologies Used
Frontend
Flutter
Dart
Backend
Supabase Authentication
Supabase Database
Database
PostgreSQL
Tools
Android Studio
Visual Studio Code
Git
GitHub
📂 Project Structure
lib/
│
├── screens/
├── widgets/
├── services/
├── models/
├── utils/
│
assets/
│
supabase/
🔐 Authentication Flow
New User
Login Page
    ↓
Email OTP Verification
    ↓
Create Profile
    ↓
Dashboard
Existing User
Login Page
    ↓
OTP Verification
    ↓
Dashboard
Logged-in User
App Start
    ↓
Dashboard
🗄 Database Tables
Users
Column	Description
email	Primary identifier
phone	Phone number
name	User name
dob	Date of birth
gender	Gender
address	Address
Products
Column	Description
product_id	Product ID
email	Owner email
title	Equipment name
price	Rent price
location	Equipment location
My Cart
Column	Description
email	User email
product_id	Product ID
⚙ Installation
Clone Repository
git clone <repository-url>
Install Dependencies
flutter pub get
Run Application
flutter run



🌟 Future Enhancements
Equipment Booking System
Payment Gateway Integration
Chat System
Push Notifications
Equipment Reviews and Ratings
Admin Panel
AI-based Equipment Recommendations
