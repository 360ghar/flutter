# 360Ghar - Flutter Real Estate App

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![GetX](https://img.shields.io/badge/State%20Management-GetX-orange)
![Supabase](https://img.shields.io/badge/Backend-Supabase-green?logo=supabase)

**360Ghar** is a modern Flutter real estate application that revolutionizes property discovery with a **Bumble-inspired swipe interface**. It offers an engaging, intuitive way for users to find their dream homes, complete with 360° virtual tours, detailed property information, and seamless agent communication.

## ✨ Features

-   **Bumble-Style Swiping:** Like or pass on properties with a simple swipe.
-   **360° Virtual Tours:** Immerse yourself in properties with integrated virtual tours.
-   **Advanced Filtering:** Narrow down searches by price, location, property type, amenities, and more.
-   **Map Exploration:** Discover properties visually on an interactive map.
-   **User Authentication:** Secure sign-up, login, and profile management powered by Supabase.
-   **Likes & History:** Keep track of liked and passed properties.
-   **Visit Scheduling:** Schedule property visits directly through the app.
-   **Detailed Property Views:** Access comprehensive information, images, and amenities for each listing.
-   **Clean Architecture:** Organized into `core` and `features` modules for scalability and maintainability.
-   **Light & Dark Mode:** Beautifully crafted themes for user preference.
-   **Localization:** Multi-language support (English & Hindi).

## 🛠️ Tech Stack & Architecture

This project is built with a modern, scalable technology stack and follows a clean, feature-first architecture.

-   **Framework:** [Flutter](https://flutter.dev/)
-   **State Management:** [GetX](https://pub.dev/packages/get) (for state, dependency, and route management)
-   **Backend:** [Supabase](https://supabase.io/) (Authentication, Database, Storage)
-   **Networking:** [Dio](https://pub.dev/packages/dio)
-   **Mapping:** [flutter_map](https://pub.dev/packages/flutter_map)
-   **Code Generation:** [json_serializable](https://pub.dev/packages/json_serializable) for type-safe models
-   **Local Storage:** [get_storage](https://pub.dev/packages/get_storage)
-   **UI:** [Google Fonts](https://pub.dev/packages/google_fonts), [CachedNetworkImage](https://pub.dev/packages/cached_network_image), [Shimmer](https://pub.dev/packages/shimmer)

### Architecture

The codebase is structured using a **GetX Clean Architecture** pattern, separating the application into two main parts:

-   `lib/core`: Contains shared application logic, infrastructure, and base components. This includes API services, data models, repositories, global controllers (Auth, Theme), routing, and common widgets.
-   `lib/features`: Each distinct feature of the app (e.g., `discover`, `explore`, `profile`) is a self-contained module with its own views, controllers, and bindings.

```
lib/
├── core/                  # Core infrastructure and shared components
│   ├── bindings/          # Global dependency injection
│   ├── controllers/       # Core business logic (Auth, Location, Theme)
│   ├── data/              # Models, Providers, Repositories
│   ├── routes/            # App navigation configuration
│   └── ...
├── features/              # Feature-based modules
│   ├── auth/              # Authentication and profile completion
│   ├── discover/          # Property discovery and swipe functionality
│   ├── explore/           # Map exploration feature
│   ├── likes/             # Liked/passed properties management
│   └── ...
└── main.dart              # App entry point
```

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

-   Flutter SDK (version 3.x or higher)
-   Dart SDK (version 3.x or higher)
-   An editor like VS Code or Android Studio

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/360ghar-flutter.git
    cd 360ghar-flutter
    ```

2.  **Set up environment variables:**
    Create two files in the root of the project: `.env.development` and `.env.production`. You can copy the example file:
    ```bash
    cp .env.example .env.development
    ```
    Fill in the required values in `.env.development` with your Supabase and API credentials:
    ```env
    # Supabase Credentials
    SUPABASE_URL=https://your-project-ref.supabase.co
    SUPABASE_ANON_KEY=your-supabase-anon-key

    # API Base URL (if different from Supabase)
    API_BASE_URL=http://your-backend-api.com/api/v1

    # Google Places API Key (for location search)
    GOOGLE_PLACES_API_KEY=your-google-places-api-key

    # Debugging Flags
    DEBUG_MODE=true
    LOG_API_CALLS=true
    ```

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run code generation:**
    The project uses `json_serializable` for data models. Run the build runner to generate the necessary files:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
    If you plan to modify models, run the watcher:
    ```bash
    dart run build_runner watch --delete-conflicting-outputs
    ```

5.  **Run the application:**
    ```bash
    flutter run
    ```

## 📱 Bottom Navigation

The app features a 5-tab bottom navigation bar for easy access to key features:

-   **Profile:** User management, settings, and preferences.
-   **Explore:** Map view with property markers for geographical discovery.
-   **Discover (Home):** The main swipe interface for liking or passing on properties.
-   **Likes:** A gallery of your favorited and passed properties.
-   **Visits:** Manage agent appointments and scheduled property tours.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

---