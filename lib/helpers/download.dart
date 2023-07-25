import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> downloadVideo(String formatUrl, String savePath) async {
  var response = await http.get(Uri.parse(formatUrl));
  var file = File(savePath);
  await file.writeAsBytes(response.bodyBytes);
}
