# Mitram: Your Smart Farming Ally

Mitram is a Flutter-based mobile application designed to assist farmers with smart farming solutions. It provides AI-powered crop diagnosis, weather information, and a platform for farmers to connect and share knowledge.

## Features

*   **User Authentication:** Secure login and signup functionality using Firebase Authentication.
*   **AI-Powered Crop Diagnosis:** Users can take or upload a photo of a crop to get an instant diagnosis of diseases, along with treatment and prevention advice. This feature is powered by Google's Gemini API.
*   **Weather Information:** The app fetches and displays current weather data based on the user's location.
*   **Profile Management:** Users can view their profile information and log out of the application.
*   **Bottom Navigation:** Easy navigation between the Home, Diagnose, and Profile screens.

## Getting Started

Follow these instructions to get a local copy of the project up and running on your machine for development and testing purposes.

### Prerequisites

You will need to have the Flutter SDK installed on your machine. For instructions on how to install Flutter, please refer to the [official Flutter documentation](https://docs.flutter.dev/get-started/install).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/mitram.git
    cd mitram
    ```

2.  **Create the API Keys File:**
    This project uses API keys for Google Gemini and OpenWeatherMap. These keys are stored in a file that is not tracked by Git for security reasons. You will need to create this file yourself.

    Create a new file at `lib/utils/api_keys.dart` and add the following content, replacing the placeholder text with your actual API keys:

    ```dart
    // lib/utils/api_keys.dart

    const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
    const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
    ```

3.  **Install dependencies:**
    Run the following command to fetch the project's dependencies:
    ```sh
    flutter pub get
    ```

4.  **Run the application:**
    Connect a device or start an emulator, then run the following command to start the application:
    ```sh
    flutter run
