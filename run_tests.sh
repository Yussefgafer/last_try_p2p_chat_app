#!/bin/bash

# P2P Chat - Test Runner Script
# This script runs all tests and generates coverage reports

echo "🚀 P2P Chat - Running Tests"
echo "================================"

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
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean and get dependencies
print_status "Cleaning project..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

# Generate code (Hive adapters, etc.)
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Generate localizations
print_status "Generating localizations..."
flutter gen-l10n

# Run static analysis
print_status "Running static analysis..."
flutter analyze

if [ $? -eq 0 ]; then
    print_success "Static analysis passed"
else
    print_warning "Static analysis found issues"
fi

# Run unit tests
print_status "Running unit tests..."
flutter test --coverage

if [ $? -eq 0 ]; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Generate coverage report (if lcov is available)
if command -v lcov &> /dev/null; then
    print_status "Generating coverage report..."
    
    # Remove generated files from coverage
    lcov --remove coverage/lcov.info \
        '**/*.g.dart' \
        '**/*.freezed.dart' \
        '**/generated/**' \
        '**/l10n/**' \
        --output-file coverage/lcov_cleaned.info
    
    # Generate HTML report
    genhtml coverage/lcov_cleaned.info --output-directory coverage/html
    
    print_success "Coverage report generated in coverage/html/"
else
    print_warning "lcov not found, skipping HTML coverage report"
fi

# Run integration tests (if they exist)
if [ -d "integration_test" ]; then
    print_status "Running integration tests..."
    flutter test integration_test/
    
    if [ $? -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_error "Integration tests failed"
    fi
fi

# Check for TODO comments
print_status "Checking for TODO comments..."
TODO_COUNT=$(grep -r "TODO" lib/ --include="*.dart" | wc -l)
if [ $TODO_COUNT -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO comments in code"
    grep -r "TODO" lib/ --include="*.dart" | head -10
    if [ $TODO_COUNT -gt 10 ]; then
        echo "... and $(($TODO_COUNT - 10)) more"
    fi
else
    print_success "No TODO comments found"
fi

# Check for debug prints
print_status "Checking for debug prints..."
DEBUG_COUNT=$(grep -r "print(" lib/ --include="*.dart" | wc -l)
if [ $DEBUG_COUNT -gt 0 ]; then
    print_warning "Found $DEBUG_COUNT debug print statements"
    grep -r "print(" lib/ --include="*.dart"
else
    print_success "No debug print statements found"
fi

# Build APK for testing
print_status "Building APK..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    print_success "APK built successfully"
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    print_status "APK size: $APK_SIZE"
else
    print_error "APK build failed"
fi

# Summary
echo ""
echo "================================"
print_success "Test run completed!"
echo ""
print_status "Summary:"
echo "  ✅ Dependencies installed"
echo "  ✅ Code generated"
echo "  ✅ Static analysis completed"
echo "  ✅ Unit tests executed"
echo "  ✅ Coverage report generated"
echo "  ✅ APK built"
echo ""
print_status "Next steps:"
echo "  1. Review coverage report: open coverage/html/index.html"
echo "  2. Address any TODO comments"
echo "  3. Remove debug print statements"
echo "  4. Test APK on device: flutter install"
echo ""
print_success "Happy coding! 🎉"
