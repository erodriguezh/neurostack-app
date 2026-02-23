/// Converts snake_case to PascalCase for test naming.
///
/// Example: `pascalCase('user_name')` returns `'UserName'`.
String pascalCase(String snakeCase) {
  return snakeCase
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
