import 'dart:io';

export 'dart:io' show HttpStatus;

enum MyHttpStatus {
  ok(200, 'OK', 'The request has succeeded.'),
  badRequest(400, 'Bad Request',
      'The server could not understand the request due to invalid syntax.'),
  notFound(404, 'Not Found', 'The server can not find the requested resource.'),
  methodNotAllowed(405, 'Method Not Allowed',
      'The request method is known by the server but is not supported by the target resource.'),
  internalServerError(500, 'Internal Server Error',
      'The server has encountered a situation it doesn\'t know how to handle.');

  static MyHttpStatus? fromCode(int code) {
    for (var httpStatus in MyHttpStatus.values) {
      if (httpStatus.code == code) return httpStatus;
    }
    return null;
  }

  const MyHttpStatus(this.code, this.phrase, this.description);

  final int code;
  final String phrase;
  final String description;

  @override
  String toString() => '$code $phrase';
}

class ErrorPage {
  ErrorPage(this.request);

  HttpRequest request;

  void response(int code, [String? message]) {
    var httpStatus = MyHttpStatus.fromCode(code);
    if (httpStatus == null) {
      message = message == null
          ? 'HTTP status code: $code'
          : '<h1>$code</h1><p>$message</p>';
    } else {
      message ??= '<h1>$httpStatus</h1><p>${httpStatus.description}</p>';
    }

    request.response
      ..statusCode = code
      ..write(message);
  }
}
