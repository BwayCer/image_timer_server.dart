import 'dart:io';
import 'package:path/path.dart' as path;

import '../refpoint.dart' show refpoint;
import './server_utils.dart' show ErrorPage;
import './ffmpeg_option.dart' show ImageTimerArgu, startFFmpeg;

final fontBasePath = path.join(refpoint, 'assets/font');

Future<void> timerPage(
  HttpRequest request,
  ErrorPage errorPage,
  Map<String, String> queryParams,
) async {
  final (errCode, errMsg01, imageTimerArgu) = parseQueryParams(queryParams);
  if (imageTimerArgu == null) {
    errorPage.response(errCode!, errMsg01);
    return;
  }

  request.response.headers.contentType = ContentType('image', 'gif');
  await (await startFFmpeg(imageTimerArgu)).stdout.pipe(request.response);
}

(int? errCode, String? errMsg, ImageTimerArgu?) parseQueryParams(
  Map<String, String> queryParams,
) {
  final tailErrMsg = 'of querysearch is incorrect format.';

  final timestampSec =
      int.tryParse(queryParams['T'] ?? queryParams['time'] ?? '');
  if (timestampSec == null || timestampSec < 0) {
    return (HttpStatus.badRequest, '"time" $tailErrMsg', null);
  }

  String? bgColor;
  String? timeColor;
  String? textColor;
  int? scale;
  int? duration;

  bgColor = queryParams['B'] ?? queryParams['bgColor'];
  timeColor = queryParams['I'] ?? queryParams['timeColor'];
  textColor = queryParams['E'] ?? queryParams['textColor'];
  scale = int.tryParse(queryParams['C'] ?? queryParams['scale'] ?? '');
  duration = int.tryParse(queryParams['D'] ?? queryParams['duration'] ?? '');

  DateTime time = DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);

  return (
    null,
    null,
    ImageTimerArgu(
      time: time,
      bgColor: bgColor,
      timeColor: timeColor,
      textColor: textColor,
      scale: scale,
      duration: duration,
      fontBasePath: fontBasePath,
    ),
  );
}
