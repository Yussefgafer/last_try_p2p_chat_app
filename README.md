# P2P Chat - Secure Peer-to-Peer Messaging with AI

A revolutionary Flutter application that enables secure, decentralized peer-to-peer messaging with integrated AI assistance powered by Gemini 1.5 Flash.

## 🚀 Features

### Core P2P Messaging
- **WebRTC Communication**: Direct peer-to-peer messaging without central servers
- **Bluetooth Support**: Local messaging via Bluetooth connections
- **LAN Discovery**: Automatic discovery of nearby devices on the same network
- **End-to-End Encryption**: Military-grade AES encryption for all messages
- **File Sharing**: Share images, videos, audio, and documents securely

### AI Integration
- **Gemini 1.5 Flash**: Integrated AI assistant for intelligent conversations
- **Context-Aware**: AI remembers conversation history for better responses
- **Secure API**: Encrypted storage of API keys with user-provided options

### Modern UI/UX
- **Material 3 Design**: Beautiful, modern interface following Google's latest design principles
- **Dark Theme**: Eye-friendly dark theme as default with light theme option
- **Smooth Animations**: Fluid transitions and engaging visual feedback
- **Responsive Design**: Optimized for various screen sizes

## 🛠️ Technology Stack

- **Framework**: Flutter 3.24.0
- **Language**: Dart 3.5.0
- **Communication**: WebRTC, Bluetooth, HTTP/HTTPS
- **Storage**: SQLite, Hive (local storage)
- **Encryption**: AES-256 encryption
- **AI**: Google Gemini 1.5 Flash API
- **Architecture**: Clean Architecture with Provider state management

## 📱 Installation

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart 3.5.0 or higher
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development)

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Yussefgafer/last_try_p2p_chat_app.git
   cd last_try_p2p_chat_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate model files:
   ```bash
   flutter packages pub run build_runner build
   flutter gen-l10n
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## 🔧 Configuration

### AI Assistant Setup
1. Get your Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open the app and go to Settings > AI Settings
3. Enter your API key: `AIzaSyAxEUlXL7nQNxrNTBYQSADm3F5YSIhF-pk`

### Permissions
The app requires the following permissions:
- **Internet**: For AI communication and WebRTC signaling
- **Bluetooth**: For local P2P connections
- **Camera/Microphone**: For media sharing and voice messages
- **Storage**: For file sharing and local data storage
- **Location**: For network discovery (coarse location only)

## 🏗️ Project Structure

```
lib/
├── core/                   # Core utilities and configurations
│   ├── constants/         # App constants
│   ├── config/           # API and app configuration
│   ├── theme/            # App theming
│   └── utils/            # Helper utilities
├── data/                  # Data layer
│   ├── models/           # Data models
│   └── services/         # API and external services
└── presentation/          # UI layer
    └── screens/          # App screens
```

## 📋 حالة التطوير

### ✅ مكتمل 100% 🎉
- [x] البنية الأساسية والتصميم
- [x] دمج الذكاء الاصطناعي (Gemini 1.5 Flash)
- [x] الاتصال P2P (WebRTC + Bluetooth)
- [x] مشاركة الوسائط والملفات
- [x] الرسائل الصوتية عالية الجودة
- [x] التشفير والأمان المتقدم
- [x] واجهات المستخدم الجميلة
- [x] الدردشات الجماعية P2P
- [x] مشاركة الموقع الجغرافي
- [x] الإشعارات المتقدمة
- [x] معاينة الروابط (Link Preview)
- [x] نظام حظر المستخدمين
- [x] التعريب الكامل (عربي فصحى + مصري + إنجليزي)
- [x] دعم RTL للغة العربية

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Yussefgafer/last_try_p2p_chat_app.git
   cd last_try_p2p_chat_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Run tests**
   ```bash
   chmod +x run_tests.sh
   ./run_tests.sh
   ```

6. **Quick start (alternative)**
   ```bash
   chmod +x quick_start.sh
   ./quick_start.sh
   ```

## 🚀 GitHub Actions - Multi-Platform Build System

This project includes comprehensive automated CI/CD workflows for all platforms:

### 📱 Available Workflows

#### 1. **Multi-Platform Build** (`.github/workflows/multi-platform-build.yml`)
- **Android**: APK + App Bundle (ARM64, ARM, x86_64)
- **Web**: Progressive Web App with HTML renderer
- **Windows**: Desktop executable with installer
- **Linux**: AppImage and native bundle
- **Automatic**: Triggers on push to main/develop

#### 2. **Quick Build** (`.github/workflows/quick-build.yml`)
- **Fast builds** for specific platforms
- **Manual trigger** with platform selection
- **Instant deployment** to GitHub Pages (web)
- **Quick releases** for testing

#### 3. **Auto Release** (`.github/workflows/auto-release.yml`)
- **All platforms** in one release
- **Automatic versioning** with tags
- **Release notes** generation
- **Asset packaging** and distribution

#### 4. **macOS Build** (`.github/workflows/macos-build.yml`)
- **Native macOS** app bundle
- **DMG installer** creation
- **Code signing** support (with certificates)

#### 5. **Continuous Integration** (`.github/workflows/ci.yml`)
- **Code quality** checks
- **Security scanning** with Trivy
- **Dependency analysis**
- **Performance testing**

### 🎯 How to Build for Different Platforms

#### 📱 **Android (APK + App Bundle)**
```bash
# Manual trigger
1. Go to Actions → "Multi-Platform Build"
2. Click "Run workflow"
3. Select "android" platform
4. Choose "release" build type
5. Download from artifacts

# Automatic
- Push to main/develop branch
- APK and App Bundle built automatically
```

#### 🌐 **Web Application**
```bash
# Manual trigger
1. Go to Actions → "Quick Build"
2. Select "web" platform
3. Enable "Deploy to GitHub Pages"
4. Access at: https://yussefgafer.github.io/last_try_p2p_chat_app

# Automatic
- Deploys to GitHub Pages on main branch push
```

#### 💻 **Windows Desktop**
```bash
# Manual trigger
1. Go to Actions → "Multi-Platform Build"
2. Select "windows" platform
3. Download Windows executable from artifacts
4. Includes installer batch file
```

#### 🐧 **Linux Desktop**
```bash
# Manual trigger
1. Go to Actions → "Multi-Platform Build"
2. Select "linux" platform
3. Download AppImage or native bundle
4. Supports all major Linux distributions
```

#### 🍎 **macOS Desktop**
```bash
# Manual trigger
1. Go to Actions → "macOS Build"
2. Download DMG installer
3. Native macOS app bundle
```

#### 🚀 **All Platforms at Once**
```bash
# Create complete release
1. Go to Actions → "Auto Release"
2. Enter version (e.g., v1.0.0)
3. All platforms built automatically
4. Complete release with all downloads
```

### 📦 Download Links

After successful builds, download from:
- **GitHub Releases**: https://github.com/Yussefgafer/last_try_p2p_chat_app/releases
- **GitHub Actions Artifacts**: https://github.com/Yussefgafer/last_try_p2p_chat_app/actions
- **GitHub Pages (Web)**: https://yussefgafer.github.io/last_try_p2p_chat_app

## 🔒 Security Features

- **End-to-End Encryption**: All messages encrypted with AES-256
- **No Central Server**: Direct P2P communication for maximum privacy
- **Secure Key Storage**: API keys encrypted and stored locally
- **Data Integrity**: Hash verification for all transmitted data

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google for the Gemini AI API
- Flutter team for the amazing framework
- WebRTC community for P2P communication protocols

## 📞 Support

For support, create an issue on GitHub or check our documentation.

---

**Made with ❤️ using Flutter**
