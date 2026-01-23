# Quick Start Commands for Ilac Dostu

## Flutter SDK Installed! ✅

Flutter version: **3.38.7**
Location: `c:\Users\404\Desktop\med-tracker\flutter`

## ⚠️ IMPORTANT: Firebase Configuration Required

Before running the app, you **MUST** configure Firebase:

1. **Create Firebase Project**:
   - Go to: https://console.firebase.google.com
   - Click "Add project" → Name it "ilac-dostu"
   - Disable Google Analytics (optional for testing)

2. **Add Web App**:
   - Click the Web icon `</>`
   - Register app nickname: "ilac-dostu-web"
   - Copy the Firebase configuration

3. **Update main.dart**:
   - Open: `lib/main.dart`
   - Go to line ~26 (function `_initializeFirebase`)
   - Replace placeholder values with your config:
   ```dart
   await Firebase.initializeApp(
     options: const FirebaseOptions(
       apiKey: "AIza...",              // ← Your API key
       authDomain: "ilac-dostu.firebaseapp.com",
       projectId: "ilac-dostu",
       storageBucket: "ilac-dostu.firebasestorage.app",
       messagingSenderId: "123456789",
       appId: "1:123456789:web:abc123",
     ),
   );
   ```

4. **Enable Firestore**:
   - In Firebase Console → Build → Firestore Database
   - Click "Create database"
   - Select "Start in test mode"
   - Choose location and click "Enable"

## 🚀 Run the App

Once Firebase is configured, use this command to run:

```powershell
# Set Flutter in PATH and run
$env:PATH += ";$PWD\flutter\bin"
flutter run -d chrome
```

Or create a permanent PowerShell alias:

```powershell
# Add this to your PowerShell profile for permanent access
$env:PATH += ";C:\Users\404\Desktop\med-tracker\flutter\bin"
```

## 📋 Available Commands

```powershell
# Check Flutter installation
flutter doctor

# List available devices
flutter devices

# Run on Chrome (default)
flutter run -d chrome

# Hot reload (press 'r' in the terminal while app is running)
# Hot restart (press 'R')
# Quit (press 'q')

# Check for outdated packages
flutter pub outdated

# Clean build cache
flutter clean
```

## 🎯 What to Expect

1. **First Launch**: Onboarding screen
   - Enter your name (e.g., "Ali")
   - Select birth date
   - Choose gender (Erkek/Kadın)
   - Select role:
     - **Elderly Mode**: Simple UI, large buttons, read-only
     - **Admin Mode**: Full medication management

2. **Elderly Mode Features**:
   - Large greeting: "Merhaba [Name]"
   - Morning medications (Sabah İlaçları) ☀️
   - Evening medications (Akşam İlaçları) 🌙
   - Tap cards to mark as taken
   - Web notifications (SnackBar)

3. **Admin Mode Features**:
   - Add medications (+ button)
   - Edit medications (pencil icon)
   - Delete medications (trash icon)
   - View 6-digit pairing code (QR icon)

## 🧪 Testing Scenarios

**Test Real-Time Sync**:
1. Open two Chrome windows/tabs
2. Complete onboarding in both (use same name or different)
3. Window 1: Admin mode → Add medication
4. Window 2: Elderly mode → See it appear instantly
5. Window 2: Mark as taken → See update in Window 1

## 🐛 Troubleshooting

**"Firebase not initialized" error**:
- You haven't configured Firebase yet (see steps above)

**"Chrome not found" error**:
```powershell
# Check available devices
flutter devices

# Try Edge browser instead
flutter run -d edge
```

**Dependencies error**:
```powershell
flutter pub get
```

**Build cache issues**:
```powershell
flutter clean
flutter pub get
```

## 📚 Next Steps After Running

1. Test the onboarding flow
2. Try both Elderly and Admin modes
3. Add some medications
4. Test the toggle functionality
5. Check web notifications (SnackBar)

## 🎨 UI Reference

The app has three main screens:
- **Onboarding**: Name, date, gender, role selection
- **Elderly Mode**: Large cards with morning/evening groups
- **Admin Mode**: Medication list with CRUD operations

See the walkthrough artifact for UI screenshots and detailed feature descriptions.
