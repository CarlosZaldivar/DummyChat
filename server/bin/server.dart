import 'dart:io';
import 'dart:convert';
import 'package:route/server.dart' show Router;

import 'models.dart' as models;

main() async {
  try {
//    await models.initializeDBConnection();
  } catch (e) {
    print(e);
  }

  try {
    var server = await HttpServer.bind('127.0.0.1', 4040);
    var router = new Router(server);

    router.serve('/ws')
    .transform(new WebSocketTransformer())
    .listen(handleMessage);

    router.serve('/register')
    .listen(register);
  } catch (e) {
    print(e);
  }
}

class LoggedClient {
  WebSocket socket;
  String username;
}

List<LoggedClient> loggedClients = [];

bool authenticate(String auth) {
  String name = auth.split(' ')[0];
  String value = auth.substring(name.length + 1);
  if (name == 'Basic') {
    String credentials = UTF8.decode(BASE64.decode(value));
    String username = credentials.split(':')[0];
    String password = credentials.substring(username.length + 1);
    return true;
  }
  return false;
}

register(HttpRequest req) async {
  try {
    var body = await req.transform(UTF8.decoder).join();
    Map credentials = JSON.decode(body);
    String username = credentials['username'];
    String rawPassword = credentials['password'];
    assert(username != null && rawPassword != null);
    print(username);
    print(rawPassword);
  } catch (e) {
    req.response.statusCode = HttpStatus.BAD_REQUEST;
    req.response.close();
    return;
  }



  req.response.statusCode = HttpStatus.OK;
  req.response.close();
}

handleMessage(WebSocket socket) {
  socket
    .map((string) => JSON.decode(string))
    .listen((json) {
      String requestType = json['requestType'];
      switch (requestType) {
        case 'getUser':
          getUser(json);
          print('getUser');
          break;
        case 'sendMessage':
          print('sendMessage');
          sendMessage(json);
          break;
        case 'changePassword':
          print('changePassword');
          break;
        default:
          print('default');
          break;
      }
    }, onError: (error) {
      print('error');
    });
  LoggedClient newClient = new LoggedClient();
  newClient.socket = socket;
  loggedClients.add(newClient);
}



getUser(json) {

}

sendMessage(json) {

}