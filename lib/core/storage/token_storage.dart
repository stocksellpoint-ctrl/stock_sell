/// Placeholder for token persistence.
///
/// When backend arrives, back this with flutter_secure_storage.
class TokenStorage {
  TokenStorage._internal();
  static final TokenStorage instance = TokenStorage._internal();

  String? _token;

  Future<String?> read() async => _token;
  Future<void> write(String token) async => _token = token;
  Future<void> clear() async => _token = null;
}