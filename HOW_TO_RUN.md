# How to Run Ilac Dostu

## Prerequisites
You need Flutter installed on your system. If you don't have it:
1. Download from: https://flutter.dev/docs/get-started/install/windows
2. Add Flutter to your PATH

## Step 1: Install Dependencies
Open PowerShell in the project directory and run:
```bash
flutter pub get
```

## Step 2: Configure Firebase (IMPORTANT)
Before running, you need to set up Firebase:

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Click "Add project"
   - Enter project name (e.g., "ilac-dostu")
   - Follow the setup wizard

2. **Add Web App**
   - In Firebase Console, click the Web icon (</>)
   - Register app with a nickname
   - Copy the Firebase configuration object

3. **Update main.dart**
   - Open `lib/main.dart`
   - Find line ~26 (the `_initializeFirebase` function)
   - Replace the placeholder values with your Firebase config:
   ```dart
   await Firebase.initializeApp(
     options: const FirebaseOptions(
       apiKey: "YOUR_ACTUAL_API_KEY",
       authDomain: "your-project.firebaseapp.com",
       projectId: "your-project-id",
       storageBucket: "your-project.appspot.com",
       messagingSenderId: "123456789",
       appId: "1:123456789:web:abc123",
     ),
   );
   ```

4. **Enable Firestore**
   - In Firebase Console, go to "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location and click "Enable"

## Step 3: Run on Chrome
```bash
flutter run -d chrome
```

## Alternative: If Flutter is not in PATH
If running `flutter` doesn't work, use the full path:
```bash
C:\path\to\flutter\bin\flutter.bat pub get
C:\path\to\flutter\bin\flutter.bat run -d chrome
```

## What to Expect
1. **First Launch**: Onboarding screen
   - Enter your name
   - Select birth date
   - Choose gender
   - Select role (Elderly or Admin mode)

2. **Elderly Mode**:
   - Simple interface with large text
   - Morning/Evening medication groups
   - Tap cards to mark as taken
   - Web notifications via SnackBar

3. **Admin Mode**:
   - Full medication management
   - Add/Edit/Delete medications
   - View pairing code (top-right QR icon)
   - Real-time sync via Firestore

## Troubleshooting

### "Firebase not configured" error
Make sure you:
1. Created a Firebase project
2. Added a Web app
3. Updated the Firebase config in main.dart (line ~26)
4. Enabled Firestore Database

### "flutter: command not found"
Flutter is not in your PATH. Either:
- Add Flutter to PATH, or
- Use the full path to flutter.bat

### Dependencies not installing
Make sure you have internet connection and run:
```bash
flutter pub get
```

### Chrome not opening
Make sure Chrome is installed and run:
```bash
flutter devices
```
This will list available devices. You should see "Chrome" in the list.
