# ClosetGenius

ClosetGenius is an AI-powered wardrobe management app designed to make sustainable fashion accessible and effortless. Built with the growing issue of textile waste in mind, the app helps users get more out of the clothes they already own while providing a platform to trade, thrift, and rent clothing within a community.

## Features

- **AI Clothing Scanner** — Snap a photo of any clothing item and AlexNet automatically identifies the category, color, season, and usage type to instantly populate your wardrobe entry
- **Closet Management** — Digitize and organize your entire wardrobe with detailed metadata, wear tracking, and custom tags
- **Outfit Builder** — Mix and match items from your closet to plan and save outfits
- **Daily Outfit Prompt** — Get daily outfit suggestions based on your wardrobe and the weather
- **Trade Marketplace** — Buy, sell, or trade clothing directly with other users — a built in thrift store experience
- **Friends & Social** — Share outfits, follow friends, and discover how others style similar pieces
- **Messaging** — Chat with other users about trades and listings
- **Weather Integration** — Outfit suggestions tailored to your local weather

## Tech Stack

- **iOS** — Swift, SwiftUI, Firebase (Auth, Firestore, Storage)
- **ML Model** — AlexNet (PyTorch), trained on the Fashion Product Images Dataset from Kaggle
- **Backend** — Flask API hosted via ngrok (development), serving model predictions
- **Training** — Google Colab with T4 GPU, 6,998 images across 15 clothing categories, 78.2% validation accuracy

## ML Model

The clothing classifier uses a pretrained AlexNet architecture with multiple output heads for simultaneous prediction of category, color, season, and usage type. Key training decisions:

- Froze the first 8 convolutional layers to preserve ImageNet features
- Fine-tuned only the later layers and custom classification heads
- Trained across 4 experimental configurations to find the optimal setup
- Final model achieved 78.2% validation accuracy, up from an initial 37% baseline

## Mission

Fast fashion is one of the largest contributors to global textile waste. ClosetGenius encourages users to rewear, restyle, and rehome clothing rather than discard it — making sustainable fashion choices easier and more rewarding through technology.

## Setup

### iOS
1. Clone the repo
2. Open `iOS/ClosetGenius.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` to the project
4. Update `baseURL` in `ScannerView.swift` with your Flask server URL
5. Build and run on simulator or device

### ML Model
1. Open `ML/ClosetGeniusAlexnet2.ipynb` in Google Colab
2. Run Cell 1 to mount Drive and download dataset
3. Run Cell 2 to extract and organize images
4. Run Cell 3 to train the model
5. Run Cell 4 to start the Flask inference server
6. Copy the ngrok URL into `ScannerView.swift`

## Author

Bianca Gambino
