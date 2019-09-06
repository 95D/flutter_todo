import 'package:english_words/english_words.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'home.dart';
import 'edit.dart';
import 'todo.dart';
import 'myTheme.dart';

void main() async {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: mainLightTheme,
      home: HomePage(),
      onGenerateRoute: (RouteSettings settings)
      {
        switch(settings.name)
        {
          case '/edit':
            final EditPageArguments args = settings.arguments;
            return SlideUpRoute(widget:EditPage(
              template: args.template,
              isNew: args.isNew,
            ));
            break;
        }
        return null;
      }
    );
  }
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget widget;
  SlideUpRoute({this.widget}) : super(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation)
  {
    return widget;
  },
  transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return new SlideTransition(position: new Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset(0.0, 0.0)).animate(animation), child: child);
  });
}