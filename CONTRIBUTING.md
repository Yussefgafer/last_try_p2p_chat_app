# Contributing to P2P Chat

Thank you for your interest in contributing to P2P Chat! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Flutter 3.24.0 or later
- Dart 3.5.0 or later
- Android Studio or VS Code
- Git

### Setup Development Environment
1. **Clone the repository**
   ```bash
   git clone https://github.com/Yussefgafer/last_try_p2p_chat_app.git
   cd last_try_p2p_chat_app
   ```

2. **Run setup script**
   ```bash
   chmod +x setup_project.sh
   ./setup_project.sh
   ```

3. **Verify setup**
   ```bash
   flutter doctor
   flutter test
   ```

## 📋 Development Guidelines

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format code
- Run `flutter analyze` before committing
- Maximum line length: 100 characters

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private members**: prefix with `_`

### Project Structure
```
lib/
├── core/           # Core utilities and constants
├── data/           # Data layer (models, services)
├── presentation/   # UI layer (screens, widgets)
└── l10n/          # Localization files
```

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` new features
- `fix:` bug fixes
- `docs:` documentation changes
- `style:` code style changes
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance tasks

Example:
```
feat(chat): add voice message support
fix(p2p): resolve WebRTC connection issues
docs(readme): update installation instructions
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/message_service_test.dart

# Run integration tests
flutter test integration_test/
```

### Writing Tests
- Write unit tests for all services and utilities
- Write widget tests for complex UI components
- Write integration tests for critical user flows
- Aim for >80% code coverage

### Test Structure
```dart
group('MessageService', () {
  late MessageService messageService;
  
  setUp(() {
    messageService = MessageService();
  });
  
  tearDown(() {
    messageService.dispose();
  });
  
  test('should save message successfully', () async {
    // Arrange
    final message = MessageModel(/* ... */);
    
    // Act
    await messageService.saveMessage(message);
    
    // Assert
    expect(/* ... */);
  });
});
```

## 🔧 Pull Request Process

### Before Submitting
1. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test**
   ```bash
   flutter test
   flutter analyze
   dart format .
   ```

3. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add your feature"
   ```

4. **Push to GitHub**
   ```bash
   git push origin feature/your-feature-name
   ```

### PR Requirements
- [ ] All tests pass
- [ ] Code is properly formatted
- [ ] No analyzer warnings
- [ ] Documentation updated if needed
- [ ] Screenshots for UI changes
- [ ] Linked to relevant issue

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Screenshots
(If applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests pass
- [ ] Documentation updated
```

## 🐛 Bug Reports

### Before Reporting
1. Search existing issues
2. Try latest version
3. Reproduce consistently
4. Gather logs and screenshots

### Bug Report Template
Use the GitHub issue template and include:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Device/OS information
- App version and build number
- Relevant logs

## 💡 Feature Requests

### Guidelines
- Align with P2P and AI focus
- Consider user experience impact
- Provide clear use cases
- Consider implementation complexity

### Feature Request Process
1. Create GitHub issue using template
2. Discuss with maintainers
3. Get approval before implementation
4. Follow development guidelines

## 🌍 Localization

### Adding New Language
1. **Add language to supported list**
   ```dart
   // lib/data/services/language_service.dart
   static const List<SupportedLanguage> supportedLanguages = [
     // ... existing languages
     SupportedLanguage(
       code: 'fr',
       name: 'French',
       nativeName: 'Français',
       flag: '🇫🇷',
       isRTL: false,
     ),
   ];
   ```

2. **Create ARB file**
   ```bash
   cp lib/l10n/app_en.arb lib/l10n/app_fr.arb
   ```

3. **Translate strings**
   ```json
   {
     "appTitle": "Chat P2P",
     "welcome": "Bienvenue"
   }
   ```

4. **Test RTL support** (if applicable)

### Translation Guidelines
- Keep strings concise
- Consider cultural context
- Test with different text lengths
- Use placeholders for dynamic content

## 🔒 Security

### Reporting Security Issues
- **DO NOT** create public issues for security vulnerabilities
- Email security concerns to: [security@example.com]
- Include detailed description and reproduction steps
- Allow time for fix before public disclosure

### Security Guidelines
- Never commit API keys or secrets
- Use secure coding practices
- Validate all user inputs
- Follow encryption best practices
- Regular dependency updates

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Code Review**: PR comments and suggestions

### Response Times
- Issues: 1-3 business days
- PRs: 2-5 business days
- Security issues: 24-48 hours

## 📜 License

By contributing to P2P Chat, you agree that your contributions will be licensed under the same license as the project.

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Special thanks in app about section

---

Thank you for contributing to P2P Chat! Your efforts help make secure, decentralized communication accessible to everyone. 🚀
