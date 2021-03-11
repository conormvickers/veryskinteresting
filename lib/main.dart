import 'dart:html';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initImage();
    updateDrawer();
    controller = PhotoViewController()..outputStateStream.listen(listener);
  }

  void listener(PhotoViewControllerValue value) {
    setState(() {
      //scaleCopy = value.scale;
    });
  }

  PhotoViewController controller;
  Image _image;
  bool _loading = true;

  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  String url;
  firebase_storage.Reference ref;

  initImage([String item = 'mtor.png']) async {
    await Firebase.initializeApp();
    ref = storage.ref().child(item);
    url = await ref.getDownloadURL();
    print('got download url' + url);
    setState(() {
      _image = Image.network(url);
      _image.image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
          (info, call) {
            print('Networkimage is fully loaded and saved');
            setState(() {
              _loading = false;
            });
            // do something
          },
        ),
      );
    });
  }

  listDocs() async {
    var listRef = storage.ref().child('/');
    listRef
        .listAll()
        .then((res) => {
              res.prefixes.forEach((folderRef) => {
                    print(folderRef),
                  }),
              res.items.forEach((itemRef) => {
                    // All the items under listRef.
                    print(itemRef),
                  }),
            })
        .onError((error, stackTrace) => null);
  }

  List<Widget> drawerItems = [];

  updateDrawer() {
    var listRef = storage.ref().child('/');
    drawerItems = [];
    listRef
        .listAll()
        .then((res) => {
              res.prefixes.forEach((folderRef) => {
                    print(folderRef),
                  }),
              res.items.forEach((itemRef) => {
                    // All the items under listRef.
                    print(itemRef),
                    drawerItems.add(ListTile(
                      title: Text(itemRef.fullPath),
                      onTap: () => {
                        setState(() => {
                              _loading = true,
                            }),
                        Navigator.pop(context),
                        initImage(itemRef.fullPath)
                      },
                    ))
                  }),
            })
        .onError((error, stackTrace) => null);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          children: drawerItems,
        ),
      ),
      body: _loading
          ? Container(
              child: SpinKitFoldingCube(
                color: Colors.lightBlue,
              ),
            )
          : Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // do something when scrolled
                  print(pointerSignal.scrollDelta);
                  final newScale = controller.scale *
                      (pointerSignal.scrollDelta.direction * 0.2 + 1);
                  if (newScale > 0.1 && newScale < 10) {
                    controller.scale = newScale;
                  }
                }
              },
              child: PhotoView(
                controller: controller,
                maxScale: 10,
                minScale: 0.1,
                imageProvider: _image.image,
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => {listDocs()},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
