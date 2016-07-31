import 'package:dart_orm_adapter_mysql/dart_orm_adapter_mysql.dart';
import 'package:dart_orm/dart_orm.dart' as orm;

main() async {
  var connectionManager = new DatabaseConnectionManager('DummyChat', 'DummyChat', 'DummyChat');
  await connectionManager.openConnection();
  await orm.Migrator.migrate();
  connectionManager.closeConnection();
}

class DatabaseConnectionManager {
  MySQLDBAdapter adapter;
  String username;
  String password;
  String database;

  DatabaseConnectionManager(String username, String password, String database) {
    this.username = username;
    this.password = password;
    this.database = database;
  }

  openConnection() async {
    String connectionString =
        'mysql://$username:$password@localhost:3306/$database';

    adapter = new MySQLDBAdapter(connectionString);
    await adapter.connect();

    orm.addAdapter('mysql', adapter);
    orm.setDefaultAdapter('mysql');
    orm.AnnotationsParser.initialize();
  }

  closeConnection() {
    adapter.close();
  }
}

@orm.DBTable('users')
class User extends orm.Model {
  @orm.DBField()
  @orm.DBFieldPrimaryKey()
  int id;

  @orm.DBField()
  String username;

  @orm.DBField()
  String password;
}

@orm.DBTable('messages')
class Message extends orm.Model {
  @orm.DBField()
  @orm.DBFieldPrimaryKey()
  int id;

  @orm.DBField()
  int conversationId;

  @orm.DBField()
  int authorId;

  @orm.DBField()
  String content;
}

@orm.DBTable('conversations')
class Conversation extends orm.Model {
  @orm.DBField()
  @orm.DBFieldPrimaryKey()
  int id;
}

@orm.DBTable('users_conversations')
class UserConversation extends orm.Model {
  @orm.DBField()
  int conversationId;

  @orm.DBField()
  int userId;
}