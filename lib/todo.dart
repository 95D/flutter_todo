
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as dev;

final String _storageName = 'storage.db';
final String _tableTodo = 'todo';
final String _colmTodoId = '_id';
final String _colmTodoTitle = '_title';
final String _colmTodoOrder = '_order';
final String _colmTodoDeadline = '_deadline';
final String _colmTodoDone = '_done';

final String _tableCntt = 'contents';
final String _colmCnttId = '_id';
final String _colmCnttPid = '_pid';
final String _colmCnttComments = '_comments';
final String _colmCnttDone = '_done';


class Todo {

  Todo();

  int id = null;
  String title = '';
  int order = 3;
  List<Contents> contentsList = <Contents>[];
  bool hasDeadLine = false;
  DateTime deadline = DateTime.now();
  bool done = false;

  String getDeadLine()
  {
    return hasDeadLine ?
        deadline.year.toString()+'-'+deadline.month.toString()+'-'+deadline.day.toString()+'_'+
            deadline.hour.toString()+':'+deadline.minute.toString()
        : 'no deadline';
  }
  
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      _colmTodoId : id,
      _colmTodoTitle: title,
      _colmTodoOrder: order,
      _colmTodoDeadline: hasDeadLine ? deadline.toIso8601String() : '',
      _colmTodoDone: done ? 1 : 0
    };
    dev.log(deadline.toIso8601String());
    return map;
  }

  Todo.fromMap(Map<String, dynamic> map)
  {
    id = map[_colmTodoId];
    title = map[_colmTodoTitle];
    order = map[_colmTodoOrder];
    final String dstr = map[_colmTodoDeadline];
    if(dstr.length == 0) {
      hasDeadLine = false;
      deadline = DateTime.now();
    }
    else {
      hasDeadLine = true;
      deadline = DateTime.parse(map[_colmTodoDeadline]);
    }
    done = map[_colmTodoDone] == 1;
  }
}

class Contents {
  Contents(String comments)
  {
    this.comments = comments;
  }

  Contents.import(String comments, bool done)
  {
    this.comments = comments;
    this.done = done;
  }

  int id = null;
  bool done = false;
  String comments = '';

  Map<String, dynamic> toMap(int pid) {
    var map = <String, dynamic>{
      _colmCnttId : id,
      _colmCnttPid: pid,
      _colmCnttComments: comments,
      _colmCnttDone: done ? 1 : 0
    };
    return map;
  }

  Contents.fromMap(Map<String, dynamic> map)
  {
    id = map[_colmCnttId];
    comments = map[_colmCnttComments];
    done = map[_colmCnttDone] == 1;
  }
}


class TodoProvider {
  
  TodoProvider._internal();
  static final TodoProvider _instance = TodoProvider._internal();
  factory TodoProvider() => _instance;
  Database _db;
  
  Future _open() async {
    var databasesPath = await getDatabasesPath();
    _db = await openDatabase(join(databasesPath,_storageName), version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            create table $_tableTodo ( 
              $_colmTodoId integer primary key autoincrement, 
              $_colmTodoTitle text not null,
              $_colmTodoOrder integer not null,
              $_colmTodoDeadline text not null,
              $_colmTodoDone integer not null)
            ''');
          await db.execute('''
            create table $_tableCntt ( 
              $_colmCnttId integer primary key autoincrement, 
              $_colmCnttComments text not null,
              $_colmCnttPid integer not null,
              $_colmCnttDone integer not null)
            ''');
        });
  }

  Future<List<Todo>> poll(int offset, int count) async {
    if(_db == null)
      await _open();
    List<Map> todoRecords = await _db.query(_tableTodo,
        columns: [_colmTodoId, _colmTodoTitle, _colmTodoOrder, _colmTodoDeadline, _colmTodoDone],
        offset: offset,
        orderBy: '$_colmTodoOrder',
        limit: offset + count);
    List<Todo> ans = <Todo>[];
    for (var todoRecord in todoRecords)
    {
      var todo =  Todo.fromMap(todoRecord);
      _joinContents(todo);
      ans.add(todo);
    }
    return ans;
  }

  Future<List<Todo>> pollDoneSortedByOrder(int offset, int count, bool done, bool isGreater) async {
    if(_db == null)
      await _open();
    String compare = isGreater ? 'desc' : 'asc' ;
    List<Map> todoRecords = await _db.query(_tableTodo,
        columns: [_colmTodoId, _colmTodoTitle, _colmTodoOrder, _colmTodoDeadline, _colmTodoDone],
        where: '$_colmTodoDone = ?',
        whereArgs: [done ? 1 : 0],
        offset: offset,
        orderBy: '$_colmTodoOrder $compare',
        limit: offset + count);
    List<Todo> ans = <Todo>[];
    for (var todoRecord in todoRecords)
    {
      var todo =  Todo.fromMap(todoRecord);
      _joinContents(todo);
      ans.add(todo);
    }
    return ans;
  }

  Future<List<Todo>> pollDone(int offset, int count, bool done) async {
    if(_db == null)
      await _open();
    List<Map> todoRecords = await _db.query(_tableTodo,
        columns: [_colmTodoId, _colmTodoTitle, _colmTodoOrder, _colmTodoDeadline, _colmTodoDone],
        where: '$_colmTodoDone = ?',
        whereArgs: [done ? 1 : 0],
        offset: offset,
        limit: offset + count);
    List<Todo> ans = <Todo>[];
    for (var todoRecord in todoRecords)
    {
      var todo =  Todo.fromMap(todoRecord);
      _joinContents(todo);
      ans.add(todo);
    }
    return ans;
  }

  Future<Todo> _joinContents(Todo todo) async
  {
    List<Map> cnttRecords = await _db.query(_tableCntt,
        columns: [_colmCnttId, _colmCnttComments, _colmCnttDone],
        where: '$_colmCnttPid = ?',
        whereArgs: [todo.id]);
    for(var cnttRecord in cnttRecords) {
      Contents contents = Contents.fromMap(cnttRecord);
      todo.contentsList.add(contents);
      dev.log(todo.toString() + "<=" + contents.toString());
    }
    return todo;
  }

  Future<Todo> insert(Todo todo) async {
    if(_db == null)
      await _open();
    todo.id = await _db.insert(_tableTodo, todo.toMap());
    for(var contents in todo.contentsList) {
      await _db.insert(_tableCntt, contents.toMap(todo.id));
    }
    return todo;
  }

  Future<Todo> getTodo(int id) async {
    if(_db == null)
      await _open();
    List<Map> todoRecords = await _db.query(_tableTodo,
        columns: [_colmTodoId, _colmTodoTitle, _colmTodoOrder, _colmTodoDeadline, _colmTodoDone],
        where: '$_colmTodoId = ?',
        whereArgs: [id]);

    List<Map> cnttRecords = await _db.query(_tableCntt,
        columns: [_colmCnttId, _colmCnttComments, _colmCnttDone],
        where: '$_colmCnttPid = ?',
        whereArgs: [id]);
    if (todoRecords.length > 0) {
      var todo =  Todo.fromMap(todoRecords.first);
      for(var record in cnttRecords)
        todo.contentsList.add(Contents.fromMap(record));
      return todo;
    }
    return null;
  }

  Future<int> delete(int id) async {
    if(_db == null)
      await _open();
    await _db.delete(_tableCntt, where: '$_colmCnttPid = ?', whereArgs: [id]);
    return await _db.delete(_tableTodo, where: '$_colmTodoId = ?', whereArgs: [id]);
  }

  Future<int> update(Todo todo, List<int> delCntts) async {
    if(_db == null)
      await _open();
    for(var contents in todo.contentsList) {
      var cnttRecord = contents.toMap(todo.id);
      _db.rawInsert('insert or replace into $_tableCntt($_colmCnttId, $_colmCnttComments, $_colmCnttPid, $_colmCnttDone) values(?, ?, ?, ?)',
          [cnttRecord[_colmCnttId], cnttRecord[_colmCnttComments], cnttRecord[_colmCnttPid], cnttRecord[_colmCnttDone]]
      );
    }
    for(var id in delCntts)
      _db.delete(_tableCntt, where: '$_colmCnttId = ?', whereArgs: [id]);
    return await _db.update(_tableTodo, todo.toMap(), where: '$_colmTodoId = ?', whereArgs: [todo.id]);
  }

  Future close() async => _db.close();
}

