import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Mines',
      theme: new ThemeData(
          primarySwatch: Colors.red,
          brightness: Brightness.light,
          canvasColor: Colors.white
      ),
      home: new MyHomePage(title: 'Mines'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  _MyHomePageState() {
    _newGame(13, 10, 15);
  }

  static const platform = const MethodChannel('devisnik.de/mines');


  void _startTimer() {
    timer = new Timer.periodic(new Duration(seconds: 1), _incTimer);
    _isRunning = true;
  }

  void _stopTimer() {
    timer.cancel();
    _isRunning = false;
  }

  void _incTimer(Timer timer) {
    setState(() {
      _seconds++;
    });
  }

  void _resetTimer() {
    setState(() {
      _seconds = 0;
    });
  }

  List<List<int>> _state = [];

  int _flagsToSet = 30;
  int _seconds = 0;
  bool _isRunning = false;
  Timer timer;

  Future<Null> _openField(int row, int column) async {
    print("open-start: " + new DateTime.now().toString());
    Map newState = await platform.invokeMethod("click", {
      "row": row,
      "column": column
    });
    print("open-receive: " + new DateTime.now().toString());
    if (!_isRunning && newState["running"]) _startTimer();
    if (_isRunning && !newState["running"]) _stopTimer();
    setState(() {
      _state = newState["board"];
      _flagsToSet = newState["flags"];
    });
  }

  Future<Null> _flagField(int row, int column) async {
    print("flag-start: " + new DateTime.now().toString());
    Map newState = await platform.invokeMethod("longclick", {
      "row": row,
      "column": column
    });
    print("flag-receive: " + new DateTime.now().toString());
    if (!_isRunning && newState["running"]) _startTimer();
    if (_isRunning && !newState["running"]) _stopTimer();
    setState(() {
      _state = newState["board"];
      _flagsToSet = newState["flags"];
    });
  }

  Future<Null> _newGame(int rows, int columns, int bombs) async {
    if (_isRunning) {
      _stopTimer();
    }
    _resetTimer();
    Map newState = await platform.invokeMethod("start", {
      "rows": rows,
      "columns": columns,
      "bombs": bombs
    });
    if (!_isRunning && newState["running"]) _startTimer();
    if (_isRunning && !newState["running"]) _stopTimer();
    setState(() {
      _state = newState["board"];
      _flagsToSet = newState["flags"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.add_circle),
            onPressed: () {
              _newGame(13, 10, 15);
            }
          )
        ],
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new RepaintBoundary.wrap(
                  new Counter(
                    value: _flagsToSet,
                  ),
                  0
              ),
              new RepaintBoundary.wrap(
                  new Counter(
                    value: _seconds,
                  ),
                  1
              ),
            ],
          ),
          new RepaintBoundary.wrap(
              new Center(
                child: new Board(
                  ids: _state,
                  size: MediaQuery
                      .of(context)
                      .size
                      .width,
                  onClick: _openField,
                  onLongClick: _flagField,
                ),
              ),
              2
          )
        ],
      ),
    );
  }
}

class Tile extends StatelessWidget {

  final int id;
  final double size;
  final VoidCallback onClick;
  final VoidCallback onLongClick;

  const Tile({Key key, this.id, this.size, this.onClick, this.onLongClick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
        onTap: onClick,
        onLongPress: onLongClick,
        child: new Image.asset(
          "assets/images/classic_image_${id < 10 ? "0$id" : "$id"}.png",
          width: size,
          height: size,
          gaplessPlayback: true, //to avoid image flickering
        )
    );
  }
}

typedef void ColumnCallback(int);

class TileRow extends StatelessWidget {

  final List<int> ids;
  final double width;
  final ColumnCallback onClick;
  final ColumnCallback onLongClick;

  const TileRow({Key key, this.ids, this.width, this.onClick, this.onLongClick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = [];
    ids.asMap().forEach((index, id) =>
        tiles.add(
            new Tile(
              id: id,
              size: width / ids.length,
              onClick: () => onClick(index),
              onLongClick: () => onLongClick(index),
            )
        )
    );
    return new Row(
        children: tiles
    );
  }
}

typedef void RowColumnCallback(int row, int column);

class Board extends StatelessWidget {

  final List<List<int>> ids;
  final double size;
  final RowColumnCallback onClick;
  final RowColumnCallback onLongClick;

  const Board({this.ids, this.size, this.onClick, this.onLongClick});

  @override
  Widget build(BuildContext context) {
    List<TileRow> rows = [];
    ids.asMap().forEach((rowIndex, values) =>
        rows.add(
            new TileRow(
              ids: values,
              width: size,
              onClick: (columnIndex) => onClick(rowIndex, columnIndex),
              onLongClick: (columnIndex) => onLongClick(rowIndex, columnIndex),
            )
        )
    );
    return new Column(
        children: rows
    );
  }
}

class Digit extends StatelessWidget {

  const Digit({Key key, this.value, this.size}) : super(key: key);

  final int value;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return new Image.asset(
      'assets/images/counter_$value.gif',
      fit: BoxFit.fill,
      width: size.width,
      height: size.height,
      gaplessPlayback: true,
    );
  }
}

class Counter extends StatelessWidget {

  const Counter({Key key, this.value}) : super(key: key);

  final int value;

  @override
  Widget build(BuildContext context) {
    var size = new Size(20.0, 35.0);
    return new Row(
      children: <Widget>[
        new Digit(
          value: (value / 100).floor() % 10,
          size: size,
        ),
        new Digit(
          value: (value / 10).floor() % 10,
          size: size,
        ),
        new Digit(
          value: value % 10,
          size: size,
        ),
      ],
    );
  }
}
