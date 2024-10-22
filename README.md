# Pomodoro Timer for macOS

A sleek and efficient Pomodoro Timer built with SwiftUI for macOS. Stay productive with focused work sessions and regular breaks.

![Pomodoro Timer Screenshot](./screenshots/main.png)

## Features

- 🎯 Classic Pomodoro technique implementation
- ⏱ 25-minute work sessions
- ☕️ 5-minute short breaks
- 🌟 15-minute long breaks after 4 pomodoros
- 📊 Session history tracking
- 💫 Native macOS app with modern SwiftUI interface
- 🎨 Minimalist design
- 🔄 Automatic session transitions
- 📈 Progress tracking

## Installation

### Download
Download the latest version from the [Releases](https://github.com/fearlipe/pomovelar/releases) page.

### Manual Installation
1. Extract and drag `Pomodoro Timer.app` to your Applications folder
2. Launch from Applications or Spotlight

### Build from Source
Prerequisites:
- Xcode 14.0 or later
- macOS 12.0 or later
- Apple Developer Account (for signing)

Steps:
```bash
# Clone the repository
git clone https://github.com/fearlipe/pomovelar.git

# Navigate to project directory
cd pomovelar

# Open in Xcode
open pomovelar.xcodeproj

# Build the project
# In Xcode: Product > Build
```

## Usage

1. Launch the app
2. Click "Start" to begin a work session
3. Work until the timer completes
4. Take a break when prompted
5. View your session history in the left panel

## Development

### Project Structure
```
PomodoroTimer/
├── Models/
│   ├── TimerState.swift
│   └── HistoryEntry.swift
├── Views/
│   ├── ContentView.swift
│   ├── TimerView.swift
│   └── HistoryView.swift
├── Resources/
│   └── Assets.xcassets/
└── PomodoroTimerApp.swift
```

### Building the Icon
```bash
# Install required tools
brew install librsvg imagemagick

# Run the icon generation script
./scripts/create_icons.sh
```

### Creating a Release Build
1. Update version number in Xcode
2. Archive the app: Product > Archive
3. Export with Developer ID signing
4. Create DMG using create-dmg
5. Notarize the DMG using notarytool

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Tech Stack

- SwiftUI
- Combine
- macOS AppKit integration
- Swift 5.5+

## Future Improvements

- [ ] Custom timer durations
- [ ] Sound notifications
- [ ] Menu bar integration
- [ ] Task labeling
- [ ] Statistics and analytics
- [ ] Data export
- [ ] Cloud sync
- [ ] Themes

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Acknowledgments

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [The Pomodoro Technique®](https://francescocirillo.com/pages/pomodoro-technique)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Contact

Felipe Avelar - [@fearlipe](https://x.com/fearlipe)

Project Link: [https://github.com/fearlipe/pomovelar](https://github.com/fearlipe/pomovelar)

## Support

⭐️ If you found this project helpful, please give it a star!

For support, email support@avelar.me or open an issue in the repository.
