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
    var server = await HttpServer.bind('0.0.0.0', 4040);
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

Map<String, LoggedUser> loggedUsers = {};

Future<User> authenticate(HttpRequest req) async {
  var completer = new Completer();
  var authHeader;
  try {
    authHeader = req.headers['Authorization'][0];
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
  query.execute()
    .then((User result) {
      if (result == null || result.password != hashPassword(password)) {
        completer.complete(null);
      } else {
        completer.complete(result);
      }
    })
    .catchError((e) {
      completer.complete(null);
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
      .listen((json) => handleMessage(user.id, json),
               onDone: () => disconnect(user),
               onError: handleError);

    LoggedUser newClient = new LoggedUser();
    newClient.socket = socket;
    newClient.user = user;
    loggedUsers[user.id] = newClient;
  }
}

disconnect(User user) {
  LoggedUser loggedUser = loggedUsers[user.id];
  if (loggedUser != null) {
    loggedUsers[user.id].socket.close();
    loggedUsers.remove(user.id);
  }
}

handleError(error) {
  print(error);
}



handleMessage(int senderId, Map json) {
  String requestType = json['requestType'];
  switch (requestType) {
    case 'getUser':
      getUser(senderId, json);
      break;
    case 'getConversations':
      getConversations(senderId, json);
      break;
    case 'startConversation':
      startConversation(senderId, json);
      break;
    case 'sendMessage':
      sendMessage(senderId, json);
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



getUser(int senderId, Map json) async {
  LoggedUser sender = loggedUsers[senderId];
  if (sender == null) {
    return;
  }
  Map response = {'messageType': 'getUserResponse'};
  var username = json['username'];
  if (username == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  var query = new orm.FindOne(User)
    ..where(new orm.Equals('username', username));

  User result = await query.execute();
  if (result == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  response['status'] = 'ok';
  response['user'] = {'username': result.username, 'id': result.id};
  sender.socket.add(JSON.encode(response));
}

getConversations(int senderId, Map json) async {
  LoggedUser sender = loggedUsers[senderId];
  if (sender == null) {
    return;
  }

  // Get sender's conversations.
  var query = new orm.Find(UserConversation)
    ..where(new orm.Equals('userId', sender.user.id));
  List<UserConversation> userConversations = await query.execute();

  Map response = {'messageType': 'getConversationsResponse'};
  response['conversations'] = [];
  for (var userConversation in userConversations) {
    var conversation = {'id': userConversation.conversationId};
    var query = new orm.Find(Message)
      ..where(new orm.Equals('conversationId', conversation['id']));
    List<Message> messages = await query.execute();
    conversation['messages'] = messages.map((message) =>
    {
      'id': message.id,
      'conversationId': message.conversationId,
      'authorId': message.authorId,
      'content': message.content
    }).toList();

    // Find other participant.
    query = new orm.FindOne(UserConversation)
      ..where(new orm.Equals('conversationId', conversation['id'])
              .and(new orm.NotEquals('userId', sender.user.id)));
    var recipientConversation = await query.execute();
    query = new orm.FindOne(User)
      ..where(new orm.Equals('id', recipientConversation.userId));
    var recipient = await query.execute();
    conversation['recipient'] = {'id': recipient.id, 'username': recipient.username};
    response['conversations'].add(conversation);
  }
  response['status'] = 'ok';
  sender.socket.add(JSON.encode(response));
}

startConversation(int senderId, Map json) async {
  LoggedUser sender = loggedUsers[senderId];
  if (sender == null) {
    return;
  }
  Map response = {'messageType': 'startConversationResponse'};
  var recipientUsername = json['recipient'];
  // Starting conversation without sending first message is not allowed.
  var message = json['message'];
  if (recipientUsername == null || message == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  // Check if recipient exist.
  var query = new orm.FindOne(User)
    ..where(new orm.Equals('username', recipientUsername));
  var recipient = await query.execute();
  if (recipient == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  // Checking if conversation exist should be added.

  Conversation newConversation = new Conversation();
  await newConversation.save();

  UserConversation senderConv = new UserConversation();
  senderConv.userId = sender.user.id;
  senderConv.conversationId = newConversation.id;
  await senderConv.save();

  UserConversation recipientConv = new UserConversation();
  recipientConv.userId = recipient.id;
  recipientConv.conversationId = newConversation.id;
  await recipientConv.save();

  Message newMessage = new Message();
  newMessage.authorId = sender.user.id;
  newMessage.conversationId = newConversation.id;
  newMessage.content = message;
  await newMessage.save();
  
  var conversation = {
    'id': newConversation.id,
    'messages': [{
      'id': newMessage.id,
      'authorId': newMessage.authorId,
      'content': newMessage.content
    }],
    'participants': [sender.user.id, recipient.id]
  };
  
  if (loggedUsers[recipient.id] != null) {
    var newMessage = {'messageType': 'newConversation', 'conversation': conversation};
    loggedUsers[recipient.id].socket.add(JSON.encode(newMessage));
  }
  
  response['status'] = 'ok';
  response['conversation'] = conversation;
  sender.socket.add(JSON.encode(response));
}

sendMessage(int senderId, Map json) async {
  LoggedUser sender = loggedUsers[senderId];
  if (sender == null) {
    return;
  }

  Map response = {'messageType': 'sendMessageResponse'};

  var message = json['message'];
  if (message == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  if (sender.user.id != message['authorId'] || message['content'] == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  var conversationId = message['conversationId'];
  var query = new orm.FindOne(Conversation)
    ..where(new orm.Equals('id', conversationId));
  var conversation = await query.execute();
  if (conversation == null) {
    response['status'] = 'error';
    sender.socket.add(JSON.encode(response));
    return;
  }

  // Create and save message.
  var newMessage = new Message();
  newMessage.authorId = sender.user.id;
  newMessage.conversationId = conversationId;
  newMessage.content = message['content'];
  newMessage.save();

  // Find other participant.
  query = new orm.FindOne(UserConversation)
    ..where(new orm.Equals('conversationId', conversation.id)
        .and(new orm.NotEquals('userId', sender.user.id)));
  var recipientConversation = await query.execute();

  query = new orm.FindOne(User)
    ..where(new orm.Equals('id', recipientConversation.userId));
  var recipient = await query.execute();

  if (loggedUsers[recipient.id] != null) {
    var newMessage = {'messageType': 'newMessage', 'message': message};
    loggedUsers[recipient.id].socket.add(JSON.encode(newMessage));
  }
  response['status'] = 'ok';
  sender.socket.add(JSON.encode(response));
}
