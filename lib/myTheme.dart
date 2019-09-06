import 'package:english_words/english_words.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

final ThemeData mainLightTheme = _buildTheme();

final Color _colorAccent = Color.fromARGB(0xFF,0xCF,0x21,0x6A);
final Color _colorButton = Color.fromARGB(0xFF,0xD9,0x04,0x29);
final Color _colorSoft = Color.fromARGB(0xFF,0xED,0xF2,0xF4);
final Color _colorHard = Color.fromARGB(0xFF,0x2B,0x2D,0x42);
final Color _colorPrimary = Color.fromARGB(0xFF,0x2B,0x2D,0x42);
final Color _colorBackground = Color.fromARGB(0xFF, 0xF0, 0xF0, 0xF0);

TextTheme _buildTextTheme(TextTheme base) {
  return base.copyWith(
    headline: base.headline.copyWith( fontWeight: FontWeight.w500, ),
    title: base.title.copyWith( fontSize: 18.0 ),
    caption: base.caption.copyWith( fontWeight: FontWeight.w400, fontSize: 14.0, ),
  ).apply(
    displayColor: _colorAccent,
    bodyColor: _colorPrimary,
  );
}


ThemeData _buildTheme() {
  final ThemeData base = ThemeData.light();
  return base
      .copyWith(
        accentColor: _colorAccent,
        primaryColor: _colorPrimary,
        buttonTheme: base.buttonTheme.copyWith(
          buttonColor: _colorButton,
          textTheme: ButtonTextTheme.normal,
        ),
        scaffoldBackgroundColor: _colorBackground,
        cardColor: _colorSoft,
        textSelectionColor: _colorBackground,
        errorColor: _colorHard,
        textTheme: _buildTextTheme(base.textTheme),
        primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
        accentTextTheme: _buildTextTheme(base.accentTextTheme),
        primaryIconTheme: base.iconTheme.copyWith( color: _colorAccent )
  );
}