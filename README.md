# Tabi

**Tabi** is a travel itinerary sharing app built with Flutter and FastAPI. Create beautiful travel journals, share your adventures, and discover new destinations through the experiences of other travelers.

## Features

- **Create Rich Itineraries** - Build detailed trip plans with text, images, and interactive maps
- **Visual Storytelling** - Upload photos to bring your travels to life
- **Interactive Maps** - Add location pins that open directly in Apple Maps
- **Markdown Support** - Format your stories with headers, bold, and italic text
- **Social Features** - Follow other travelers, save favorite itineraries, and discover new destinations
- **Cloud Storage** - All images securely stored in Google Cloud Storage
- **Secure Authentication** - JWT-based auth with email verification

## Tech Stack

**Frontend:**
- Flutter (iOS)
- Google Maps / Apple Maps
- Provider for state management
- SharedPreferences for local storage

**Backend:**
- FastAPI (Python)
- PostgreSQL with SQLModel
- Google Cloud Run (hosting)
- Google Cloud Storage (file storage)
- JWT authentication
- SMTP email service

## Getting Started

### Prerequisites
- Flutter SDK
- Python 3.11+
- PostgreSQL
- Google Cloud Platform account

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
# Configure your .env file
uvicorn app.main:app --reload
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d <your-device-id>
```

## Current Status

✅ Production-ready backend on Google Cloud Run  
✅ Cloud Storage integration for images  
✅ Full authentication and user management  
✅ Itinerary CRUD operations  
✅ Social features (follow, save, bookmark)  
✅ Clickable images and interactive maps  
✅ Markdown text formatting  

**Ready for TestFlight submission!**

## Contributing

This is a personal project by [Stanley Woo](https://github.com/stanley-woo).

---

*Built with love for travelers everywhere*
