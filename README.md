# AI Public Transport Assistant

A Flutter web application that provides real-time transit information and an AI-powered chatbot assistant for commuters in **Oman** and **Belgium**.

## Features

- **Departure Board** — View live departure schedules for trains and buses
- **AI Chatbot** — Ask questions about delays, routes, and stations in natural language
- **Multi-language Support** — The assistant responds in the same language you write in
- **Conversation History** — The chatbot remembers context within a session

## Tech Stack

- **Flutter** (Web)
- **Anthropic Claude API** — Powers the AI assistant (`claude-haiku-4-5`)
- **flutter_dotenv** — Secure environment variable management
- **http** — REST API communication

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.5`
- An [Anthropic API key](https://console.anthropic.com)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/JuhainaAlbadi/transit_app.git
   cd transit_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

4. Add your Anthropic API key to `.env`:
   ```
   ANTHROPIC_API_KEY=your_api_key_here
   ```

5. Run the app:
   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```

> **Note:** The `--disable-web-security` flag is required for local development due to browser CORS restrictions when calling the Anthropic API directly. Do not use this flag in production.

## Project Structure

```
lib/
├── main.dart              # App entry point and navigation
├── screens/
│   ├── home_screen.dart   # Departure board screen
│   └── chat_screen.dart   # AI chatbot screen
└── services/
    └── gemini_service.dart # Anthropic API integration
```

## Environment Variables

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | Your Anthropic API key from console.anthropic.com |

Never commit your `.env` file. It is listed in `.gitignore` by default.
