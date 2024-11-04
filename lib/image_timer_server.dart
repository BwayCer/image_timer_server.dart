import 'dart:io';
import 'package:path/path.dart' as path;

import './refpoint.dart' show refpoint;
import './src/server_utils.dart' show ErrorPage;
import './src/controller_timer_page.dart' show timerPage;

void main() {
  runHttpServer();
}

void runHttpServer({
  int port = 8080,
  InternetAddress? ip,
}) async {
  // 使用本地 IP (127.0.0.1)
  ip = ip ?? InternetAddress.loopbackIPv4;

  var server = await HttpServer.bind(ip, port);
  print('Listening on http://${ip.address}:$port');

  await for (HttpRequest request in server) {
    var errorPage = ErrorPage(request);

    try {
      if (request.method != 'GET') {
        errorPage.response(405);
      } else {
        // 取得路徑
        var urlPathname = request.uri.path;
        // 取得查詢參數
        var queryParams = request.uri.queryParameters;

        if (urlPathname == '/') {
          await editPage(request, errorPage);
        } else if (urlPathname == '/timer') {
          await timerPage(request, errorPage, queryParams);
        } else {
          errorPage.response(HttpStatus.notFound);
        }
      }
    } catch (err) {
      errorPage.response(500);
    }

    // 關閉回應
    await request.response.close();
  }
}

Future<void> editPage(
  HttpRequest request,
  ErrorPage errorPage,
) async {
  final htmlFile = File(path.join(refpoint, 'assets/editPage.html'));
  if (!(await htmlFile.exists())) {
    errorPage.response(HttpStatus.notFound, 'File not found.');
  } else {
    request.response.headers.contentType = ContentType.html;
    await htmlFile.openRead().pipe(request.response);
  }
}
