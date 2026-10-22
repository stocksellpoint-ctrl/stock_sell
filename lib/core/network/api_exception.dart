class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final List<String>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == null;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isAuthError {
    const authCodes = {
      'MISSING_TOKEN',
      'INVALID_TOKEN',
      'TOKEN_EXPIRED',
      'TOKEN_NOT_ACTIVE',
      'USER_NOT_FOUND',
      'USER_INACTIVE',
      'UNAUTHORIZED',
    };
    return authCodes.contains(code) || statusCode == 401;
  }

  // ── Friendly user-facing message ────────────────────────
  String get friendlyMessage {
    switch (code) {
      // ── Auth / session ──────────────────────────────────
      case 'MISSING_TOKEN':
      case 'INVALID_TOKEN':
        return 'Your session is invalid. Please log in again.';
      case 'TOKEN_EXPIRED':
        return 'Your session has expired. Please log in again.';
      case 'TOKEN_NOT_ACTIVE':
        return 'Session not yet active. Try again in a moment.';
      case 'USER_NOT_FOUND':
        return 'Your account no longer exists.';
      case 'USER_INACTIVE':
        return 'Your account has been deactivated. Contact support.';
      case 'ADMIN_REQUIRED':
        return 'You do not have permission to do this.';
      case 'NOT_AUTHENTICATED':
        return 'Please log in to continue.';

      // ── Login / register ────────────────────────────────
      case 'INVALID_CREDENTIALS':   // ← must match exactly, character for character
        return 'Invalid email or password.';
      case 'INVALID_PASSWORD':
        return 'Incorrect password. Please try again.';
      case 'EMAIL_ALREADY_REGISTERED':
        return 'This email is already registered. Try logging in instead.';
      case 'USER_EXISTS':
        return 'An account with this email already exists.';

      // ── Validation ──────────────────────────────────────
      case 'VALIDATION_ERROR':
        return errors?.isNotEmpty == true
            ? errors!.join('\n')
            : 'Please check your input.';
      case 'DUPLICATE_VALUE':
        return 'This value is already in use. Try a different one.';

      // ── Not found ───────────────────────────────────────
      case 'ROUTE_NOT_FOUND':
        return 'The requested resource was not found.';
      case 'RECORD_NOT_FOUND':
        return 'The item you are looking for does not exist.';

      // ── Limits & server ─────────────────────────────────
      case 'RATE_LIMITED':
        return 'Too many requests. Please try again later.';
      case 'INTERNAL_SERVER_ERROR':
        return 'Something went wrong on our end. Please try again.';
      case 'SERVICE_UNAVAILABLE':
        return 'Service is temporarily unavailable. Please try again later.';

      // ── Network (set by ApiClient) ──────────────────────
      case 'TIMEOUT':
        return 'Connection timed out. Check your internet.';
      case 'CONNECTION_ERROR':
        return 'Cannot reach the server. Is the backend running?';
      case 'CANCELLED':
        return 'Request was cancelled.';
      case 'UNKNOWN':
        return 'Something went wrong. Please try again.';


      case 'CATEGORY_EXISTS':
        return 'A category with this name already exists.';
      // ── Fallback ────────────────────────────────────────
      default:
        // If the backend sent a message, use it.
        if (message.isNotEmpty && message != 'null') return message;

        // Otherwise fall back on status code.
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please check your input.';
          case 401:
            return 'Please log in to continue.';
          case 403:
            return 'You do not have permission to do this.';
          case 404:
            return 'The requested item was not found.';
          case 409:
            return 'There is a conflict with this request.';
          case 422:
            return 'The data you submitted is invalid.';
          case 429:
            return 'Too many requests. Please try again later.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
          case 503:
            return 'Service temporarily unavailable. Please try again.';
          default:
            return 'Something went wrong. Please try again.';
        }
    }
  }

  @override
  String toString() => friendlyMessage;
  // String toString() {
  //   if (errors != null && errors!.isNotEmpty) {
  //     return '$message: ${errors!.join(", ")}';
  //   }
  //   return message;
  // }
}
