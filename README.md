# ClosetGenius

ClosetGenius is an AI-powered wardrobe management app for iOS that helps you organize your closet, build outfits, and connect with a fashion community — all while encouraging more sustainable clothing habits.

---

## Features

- **AI Clothing Scanner** — Photograph any clothing item and the app automatically identifies its category, color, season, and usage type to instantly populate your wardrobe entry
- **Nova AI Assistant** — Chat with Nova, an in-app AI stylist that answers outfit questions, suggests pairings, and gives personalized fashion advice based on your wardrobe
- **Closet Management** — Digitize and organize your entire wardrobe with photos, metadata, wear tracking, and tags
- **Outfit Builder** — Mix and match pieces from your closet to plan and save complete outfits
- **Daily Outfit Prompt** — Share your outfit of the day and browse what your friends are wearing
- **Trade Marketplace** — Buy, sell, and trade clothing directly with other users or filter to friends-only listings
- **Friends & Social Feed** — Follow friends, like and comment on their posts, and discover how others style similar pieces
- **Dashboard Suggestions** — Receive AI-generated outfit recommendations each time you open the app

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS | Swift, SwiftUI |
| Auth & Database | Firebase Auth, Firestore |
| Image Storage | Cloudinary |
| AI Backend | FastAPI (Python), deployed on Google Cloud Run |
| Image Classification | Florence-2 (via Hugging Face Transformers) |
| AI Chat (Nova) | Llama 3.3 via Groq |

---

## How It Works

The iOS app communicates with a FastAPI backend deployed on Google Cloud Run that handles both clothing classification and AI chat. The backend scales to zero when idle and spins up automatically on first request — no configuration needed.

**Scan flow:** The app sends a clothing photo to the `/scan` endpoint → Florence-2 analyzes the image → the app receives structured clothing metadata and pre-fills the item form.

**Nova chat flow:** The app sends a conversation message to the `/chat` endpoint → the backend queries Llama 3.3 via Groq → Nova's response is returned to the UI.

---

## Setup

### iOS App

1. Clone the repository
2. Open `IOS/ClosetGenius.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the `IOS/ClosetGenius/` directory
4. In `Models/CloudinaryService.swift`, replace the cloud name and upload preset with your own Cloudinary credentials
5. Build and run on a simulator or physical device

### AI Backend (Google Cloud Run)

The backend is located in the `backend/` directory and is deployed on Google Cloud Run. See `backend/DEPLOY.md` for full deployment instructions.

The backend exposes three endpoints:

| Endpoint | Method | Description |
|---|---|---|
| `/health` | GET | Health check |
| `/scan` | POST | Classify a clothing image |
| `/chat` | POST | Chat with Nova AI stylist |

---

## Mission

Fast fashion is one of the largest contributors to global textile waste. ClosetGenius is built around the idea that the most sustainable garment is the one you already own. By making it easier to organize, style, and rehome clothing, the app encourages users to buy less and wear more.

---

## Author

Bianca Gambino
