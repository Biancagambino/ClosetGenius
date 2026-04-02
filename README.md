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
| AI Backend | Flask (Python), served via ngrok |
| Image Classification | Florence-2 (via Hugging Face Transformers) |
| AI Chat (Nova) | Llama 3 via Ollama, served through Flask |
| Training Environment | Google Colab (T4 GPU) |

---

## How It Works

The iOS app communicates with a Python Flask backend that handles both clothing classification and AI chat. The backend is run in Google Colab and exposed publicly via ngrok. Because ngrok URLs change each session, the app includes a built-in settings panel to update the server URL without needing to touch any code.

**Scan flow:** The app sends a clothing photo to the `/scan` endpoint → Florence-2 analyzes the image → the app receives structured clothing metadata and pre-fills the item form.

**Nova chat flow:** The app sends a conversation message to the `/chat` endpoint → the backend queries the language model → Nova's response streams back to the UI.

---

## Setup

### Prerequisites

- Xcode 15+
- A Firebase project with Firestore and Authentication enabled
- A Cloudinary account
- A Google account to run the Colab notebook

### iOS App

1. Clone the repository
2. Open `IOS/ClosetGenius.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the `IOS/ClosetGenius/` directory
4. In `Models/CloudinaryService.swift`, replace the cloud name and upload preset with your own Cloudinary credentials
5. Build and run on a simulator or physical device

### AI Backend (Google Colab)

1. Open `Alexnet/ClosetGeniusAlexnet2.ipynb` in Google Colab
2. Run all cells — this installs dependencies, loads Florence-2 and the language model, and starts the Flask server
3. Copy the ngrok URL printed at the end of the final cell

### Connecting the App to the Backend

You do not need to edit any code to update the server URL. From inside the app:

1. Go to **Profile → Settings → AI Server**
2. Paste your ngrok URL into the input field
3. Tap **Test** to verify the connection (indicator turns green when reachable)
4. Tap **Save**

The app will use this URL for all scan and chat requests until you update it again.

> **Note:** The ngrok URL changes every time the Colab session is restarted. You will need to repeat the connection step each new session.

---

## Mission

Fast fashion is one of the largest contributors to global textile waste. ClosetGenius is built around the idea that the most sustainable garment is the one you already own. By making it easier to organize, style, and rehome clothing, the app encourages users to buy less and wear more.

---

## Author

Bianca Gambino
