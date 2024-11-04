import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

String _customBaseEncode(String alphabet, int number) {
  final base = alphabet.length;

  // AI: 每次操作 `String` 都會創建新的字符串, 所以使用 `StringBuffer` 更佳。
  StringBuffer result = StringBuffer();
  while (number > 0) {
    int remainder = number % base;
    result.write(alphabet[remainder]);
    number ~/= base;
  }

  // 反轉字串
  return result.toString().split('').reversed.join('').padLeft(4, '0');
}

class ImageTimerArgu {
  ImageTimerArgu({
    required DateTime time,
    String? bgColor,
    String? timeColor,
    String? textColor,
    int? scale,
    int? duration,
    String? fontBasePath,
    String? outputBasePath,
  }) {
    remainingTime = countRemainingTime(time);
    var remainingSec = remainingTime.inSeconds;

    if (bgColor != null && _isValidHexColor(bgColor)) {
      this.bgColor = '0x${bgColor.toLowerCase()}';
    }
    if (timeColor != null && _isValidHexColor(timeColor)) {
      this.timeColor = '0x${timeColor.toLowerCase()}';
    }
    if (textColor != null && _isValidHexColor(textColor)) {
      this.textColor = '0x${textColor.toLowerCase()}';
    }
    // if 26, width is 1254px.
    if (scale != null && 0 < scale && scale <= 26) {
      this.scale = scale;
    }

    if (remainingSec == 0) {
      this.duration = 1;
    } else if (duration != null && 0 < duration && duration <= 60) {
      this.duration = duration;
    }

    if (fontBasePath != null) {
      textFontPath = path.join(fontBasePath, textFontPath);
      timeFontPath = path.join(fontBasePath, timeFontPath);
    }

    id = _nameId();
    var filename = '${id}.gif';
    outputPath =
        outputBasePath == null ? filename : path.join(outputBasePath, filename);
  }

  late Duration remainingTime;
  String bgColor = '0x141414';
  String timeColor = '0x00ff00';
  String textColor = '0xffffff';
  int scale = 6;
  int duration = 10;
  String textFontPath = './Kavivanar-Regular.ttf';
  String timeFontPath = './MonomaniacOne-Regular.ttf';
  String id = '';
  String outputPath = '';

  Duration countRemainingTime(DateTime specifiedTime) {
    DateTime currentTime = DateTime.now();
    var remainingTime = specifiedTime.difference(currentTime);

    // 大於 60 秒的每 10 秒一個單位以節約消耗.
    var remainingSec = remainingTime.inSeconds;
    var duration = remainingSec < 0
        ? Duration(seconds: 0)
        : remainingSec <= 60
            ? remainingTime
            : Duration(seconds: (remainingSec ~/ 10) * 10);

    return duration;
  }

  bool _isValidHexColor(String color) {
    return _hexColorRegex.hasMatch(color);
  }

  String _nameId() {
    var id = '';
    var remainingSec = remainingTime.inSeconds;
    id += remainingSec < 60 ? '05' : '60';
    id += _customBaseEncode(_customAlphabet, remainingSec);
    id += md5
        .convert(utf8.encode('$bgColor-$timeColor-$textColor-$scale-$duration'))
        .toString()
        .substring(0, 7);
    return id;
  }
}

// 在這裡忽略 "#".
final _hexColorRegex = RegExp(r'^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');

// 排除 I, l, O.
const _customAlphabet =
    '0123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

// ffmpeg 的色碼可以接受大小寫, 透明度及名稱, 如: '0xffffff', '0xFFFFFF', '0xFFFFFF88', 'white'.
List<String> createFFmpegOptList(ImageTimerArgu argu) {
  var ImageTimerArgu(
    remainingTime: remainingTime,
    bgColor: bgColor,
    timeColor: timeColor,
    textColor: textColor,
    duration: duration,
    textFontPath: textFont,
    timeFontPath: timeFont,
    outputPath: outputPath,
  ) = argu;
  var scale = argu.scale + 4;

  int textSize = (1.8 * scale).toInt();
  int textDaX = (2.4 * scale).toInt();
  int textHoX = (12.6 * scale).toInt();
  int textMiX = (22.4 * scale).toInt();
  int textSeX = (32.8 * scale).toInt();
  int textY = (6.6 * scale).toInt();
  int imgSizeX = (41.8 * scale).toInt();
  int imgSizeY = (9 * scale).toInt();
  int timeSize = (5.4 * scale).toInt();
  int timeX = (1 * scale).toInt();
  int timeY = (1 * scale).toInt();

  var textSamePart = 'fontcolor=$textColor:fontsize=$textSize:y=$textY';
  var vfTxt = "drawtext=fontfile=$textFont:text='DAYS':$textSamePart:x=$textDaX"
      ",drawtext=fontfile=$textFont:text='HOURS':$textSamePart:x=$textHoX"
      ",drawtext=fontfile=$textFont:text='MINUTES':$textSamePart:x=$textMiX"
      ",drawtext=fontfile=$textFont:text='SECONDS':$textSamePart:x=$textSeX";

  // 計時鐘的"天"不支援三位數所以不能超過100天
  if (remainingTime.inSeconds >= 8640000) {
    var timerText = '9 9   9 9   9 9   9 9';
    vfTxt += ",drawtext=fontfile=$timeFont:text='$timerText'"
        ":fontcolor=$timeColor:fontsize=$timeSize:x=$timeX:y=$timeY";
  } else {
    for (int idx = 0; idx < duration; idx++) {
      var theRemainingTime = remainingTime - Duration(seconds: idx);
      if (theRemainingTime.inSeconds == 0) {
        var timerText = '0 0   0 0   0 0   0 0';
        var flashInterval = 0.8;

        for (int ida = 0; ida < 10; ida++) {
          // TODO: 如何每幀間隔0.8秒
          // var startFrame = (idx + (flashInterval * ida)) * 10 ~/ 1 * 10;
          var startFrame = idx + ida;
          vfTxt += ",drawtext=fontfile=$timeFont:text='$timerText'"
              ":fontcolor=$timeColor:fontsize=$timeSize:x=$timeX:y=$timeY"
              ":enable='between(t,$startFrame,${startFrame + flashInterval})'";
        }

        // duration = idx + (flashInterval * 10).toInt();
        duration = idx + 10;
        break;
      } else {
        // 計算天、時、分、秒
        var timerText = [
          theRemainingTime.inDays,
          theRemainingTime.inHours % 24,
          theRemainingTime.inMinutes % 60,
          theRemainingTime.inSeconds % 60,
        ].map((val) {
          var txt = val.toString().padLeft(2, '0');
          return '${txt[0]} ${txt[1]}';
        }).join('   ');

        vfTxt += ",drawtext=fontfile=$timeFont:text='$timerText'"
            ":fontcolor=$timeColor:fontsize=$timeSize:x=$timeX:y=$timeY"
            ":enable='between(t,$idx,${idx + 1})'";
      }
    }
  }

  return [
    '-f',
    'lavfi',
    '-i',
    'color=c=$bgColor:s=${imgSizeX}x$imgSizeY:d=$duration',
    '-vf',
    vfTxt,
  ];
}

// 問題:
//   使用 pipe 有錯誤也難以察覺.
//   在 shell 下假設 `ffmpeg -` 退出不為 0, 但 `ffmpeg - | cat` 卻為 0.
//   dart 的 try catch 或 pipe.catchError() 也都抓不到錯誤.
// @example
// ```
// await for (HttpRequest request in server) {
//   await (await startFFmpeg(imageTimerArgu)).stdout.pipe(request.response);
// }
// ```
Future<Process> startFFmpeg(ImageTimerArgu argu) {
  final optList = createFFmpegOptList(argu);
  final argList = optList + ['-f', 'gif', '-'];
  return Process.start('ffmpeg', argList);
}
