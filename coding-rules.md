---
description: 
globs: 
alwaysApply: true
---
---
description: Flutter MVVM coding guidelines and best practices
globs:
alwaysApply: true
---

# 📝 Flutter MVVM Coding Rules

## 🔍 Overview

This document defines coding standards for Flutter projects using the MVVM (Model-View-ViewModel) architecture. Follow these guidelines to maintain clean, maintainable, and consistent codebase.

## 📋 Contents

1. [General Coding Standards](#-general-coding-standards)
2. [ViewModels](#-viewmodels)
3. [Views](#-views)
4. [Models](#-models)
5. [Helpers & Services](#-helpers--services)
6. [State Management](#-state-management)
7. [Widget Usage](#-widget-usage)
8. [Navigation](#-navigation)
9. [Error Handling](#-error-handling)

## 📏 General Coding Standards

### Code Writing
- **Naming Conventions**:
  - Variables: `camelCase` - `userAge`, `isLoading`
  - Classes: `PascalCase` - `HomeView`, `ApiService`
  - Files: snake_case - `home_view.dart`, `api_service.dart`
  - Private variables begin with `_`: `_apiClient`
  - Boolean variables start with `is`, `has`, `can`: `isLoading`

- **Code Structure**:
  - Keep code formatted with `dart format .`
  - Fix all Dart Analysis warnings
  - Each function should do one task
  - Document complex code blocks with comments

### Good and Bad Examples

```dart
// GOOD EXAMPLE - Clean code with async/await
Future<void> checkPremiumStatus() async {
  _isLoading = true;
  notifyListeners();
  
  try {
    final isPremium = await _userService.isPremiumUser();
    _isPremiumUser = isPremium;
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// BAD EXAMPLE - Complex then/catch chain
void check() {
  _isLoading = true;
  notifyListeners();
  _userService.isPremiumUser().then((val) {
    _isPremiumUser = val;
    _isLoading = false;
    notifyListeners();
  }).catchError((e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  });
}
```

## 🧠 ViewModels

### Key Rules
- Every ViewModel should extend `ChangeNotifier`
- Call `notifyListeners()` after state changes
- All state variables must be private (prefixed with `_`)
- Use getters for accessing state from outside
- Business logic should be in ViewModels, not Views

### Example ViewModel

```dart
class HomeViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _products.isEmpty && !_isLoading && !hasError;
  
  // Data loading
  Future<void> loadProducts() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getProducts();
      _products = data;
    } catch (e) {
      _error = 'Error loading products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // User interaction
  Future<void> refreshProducts() async {
    await loadProducts();
  }
  
  @override
  void dispose() {
    // Cleanup operations if needed
    super.dispose();
  }
}
```

## 👁 Views

### Key Rules
- View classes should only contain UI and user interactions
- Business logic belongs in ViewModel, not View
- Use Provider and Consumer widgets for state management
- Show different UI for different states (loading, error, empty)

### Example View

```dart
class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Call ViewModel method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // Loading state
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Error state
        if (viewModel.hasError) {
          return ErrorWidget(
            message: viewModel.error!,
            onRetry: viewModel.loadProducts,
          );
        }
        
        // Empty state
        if (viewModel.isEmpty) {
          return const EmptyStateWidget(message: 'No products found');
        }
        
        // Data state
        return ListView.builder(
          itemCount: viewModel.products.length,
          itemBuilder: (context, index) {
            final product = viewModel.products[index];
            return ProductItem(product: product);
          },
        );
      },
    );
  }
}
```

## 📦 Models

### Key Rules
- Model classes should be for data transportation
- Make models immutable - use `final` fields
- Include JSON conversion methods: `fromJson` and `toJson`
- Add `copyWith()` method for modifications when needed

### Example Model

```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isPremium;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.isPremium = false,
  });

  // JSON conversion
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
    };
  }

  // Copy with method
  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
```

## 🛠 Helpers & Services

### Key Rules
- Each helper class should focus on a specific functionality
- Use singleton pattern - as defined in setup rules
- Create clean API design - simple and intuitive method names
- Follow the structure defined in setup rules for NavigationHelper, StorageHelper, and ApiService

### Example API Service

```dart
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  // Dio HTTP client
  late final Dio _dio;
  
  ApiService._internal() {
    _initDio();
  }
  
  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add logging
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }
  
  // GET request
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('Could not get products', e);
    }
  }
  
  // POST request
  Future<User> createUser(User user) async {
    try {
      final response = await _dio.post('/users', data: user.toJson());
      return User.fromJson(response.data);
    } catch (e) {
      throw ApiException('Could not create user', e);
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final dynamic originalError;
  
  ApiException(this.message, this.originalError);
  
  @override
  String toString() => 'ApiException: $message';
}
```

## 🔄 State Management

### Key Rules
- Implement MVVM architecture with Provider package
- Use AppProvider for global state - as defined in setup rules
- Create separate ViewModel for each screen
- Use AppProvider for communication between ViewModels

### Example Implementation

```dart
// main.dart - MultiProvider setup
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        // Other ViewModels
      ],
      child: MyApp(),
    ),
  );
}

// AppProvider - use as defined in setup rules
class AppProvider extends ChangeNotifier {
  // Tab index
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;
  
  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }
  
  // Home scroll control
  bool _homeScrollToTopRequested = false;
  bool get homeScrollToTopRequested => _homeScrollToTopRequested;
  
  set homeScrollToTopRequested(bool value) {
    _homeScrollToTopRequested = value;
    if (value) {
      Future.microtask(() {
        _homeScrollToTopRequested = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }
}
```

## 🧩 Widget Usage

### Key Rules
- Create reusable custom widgets
- Collect common UI components in a `widgets` folder
- Break complex UIs into smaller pieces
- Mark required parameters as `required`

### Example Custom Widget

```dart
// Custom button widget
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      ),
    );
  }
}

// Usage
AppButton(
  text: 'Login',
  isLoading: viewModel.isLoading,
  isFullWidth: true,
  onPressed: () => viewModel.login(),
)
```

## 📱 Navigation

### Key Rules
- Use the NavigationHelper class from setup rules
- Use named routes for all routes
- Define routes in the AppRoutes class
- Call NavigationHelper methods for push and replace operations

### Example Usage

```dart
// Route definitions in constants.dart
class AppRoutes {
  static const String splash = '/splash';
  static const String onboard = '/onboard';
  static const String maintab = '/maintab';
  static const String productDetail = '/product-detail';
}

// Using methods defined in NavigationHelper
// (Already defined in setup rules)

// Usage in ViewModel
void showProductDetail(BuildContext context, int productId) {
  final product = _products.firstWhere((p) => p.id == productId);
  NavigationHelper.navigateTo(
    context, 
    AppRoutes.productDetail,
    arguments: {'product': product}
  );
}

// Clean navigation in SplashViewModel
void checkNavigation(BuildContext context) async {
  final bool onboardingShown = _storageHelper.isOnboardingCompleted();
  
  if (onboardingShown) {
    NavigationHelper.goToMainTabAndClearStack(context);
  } else {
    NavigationHelper.goToOnboardingAndClearStack(context);
  }
}
```

## ⚠️ Error Handling

### Key Rules
- Handle error states in ViewModel
- Show user-friendly error messages
- Use custom exception classes (like ApiException)
- Create separate widgets for error screens

### Example Error Handling

```dart
// Error handling in ViewModel
Future<void> loadProducts() async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    _products = await _apiService.getProducts();
  } on ApiException catch (e) {
    _error = e.message;
    debugPrint('API Error: ${e.originalError}');
  } catch (e) {
    _error = 'An unexpected error occurred';
    debugPrint('Unexpected error: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// Error UI widget
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  
  const ErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
```

## 🚀 Recommended Workflow

When working on a Flutter MVVM project, follow these steps:

1. **Planning**:
   - Review UI mockup of the screen
   - Identify required state variables
   - Define user interactions and business flows

2. **ViewModel Development**:
   - Define necessary state variables in ViewModel
   - Create methods for API calls and data transformations
   - Handle error cases

3. **UI Development**:
   - Create the static UI of the screen
   - Connect the ViewModel with Provider
   - Handle loading, error, and data states

4. **Navigation Integration**:
   - Register the new screen in the routing system
   - Add necessary methods to NavigationHelper

## 📝 Code Review Checklist

Check these points during code reviews:

- [ ] Are all state variables private (starting with `_`)?
- [ ] Is `notifyListeners()` called after each state change?
- [ ] Are all asynchronous operations written with `async/await`?
- [ ] Are error cases properly handled?
- [ ] Are UI logic and business logic separated?
- [ ] Is NavigationHelper being used?
- [ ] Are repeated code blocks extracted into common methods?
- [ ] Are Dart analysis warnings cleared?
