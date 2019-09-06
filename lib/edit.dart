import 'package:english_words/english_words.dart' as prefix0;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:todo/myTheme.dart';
import 'package:todo/notifyManager.dart';
import 'dart:developer' as dev;
import 'todo.dart';
import 'myTheme.dart';

class EditPageArguments {
  EditPageArguments(this.template, this.isNew);

  Todo template;
  bool isNew;
}

class EditPageReturns {
  EditPageReturns(this.dirty, this.id);

  bool dirty;
  int id;
}

class EditPage extends StatefulWidget {
  EditPage({@required this.template, @required this.isNew});

  final bool isNew;
  final Todo template;

  @override
  State<StatefulWidget> createState() {
    return new EditState();
  }
}

class EditState extends State<EditPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Todo _template;
  bool _isEditing;

  final _delCntts = <int>[];
  final _orderController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentsControllers = <TextEditingController>[];

  void _popNavigation(bool dirty) {
    Navigator.pop(context, EditPageReturns(dirty, _template.id));
  }

  void _cancelTodoEdit() async {
    if (widget.isNew)
      _popNavigation(false);
    else {
      _template = await TodoProvider().getTodo(_template.id);
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _commitContentsDone() async {
    if (widget.isNew)
      return;
    else
      await TodoProvider().update(_template, <int>[]);
  }

  void _commitTodoEdit() async {
    if (widget.isNew)
      await TodoProvider().insert(_template);
    else
      await TodoProvider().update(_template, _delCntts);

    if (_template.hasDeadLine && _template.deadline.isAfter(DateTime.now())) {
      NotifyManager()
          .deadlineSchedule(_template.id, _template.title, _template.deadline);
    } else {
      NotifyManager().cancelSchedule(_template.id);
    }
    _popNavigation(true);
  }

  void _commitTodoDel(int id) async {
    if (widget.isNew) return;
    await TodoProvider().delete(id);
    _popNavigation(true);
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNew;
    _template = widget.template;
  }

  @override
  Widget build(BuildContext context) {
    for (int i = _contentsControllers.length - 1;
        i < _template.contentsList.length;
        i++) _contentsControllers.add(TextEditingController());
    _titleController.text = _template.title;
    _orderController.text = _template.order.toString();
    for (int i = 0; i < _template.contentsList.length; i++) {
      _contentsControllers[i].text = _template.contentsList[i].comments;
    }
    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            title: Text("Detail",
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: Theme.of(context).accentColor)),
          ),
          _isEditing ? _buildEditTodoDetail() : _buildStdTodoDetail(),
          SliverFillRemaining(
              hasScrollBody: false,
              child: Column(children: <Widget>[
                Divider(),
                Card(
                    margin: EdgeInsets.fromLTRB(30, 10, 30, 10),
                    child: Container(
                      margin: EdgeInsets.only(left: 15.0),
                      height: 60,
                      child: _isEditing
                          ? _buildEditDeadline()
                          : _buildStdDeadline(),
                    )),
                Card(
                    margin: EdgeInsets.fromLTRB(30, 10, 30, 10),
                    child: Container(
                      margin: EdgeInsets.only(left: 15.0),
                      height: 60,
                      child: Row(children: <Widget>[
                        Expanded(
                            child: Text("Order",
                                style:
                                    Theme.of(context).textTheme.title.copyWith(
                                          color: Theme.of(context).accentColor,
                                        ))),
                        Expanded(
                          flex: 2,
                          child:
                              _isEditing ? _buildEditOrder() : _buildStdOrder(),
                        ),
                      ]),
                    ))
              ])),
        ],
      ),
      bottomNavigationBar:
          _isEditing ? _buildEditButtonBar() : _buildStdButtonBar(),
    );
  }

  Widget _buildStdTodoDetail() {
    return Container(
        child: SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i == 0)
          return _buildStdTitleRow();
        else if (i <= _template.contentsList.length)
          return _buildStdContentsRow(i - 1);
        else
          return ListTile();
      }, childCount: _template.contentsList.length + 1),
    ));
  }

  Widget _buildStdTitleRow() {
    return ListTile(
        title: Text(_template.title,
            style: Theme.of(context)
                .textTheme
                .title
                .copyWith(fontWeight: FontWeight.bold)));
  }

  Widget _buildStdContentsRow(int index) {
    Contents cur = _template.contentsList[index];
    return new ListTile(
      leading: _buildDoneCheckbox(index),
      title: Text(cur.comments),
      onTap: () => dev.log("update check."),
    );
  }

  Widget _buildStdDeadline() {
    return Row(children: <Widget>[
      Expanded(
          child: Icon(_template.hasDeadLine ? Icons.alarm : Icons.alarm_off,
              color: Theme.of(context).accentColor)),
      Expanded(
        flex: 2,
        child: Text(
          _template.getDeadLine(),
          textAlign: TextAlign.center,
        ),
      ),
      Expanded(child: Text(''))
    ]);
  }

  Widget _buildStdOrder() {
    return Text(
      _template.order.toString(),
      style: Theme.of(context)
          .textTheme
          .title
          .copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStdButtonBar() {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        FlatButton.icon(
          icon: Icon(Icons.check),
          label: Text('Complete'),
          onPressed: () {
            _template.done = true;
            _commitTodoEdit();
          },
        ),
        FlatButton.icon(
            icon: Icon(Icons.edit),
            label: Text('Edit'),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            }),
        FlatButton.icon(
          icon: Icon(Icons.delete),
          label: Text('Delete'),
          onPressed: () => _commitTodoDel(_template.id),
        )
      ],
    );
  }

  Widget _buildEditTodoDetail() {
    return Container(
        child: SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i == 0)
          return _buildEditTitleRow();
        else if (i <= _template.contentsList.length)
          return _buildEditContentsRow(i - 1);
        else
          return _buildEditAddRow();
      }, childCount: _template.contentsList.length + 2),
    ));
  }

  Widget _buildEditTitleRow() {
    return ListTile(
      title: TextField(
        controller: _titleController,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(fontWeight: FontWeight.bold),
        keyboardType: TextInputType.multiline,
        decoration: new InputDecoration.collapsed(hintText: "제목"),
        onChanged: (text) => _template.title = text,
      ),
    );
  }

  Widget _buildEditContentsRow(int index) {
    Contents cur = _template.contentsList[index];
    return new ListTile(
      leading: _buildDoneCheckbox(index),
      title: TextField(
        controller: _contentsControllers[index],
        keyboardType: TextInputType.multiline,
        decoration: new InputDecoration.collapsed(hintText: "내용"),
        onChanged: (text) => cur.comments = text,
      ),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline),
        onPressed: () {
          setState(() {
            _delCntts.add(cur.id);
            _template.contentsList.remove(cur);
          });
        },
      ),
    );
  }

  Widget _buildEditAddRow() {
    return new ListTile(
      leading: Icon(Icons.navigate_next),
      title: Text(
        "Add New Contents",
      ),
      onTap: () {
        setState(() {
          _template.contentsList.add(Contents(""));
        });
      },
    );
  }

  Widget _buildEditDeadline() {
    return Row(children: <Widget>[
      Expanded(
          child: IconButton(
        icon: Icon(_template.hasDeadLine ? Icons.alarm : Icons.alarm_off),
        color: Theme.of(context).accentColor,
        onPressed: () {
          setState(() {
            _template.hasDeadLine = !_template.hasDeadLine;
          });
        },
      )),
      Expanded(
        flex: 2,
        child: Text(
          _template.getDeadLine(),
          textAlign: TextAlign.center,
        ),
      ),
      Expanded(
          child: Visibility(
              visible: _template.hasDeadLine,
              child: FlatButton(
                  child: Text("Pick Date"),
                  onPressed: () => _buildDateTimePicker())))
    ]);
  }

  void _buildDateTimePicker() async {
    DateTime dateNow = DateTime.now();
    DateTime selDate = await showDatePicker(
        context: context,
        initialDate: dateNow,
        firstDate: DateTime(dateNow.year, dateNow.month, dateNow.day),
        lastDate: DateTime(2077),
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.dark(),
            child: child,
          );
        });
    TimeOfDay selTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.dark(),
            child: child,
          );
        });
    if (selDate != null && selTime != null) {
      DateTime selDateTime = DateTime(selDate.year, selDate.month, selDate.day,
          selTime.hour, selTime.minute);
      setState(() {
        _template.hasDeadLine = true;
        _template.deadline = selDateTime;
      });
    }
  }

  Widget _buildEditOrder() {
    return TextField(
      controller: _orderController,
      keyboardType: TextInputType.number,
      decoration: new InputDecoration.collapsed(),
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .title
          .copyWith(fontWeight: FontWeight.bold),
      onChanged: (text) => _template.order = int.parse(text),
    );
  }

  Widget _buildEditButtonBar() {
    return ButtonBar(
      children: <Widget>[
        FlatButton(child: Text('Cancel'), onPressed: () => _cancelTodoEdit()),
        FlatButton(child: Text('Save'), onPressed: () => _commitTodoEdit()),
      ],
    );
  }

  Widget _buildDoneCheckbox(int index) {
    Contents cur = _template.contentsList[index];
    return IconButton(
        icon: Icon(cur.done ? Icons.check_box : Icons.check_box_outline_blank),
        onPressed: () {
          setState(() {
            cur.done = !cur.done;
            _commitContentsDone();
          });
        });
  }
}
