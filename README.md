# Intelligent Mobile Travel Guide

An intelligent mobile travel guide app that helps users discover nearby places, get real-time navigation, check weather/news, and receive personalized travel recommendations powered by AI.

This repository contains both the Flutter frontend app and the custom Node.js/MongoDB backend.

## Features

- **Location & Discovery**: Find nearby places (restaurants, shops, hospitals, hotels, etc.) with category filters.
- **Maps & Navigation**: Google Maps integration with route calculation and real-time turn-by-turn navigation.
- **AI Recommendations**: Personalized travel recommendations using Groq API (llama-3.1-8b-instant) based on user search history and preferences.
- **Weather & News**: Current weather forecasts and local travel news integration.
- **User Accounts & Bookmarks**: Custom JWT authentication allowing users to create accounts, set preferences, and bookmark favorite places.

## Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (or Bloc)
- **Maps & Location**: Google Maps Flutter, Geolocator, Google Places API
- **Networking**: Dio / Http

### Backend (Server & API)
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (with Mongoose)
- **Authentication**: JWT (JSON Web Tokens) & bcryptjs
- **AI Integration**: Groq SDK (`llama-3.1-8b-instant`)
- **External API Proxies**: Axios (Google Places, OpenWeatherMap, NewsAPI)

---

## Getting Started

### Prerequisites
- Node.js (v16+)
- MongoDB running locally or a MongoDB Atlas URI
- Flutter SDK
- API Keys for Groq, Google Maps, OpenWeatherMap, and NewsAPI.

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up environment variables:
   Copy `.env.example` to `.env` and fill in your keys:
   ```bash
   cp .env.example .env
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```
   *The server will run on http://localhost:5000*

### Frontend Setup

*(Flutter app setup instructions will go here once the frontend is initialized.)*

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## License
MIT License
