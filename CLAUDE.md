# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "Antique Identifier" - an antique identification and collection management app that uses AI/ML for antique recognition and includes premium features through RevenueCat.

## Common Commands

### Development
- `flutter run` - Run the app in development mode
- `flutter run --debug` - Run with debugging enabled
- `flutter run --release` - Run optimized release build

### Testing & Quality
- `flutter test` - Run unit and widget tests
- `flutter analyze` - Run static analysis (uses flutter_lints rules)

### Build & Deploy
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web version
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Architecture Overview

### State Management
- **Provider pattern**: Uses `provider` package for state management
- **ViewModels**: Each major screen has a corresponding ViewModel (e.g., `HomeViewModel`, `ScanViewModel`)
- **Global state**: `AppProvider` manages app-wide state like tab selection, premium status, theme, and language

### Project Structure
```
lib/
├── constants/app_constants.dart    # App colors, text styles, routes, strings, sizes
├── providers/app_provider.dart     # Global app state management
├── helpers/                        # Utility classes
│   ├── storage_helper.dart        # SharedPreferences wrapper
│   ├── revenuecat_helper.dart     # Premium subscription management
│   └── navigation_helper.dart     # Navigation utilities
├── services/                       # External service integrations
│   ├── api_service.dart           # HTTP API calls
│   ├── supabase_service.dart      # Supabase backend integration
│   └── collection_service.dart    # Collection management
├── screens/                        # UI screens with View/ViewModel pattern
│   ├── antique_home/              # Home screen with scanning features
│   ├── antique_scan/              # Camera-based antique scanning
│   ├── antique_collection/        # User's antique collection
│   ├── antique_premium/           # Premium subscription flow
│   └── [other screens]/
└── widgets/                        # Reusable UI components
```

### Key Dependencies
- **UI**: `flutter_screenutil` for responsive design, `google_fonts` (Playfair Display)
- **Navigation**: Flutter's built-in routing with named routes
- **Networking**: `dio` for HTTP requests
- **Camera**: `camera`, `image_picker`, `image_cropper` for antique scanning
- **Storage**: `shared_preferences` for local data persistence
- **Backend**: `supabase_flutter` for backend services
- **Subscriptions**: `purchases_flutter` (RevenueCat) for premium features
- **Animations**: `lottie` for animations, `animated_bottom_navigation_bar`

### Design System
- **Color scheme**: Antique-themed browns and golds defined in `AppColors`
- **Typography**: Playfair Display font family with responsive sizing via `flutter_screenutil`
- **Responsive design**: Base design size is 375x812 (iPhone X)
- **Theme**: Material 3 with custom color scheme

### Navigation Flow
- Splash → Onboarding (if first time) → Main Tab Navigation
- Main tabs: Home, Discover, Scan, Collection, Settings
- Modal routes for Premium paywall and Antique details

### Premium Features
- Managed through RevenueCat integration
- Premium status stored in `AppProvider` and persisted via `StorageHelper`
- Premium-only features gated throughout the app

## Development Notes

### Code Style
- Uses flutter_lints for code quality
- ViewModels extend `ChangeNotifier` for reactive UI updates
- Consistent naming: screens have separate `_view.dart` and `_viewmodel.dart` files
- Assets organized in `assets/` with subdirectories for different types

### Testing
- Test files should be placed in `test/` directory
- Use `flutter test` to run all tests

### State Management Pattern
- Each screen's state is managed by its corresponding ViewModel
- Global app state (tab navigation, premium status, settings) is handled by `AppProvider`
- Use `Consumer<ViewModel>` or `context.watch<ViewModel>()` to rebuild UI on state changes