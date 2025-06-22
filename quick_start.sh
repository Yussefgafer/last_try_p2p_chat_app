#!/bin/bash

# P2P Chat - Quick Start Script
# This script quickly sets up and runs the P2P Chat application

echo "🚀 P2P Chat - Quick Start"
echo "========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    print_status "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter found"

# Quick setup
print_status "Running quick setup..."

# Clean and get dependencies
print_status "Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    print_error "Failed to get dependencies"
    exit 1
fi

# Generate code (ignore errors for quick start)
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1
flutter gen-l10n > /dev/null 2>&1

# Check for connected devices
print_status "Checking for connected devices..."
DEVICES=$(flutter devices --machine | jq -r '.[].id' 2>/dev/null || flutter devices | grep -c "•")

if [ "$DEVICES" = "0" ] || [ -z "$DEVICES" ]; then
    print_warning "No devices found!"
    print_status "Please connect an Android device or start an emulator"
    print_status "Available options:"
    echo "  1. Connect Android device via USB"
    echo "  2. Start Android emulator"
    echo "  3. Use Chrome for web version (experimental)"
    echo ""
    read -p "Press Enter when device is ready, or Ctrl+C to exit..."
fi

# Show available devices
print_status "Available devices:"
flutter devices

# Ask user which device to use
echo ""
print_status "Choose how to run the app:"
echo "  1. Run on connected device (recommended)"
echo "  2. Run in debug mode with hot reload"
echo "  3. Run in profile mode (performance testing)"
echo "  4. Build APK only"
echo "  5. Run tests first"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        print_status "Running on connected device..."
        flutter run
        ;;
    2)
        print_status "Running in debug mode with hot reload..."
        flutter run --debug
        ;;
    3)
        print_status "Running in profile mode..."
        flutter run --profile
        ;;
    4)
        print_status "Building APK..."
        flutter build apk --debug
        if [ $? -eq 0 ]; then
            APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            print_success "APK built successfully!"
            print_status "Location: $APK_PATH"
            print_status "Size: $APK_SIZE"
            print_status "Install with: adb install $APK_PATH"
        fi
        ;;
    5)
        print_status "Running tests first..."
        flutter test
        if [ $? -eq 0 ]; then
            print_success "All tests passed!"
            print_status "Now running the app..."
            flutter run
        else
            print_error "Tests failed! Please fix issues before running."
            exit 1
        fi
        ;;
    *)
        print_warning "Invalid choice. Running default mode..."
        flutter run
        ;;
esac

# Post-run information
echo ""
print_success "🎉 P2P Chat Quick Start Complete!"
echo ""
print_status "Next steps:"
echo "  1. Add your Gemini API key in app settings"
echo "  2. Grant necessary permissions"
echo "  3. Start chatting with AI or connect to peers"
echo ""
print_status "Useful commands:"
echo "  • flutter run --hot                 - Run with hot reload"
echo "  • flutter run --release             - Run release build"
echo "  • flutter build apk                 - Build APK"
echo "  • ./run_tests.sh                    - Run full test suite"
echo "  • ./setup_project.sh                - Full project setup"
echo ""
print_status "Documentation:"
echo "  • README.md                         - Project overview"
echo "  • GETTING_STARTED.md                - Detailed setup guide"
echo "  • CONTRIBUTING.md                   - Contribution guidelines"
echo ""
print_success "Happy coding! 🚀"
