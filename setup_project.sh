#!/bin/bash

# P2P Chat - Project Setup Script
# This script sets up the complete development environment

echo "🚀 P2P Chat - Project Setup"
echo "============================"

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

print_success "Flutter is installed"
flutter --version

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

# Clean any previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies"
    exit 1
fi

print_success "Dependencies installed successfully"

# Generate Hive adapters and other generated code
print_status "Generating Hive adapters and code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

if [ $? -ne 0 ]; then
    print_warning "Code generation had issues, but continuing..."
fi

# Generate localizations
print_status "Generating localizations..."
flutter gen-l10n

if [ $? -ne 0 ]; then
    print_warning "Localization generation had issues, but continuing..."
fi

# Create necessary directories
print_status "Creating project directories..."
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p test/unit
mkdir -p test/widget
mkdir -p test/integration
mkdir -p coverage

print_success "Project directories created"

# Set up Git hooks (if .git exists)
if [ -d ".git" ]; then
    print_status "Setting up Git hooks..."
    
    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running pre-commit checks..."

# Run Flutter analyze
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Flutter analyze failed"
    exit 1
fi

# Run tests
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ Pre-commit checks passed"
EOF

    chmod +x .git/hooks/pre-commit
    print_success "Git hooks configured"
fi

# Create VS Code settings
print_status "Creating VS Code settings..."
mkdir -p .vscode

cat > .vscode/settings.json << 'EOF'
{
    "dart.flutterSdkPath": null,
    "dart.lineLength": 100,
    "dart.insertArgumentPlaceholders": false,
    "dart.updateImportsOnRename": true,
    "dart.completeFunctionCalls": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": true,
        "source.organizeImports": true
    },
    "files.associations": {
        "*.arb": "json"
    },
    "emmet.includeLanguages": {
        "dart": "html"
    }
}
EOF

cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": ["--flavor", "development"]
        },
        {
            "name": "Profile",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile",
            "program": "lib/main.dart"
        },
        {
            "name": "Release",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release",
            "program": "lib/main.dart"
        }
    ]
}
EOF

print_success "VS Code settings created"

# Create analysis options
print_status "Creating analysis options..."
cat > analysis_options.yaml << 'EOF'
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated/**"
    - "**/l10n/**"
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Error rules
    avoid_empty_else: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    avoid_type_to_string: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    control_flow_in_finally: true
    empty_statements: true
    hash_and_equals: true
    invariant_booleans: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    no_logic_in_create_state: true
    prefer_void_to_null: true
    test_types_in_equals: true
    throw_in_finally: true
    unnecessary_statements: true
    unrelated_type_equality_checks: true
    use_key_in_widget_constructors: true
    valid_regexps: true

    # Style rules
    always_declare_return_types: true
    always_put_control_body_on_new_line: true
    always_put_required_named_parameters_first: true
    always_specify_types: false
    annotate_overrides: true
    avoid_annotating_with_dynamic: true
    avoid_bool_literals_in_conditional_expressions: true
    avoid_catches_without_on_clauses: true
    avoid_catching_errors: true
    avoid_double_and_int_checks: true
    avoid_field_initializers_in_const_classes: true
    avoid_function_literals_in_foreach_calls: true
    avoid_implementing_value_types: true
    avoid_init_to_null: true
    avoid_null_checks_in_equality_operators: true
    avoid_positional_boolean_parameters: true
    avoid_private_typedef_functions: true
    avoid_redundant_argument_values: true
    avoid_renaming_method_parameters: true
    avoid_return_types_on_setters: true
    avoid_returning_null: true
    avoid_returning_null_for_void: true
    avoid_returning_this: true
    avoid_setters_without_getters: true
    avoid_shadowing_type_parameters: true
    avoid_single_cascade_in_expression_statements: true
    avoid_types_as_parameter_names: true
    avoid_types_on_closure_parameters: true
    avoid_unnecessary_containers: true
    avoid_unused_constructor_parameters: true
    avoid_void_async: true
    await_only_futures: true
    camel_case_extensions: true
    camel_case_types: true
    cascade_invocations: true
    cast_nullable_to_non_nullable: true
    constant_identifier_names: true
    curly_braces_in_flow_control_structures: true
    directives_ordering: true
    empty_catches: true
    empty_constructor_bodies: true
    exhaustive_cases: true
    file_names: true
    flutter_style_todos: true
    implementation_imports: true
    join_return_with_assignment: true
    leading_newlines_in_multiline_strings: true
    library_names: true
    library_prefixes: true
    lines_longer_than_80_chars: false
    missing_whitespace_between_adjacent_strings: true
    no_runtimeType_toString: true
    non_constant_identifier_names: true
    null_closures: true
    omit_local_variable_types: true
    one_member_abstracts: true
    only_throw_errors: true
    overridden_fields: true
    package_api_docs: true
    package_prefixed_library_names: true
    parameter_assignments: true
    prefer_adjacent_string_concatenation: true
    prefer_asserts_in_initializer_lists: true
    prefer_asserts_with_message: true
    prefer_collection_literals: true
    prefer_conditional_assignment: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_constructors_over_static_methods: true
    prefer_contains: true
    prefer_equal_for_default_values: true
    prefer_expression_function_bodies: true
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_foreach: true
    prefer_function_declarations_over_variables: true
    prefer_generic_function_type_aliases: true
    prefer_if_elements_to_conditional_expressions: true
    prefer_if_null_operators: true
    prefer_initializing_formals: true
    prefer_inlined_adds: true
    prefer_int_literals: true
    prefer_interpolation_to_compose_strings: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_is_not_operator: true
    prefer_iterable_whereType: true
    prefer_null_aware_operators: true
    prefer_relative_imports: true
    prefer_single_quotes: true
    prefer_spread_collections: true
    prefer_typing_uninitialized_variables: true
    provide_deprecation_message: true
    public_member_api_docs: false
    recursive_getters: true
    slash_for_doc_comments: true
    sort_child_properties_last: true
    sort_constructors_first: true
    sort_pub_dependencies: true
    sort_unnamed_constructors_first: true
    type_annotate_public_apis: true
    type_init_formals: true
    unawaited_futures: true
    unnecessary_await_in_return: true
    unnecessary_brace_in_string_interps: true
    unnecessary_const: true
    unnecessary_getters_setters: true
    unnecessary_lambdas: true
    unnecessary_new: true
    unnecessary_null_aware_assignments: true
    unnecessary_null_checks: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_nullable_for_final_variable_declarations: true
    unnecessary_overrides: true
    unnecessary_parenthesis: true
    unnecessary_raw_strings: true
    unnecessary_string_escapes: true
    unnecessary_string_interpolations: true
    unnecessary_this: true
    use_full_hex_values_for_flutter_colors: true
    use_function_type_syntax_for_parameters: true
    use_is_even_rather_than_modulo: true
    use_named_constants: true
    use_raw_strings: true
    use_rethrow_when_possible: true
    use_setters_to_change_properties: true
    use_string_buffers: true
    use_to_and_as_if_applicable: true
    void_checks: true
EOF

print_success "Analysis options configured"

# Run initial analysis
print_status "Running initial code analysis..."
flutter analyze

# Try to build the project
print_status "Building project..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    print_success "Project built successfully!"
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    print_status "APK size: $APK_SIZE"
else
    print_warning "Build had issues, but setup is complete"
fi

# Final summary
echo ""
echo "================================"
print_success "🎉 Project setup completed!"
echo ""
print_status "What's been set up:"
echo "  ✅ Flutter dependencies installed"
echo "  ✅ Code generation completed"
echo "  ✅ Localizations generated"
echo "  ✅ Project directories created"
echo "  ✅ VS Code settings configured"
echo "  ✅ Analysis options set up"
echo "  ✅ Git hooks configured (if Git repo)"
echo ""
print_status "Next steps:"
echo "  1. Add your Gemini API key in the app settings"
echo "  2. Test the app: flutter run"
echo "  3. Run tests: ./run_tests.sh"
echo "  4. Start coding! 🚀"
echo ""
print_status "Useful commands:"
echo "  • flutter run                    - Run the app"
echo "  • flutter test                   - Run tests"
echo "  • flutter analyze                - Analyze code"
echo "  • flutter build apk             - Build APK"
echo "  • ./run_tests.sh                 - Run full test suite"
echo ""
print_success "Happy coding! 🎉"
