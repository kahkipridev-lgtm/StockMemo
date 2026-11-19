import 'dart:io';

/// iOSではネイティブのタブバー（RootFlutterViewController.swift）をFlutterの画面の上に重ねているため、
/// Flutter側からはその高さが見えない。画面下端まで届くもの（ボトムシートなど）は、
/// セーフエリアに加えてこの分だけ余白を空けないとタブバーに隠れる。
const double nativeTabBarHeight = 49;

/// ネイティブのタブバーで隠れる高さ（iOS以外は0）
double get nativeTabBarInset => Platform.isIOS ? nativeTabBarHeight : 0;
