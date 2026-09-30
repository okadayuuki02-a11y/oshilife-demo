import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

Future<String?> recognizeProfileImage(Uint8List bytes) async {
  final dynamic tesseract = js_util.getProperty(html.window, 'Tesseract');
  if (tesseract == null) return null;

  final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  final dynamic promise = js_util.callMethod(
    tesseract,
    'recognize',
    [dataUrl, 'jpn+eng'],
  );
  final dynamic result = await js_util.promiseToFuture(promise);
  if (result == null) return null;
  final dynamic data = js_util.getProperty(result, 'data');
  if (data == null) return null;
  final dynamic text = js_util.getProperty(data, 'text');
  return text?.toString();
}
