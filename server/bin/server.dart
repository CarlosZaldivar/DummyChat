import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_orm/dart_orm.dart' as orm;
import 'package:route/server.dart' show Router;

import 'models.dart' show
  Conversation,
  DatabaseConnectionManager,
  Message,
  User,
  UserConversation;

main() async {
  try {
    var databaseManager = new DatabaseConnectionManager('DummyChat', 'DummyChat', 'DummyChat');
    await databaseManager.openConnection();
  } catch (e) {
    print('Could not connect to database.');
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

class LoggedUser {
  WebSocket socket;
  User user;
}

List<LoggedUser> LoggedUsers = [];

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
  String username;
  String rawPassword;
  try {
    var body = await req.transform(UTF8.decoder).join();
    Map credentials = JSON.decode(body);
    username = credentials['username'];
    rawPassword = credentials['password'];
    if (!(username is String) || !(rawPassword is String)) {
      // Custom exception should be thrown here.
      throw new Exception();
    }
  } catch (e) {
    req.response.statusCode = HttpStatus.BAD_REQUEST;
    req.response.close();
    return;
  }

  var query = new orm.FindOne(User)
    ..where(new orm.Equals('username', username));

  var result = await query.execute();
  if (result != null) {
    req.response.statusCode = HttpStatus.CONFLICT;
    req.response.close();
    return;
  }

  var newUser = new User();
  newUser.username = username;
  newUser.password = hashPassword(rawPassword);
  await newUser.save();

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
  LoggedUser newClient = new LoggedUser();
  newClient.socket = socket;
  LoggedUsers.add(newClient);
}

String hashPassword(String rawPassword) {
  var bytes = rawPassword.codeUnits;
  var digest = sha256.convert(bytes);
  return digest.toString();
}



getUser(json) {

}

sendMessage(json) {

}