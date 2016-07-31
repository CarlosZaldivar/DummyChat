import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
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
    .listen(logIn);

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

Future<User> authenticate(HttpRequest req) async {
  var completer = new Completer();
  var authHeader;
  try {
    authHeader = req.headers['authorization'][0];
  } on NoSuchMethodError catch (e) {
    return null;
  }
  var splitAuth = authHeader.split(' ');

  if (splitAuth.length != 2) {
    return null;
  }

  String method = splitAuth[0];

  if (method != 'Basic') {
    return null;
  }

  String value = splitAuth[1];
  String credentials;
  try {
    credentials = UTF8.decode(BASE64.decode(value));
  } on FormatException catch (e) {
    return null;
  }
  var splitCredentials = credentials.split(':');
  if (splitCredentials.length != 2) {
    return null;
  }
  String username = splitCredentials[0];
  String password = splitCredentials[1];

  var query = new orm.FindOne(User)
    ..where(new orm.Equals('username', username));
  query.execute().then((User result) {
    if (result.password == hashPassword(password)) {
      completer.complete(result);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}

register(HttpRequest req) async {
  String username;
  String rawPassword;
  try {
    var body = await req.transform(UTF8.decoder).join();
    Map credentials = JSON.decode(body);
    username = credentials['username'];
    rawPassword = credentials['password'];
    RegExp usernameRegex = new RegExp(r'^[a-zA-Z0-9_-]*$');
    if (!(username is String) || !(rawPassword is String) ||
        !usernameRegex.hasMatch(username)) {
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

logIn(HttpRequest req) async {
  var user = await authenticate(req);
  if (user == null) {
    req.response.statusCode = HttpStatus.UNAUTHORIZED;
    req.response.close();
    return;
  } else {
    var socket = await WebSocketTransformer.upgrade(req);
    socket
      .map((string) => JSON.decode(string))
      .listen((json) => handleMessage(socket, json), onError: handleError);

    LoggedUser newClient = new LoggedUser();
    newClient.socket = socket;
    newClient.user = user;
    LoggedUsers.add(newClient);
  }
}

handleError(error) {
  print(error);
}



handleMessage(WebSocket socket, Map json) {
  String requestType = json['requestType'];
  switch (requestType) {
    case 'getUser':
      getUser(socket, json);
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
}

String hashPassword(String rawPassword) {
  var bytes = rawPassword.codeUnits;
  var digest = sha256.convert(bytes);
  return digest.toString();
}



getUser(WebSocket socket, Map json) async {
  var username = json['username'];
  if (username == null) {
    socket.add(null);
    return;
  }

  var query = new orm.FindOne(User)
    ..where(new orm.Equals('username', username));

  User result = await query.execute();
  if (result == null) {
    socket.add(null);
    return;
  }

  var user = {'username': result.username, 'id': result.id};
  socket.add(JSON.encode(user));
}

sendMessage(json) {

}