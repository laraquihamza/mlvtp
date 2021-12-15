import "package:http/http.dart" as http;
import "dart:convert";
class RequestAssistant {
  Future<Map <String, dynamic>> getRequest(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var res = jsonDecode(response.body);
      return res;
    }
    return {};
  }
}