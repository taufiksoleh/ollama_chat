# Ollama Chat

A Flutter-based chat application that integrates with Ollama for intelligent conversations. This application provides a modern, user-friendly interface for interacting with Ollama's language models.

## Features

- Clean and intuitive chat interface
- Integration with Ollama's language models
- Material Design 3 theming
- Cross-platform support (iOS, Android, Web, Desktop)
- Web search capabilities using Google Custom Search

## Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter](https://flutter.dev/docs/get-started/install) (SDK version ^3.5.1)
- [Ollama](https://ollama.ai) running locally
- Google API Key and Custom Search Engine ID for web search functionality

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/taufiksoleh/ollama_chat.git
cd ollama_chat
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API keys:
- Open `lib/config/api_config.dart`
- Add your Google API Key and Custom Search Engine ID

4. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/          # Configuration files
├── data/            # Data layer (repositories implementations)
├── domain/          # Domain layer (entities, repositories interfaces)
├── presentation/    # UI layer (screens, widgets)
└── main.dart        # Application entry point
```

## Configuration

To enable web search functionality, you need to:
1. Create a Google Cloud Project
2. Enable Custom Search API
3. Create API credentials
4. Set up a Custom Search Engine
5. Add the credentials to `lib/config/api_config.dart`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Ollama](https://ollama.ai) for providing the language model capabilities
- [Flutter](https://flutter.dev) for the amazing cross-platform framework
- All contributors who help improve this project
