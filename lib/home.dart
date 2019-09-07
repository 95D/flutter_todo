import 'package:english_words/english_words.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:todo/edit.dart';
import 'package:todo/todo.dart';
import 'dart:developer' as dev;
import 'myTheme.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new HomeTodoListState();
  }
}

class HomeTodoListState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _todos = <Todo>[];
  bool pollAwait = false;
  bool pollOrderGreater = false;
  bool pollIsDone = false;

  void _pushEdit(
      {int index = 0, bool isEditing = true, bool isNew = true}) async {
    Todo todo = isNew ? Todo() : await TodoProvider().getTodo(_todos[index].id);
    EditPageReturns ans = (await Navigator.pushNamed(context, '/edit',
        arguments: EditPageArguments(todo, isNew))) as EditPageReturns;
    if (ans != null && ans.dirty) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Todo edit complete."),
        duration: Duration(milliseconds: 400),
      ));
      if (!isNew) {
        Todo updated = await TodoProvider().getTodo(ans.id);
        setState(() {
          if (updated == null || updated.done != pollIsDone)
            _todos.removeAt(index);
          else
            _todos[index] = todo;
          _todos.sort((Todo a, Todo b){
            if(a.order > b.order)
              return pollOrderGreater ? -1 : 1;
            else if(a.order == b.order)
              return 0;
            else
              return pollOrderGreater ? 1 : -1;
          });
        });
      }
    }
  }

  void _pollNext(int offset) async {
    pollAwait = true;
    List<Todo> nxts = await TodoProvider().pollDoneSortedByOrder(
        offset, 100, pollIsDone, pollOrderGreater);
    setState(() {
      _todos.addAll(nxts);
    });
    pollAwait = false;
  }

  @override
  Widget build(BuildContext context) {
    double curHeight = 0.0;
    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
              expandedHeight: 250,
              floating: false,
              pinned: true,
              flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    curHeight = constraints.biggest.height;
                    return FlexibleSpaceBar(
                        title: AnimatedOpacity(
                            duration: Duration(milliseconds: 200),
                            opacity: curHeight == 80.0 ? 1.0 : 0.0,
                            child: Text("Todo",
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .title
                                    .copyWith(
                                    color: Theme
                                        .of(context)
                                        .accentColor))),
                        background: AnimatedOpacity(
                          duration: Duration(milliseconds: 200),
                          opacity: curHeight >= 180.0 ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Text(
                              "Todo",
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .body2
                                  .copyWith(
                                  fontSize: 42.0,
                                  color: Theme
                                      .of(context)
                                      .accentColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ));
                  }),
              bottom: PreferredSize(
                  child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          IconButton(
                              icon: Icon(Icons.add),
                              color: Theme
                                  .of(context)
                                  .accentColor,
                              onPressed: () =>
                                  _pushEdit(
                                      isEditing: true)), //Navigator.pushNamed),
                          IconButton(
                              icon: Icon(pollOrderGreater ? Icons.arrow_downward : Icons.arrow_upward),
                              color: Theme
                                  .of(context)
                                  .accentColor,
                              onPressed: () {
                                setState(() {
                                  pollOrderGreater = ! pollOrderGreater;
                                  _todos.clear();
                                });
                              }),
                          IconButton(
                              icon: Icon(pollIsDone ? Icons.check_box : Icons.check_box_outline_blank),
                              color: Theme
                                  .of(context)
                                  .accentColor,
                              onPressed: () {
                                setState(() {
                                  pollIsDone = !pollIsDone;
                                  _todos.clear();
                                });
                              })
                        ],
                      )))),
          _buildTodoList(), //_buildSuggestions()
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    return new Container(
      //decoration: new BoxDecoration(
      //color: Color(0xFF454545)
      // borderRadius: new BorderRadius.vertical(top: Radius.circular(19.0))
      //),
        child: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                if (i.isOdd) return Divider();
                final index = i ~/ 2;
                if (index == _todos.length) {
                  if (pollAwait)
                    return ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text("Loading.."));
                  else
                    _pollNext(_todos.length);
                }
                if (index < _todos.length)
                  return _buildTodoRow(index);
                else
                  return ListTile(); // end
              },
              childCount: _todos.length * 2 + 1,
            )));
  }

  Widget _buildTodoRow(int index) {
    final Todo model = _todos[index];
    return ListTile(
        title: Text(
          model.title,
        ),
        subtitle: Text(
          model.getDeadLine(),
          style: Theme
              .of(context)
              .textTheme
              .body2
              .copyWith(color: Theme
              .of(context)
              .accentColor),
        ),
        trailing: Container(
          alignment: Alignment(0, 0),
          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Theme
                .of(context)
                .accentColor,
            borderRadius: BorderRadius.all(const Radius.circular(15)),
          ),
          child: Text(model.order.toString(),
              style: Theme
                  .of(context)
                  .textTheme
                  .body1
                  .copyWith(color: Theme
                  .of(context)
                  .textSelectionColor)),
        ),
        onTap: () => _pushEdit(index: index, isEditing: false, isNew: false));
  }
}
