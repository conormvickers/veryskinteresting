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
        primarySwatch: Colors.blueGrey,
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

class Protein {
  Protein(this.name, this.key);
  String name;
  GlobalKey key;
}

List<String> mapk = ["Tyrosine Kinase", "SHP2/SOS", "KRAS/HRAS/NRAS"];
List<Protein> mapkProteins = mapk.map((e) => Protein(e, GlobalKey())).toList();

class ProfileCardPainter extends CustomPainter {
  //2
  ProfileCardPainter({@required this.color});

  //3
  final Color color;

  //4
  @override
  void paint(Canvas canvas, Size size) {
    //1
    List<Offset> points = [];
    mapkProteins.asMap().forEach((key, value) {
      GlobalKey gkey = value.key;
      final b = (gkey.currentContext.findRenderObject() as RenderBox)
          .getTransformTo(gkey.currentContext.findRenderObject().parent)
          .getTranslation();
      final d = (gkey.currentContext.findRenderObject() as RenderBox).size;
      var hOffset = 0.0;
      if (key.isEven) {
        hOffset = d.height;
      }
      Offset box = Offset(b.x + (d.width / 2), b.y + hOffset);
      //localToGlobal(Offset.zero);
      points.add(box);
      print(box);
    });
    points.asMap().forEach((n, point) {
      if (n > 0 && n < points.length) {
        final p1 = point;
        final p2 = points[n - 1];
        final paint = Paint()
          ..color = Colors.pink
          ..strokeWidth = 4;
        canvas.drawLine(p1, p2, paint);
      }
    });
  }

  @override
  bool shouldRepaint(ProfileCardPainter oldDelegate) {
    return color != oldDelegate.color;
  }
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

  List<Widget> enzymes() {
    List<Widget> a = [];
    double y = 0;
    mapkProteins.asMap().forEach((key, value) {
      y = y + 100;
      a.add(Positioned(
        left: 100,
        top: y,
        child: Container(
          key: value.key,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.lightBlue,
          ),
          child: Text(value.name),
        ),
      ));
    });
    return a;
  }

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
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Set it to false to prevent panning.
          boundaryMargin: EdgeInsets.all(80),
          minScale: 0.5,
          maxScale: 4,
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 5)),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: ProfileCardPainter(color: Colors.orange),
                  ),
                  ...enzymes(),
                  // Positioned(
                  //   left: 400,
                  //   child: Container(
                  //     child: PopupMenuButton<String>(
                  //       itemBuilder: (context) => [PopupMenuItem(child: Text('a'))],
                  //     ),
                  //     width: 100,
                  //     height: 100,
                  //     color: Colors.red,
                  //   ),
                  // ),
                ],
              )),
        ),
      ),

      // _loading
      //     ? Container(
      //         child: SpinKitFoldingCube(
      //           color: Colors.lightBlue,
      //         ),
      //       )
      //     : Center(
      //         child: InteractiveViewer(
      //           panEnabled: true, // Set it to false to prevent panning.
      //           boundaryMargin: EdgeInsets.all(80),
      //           minScale: 0.5,
      //           maxScale: 4,
      //           child: Container(
      //               width: _image.width,
      //               height: _image.height,
      //               child: Stack(
      //                 children: [
      //                   //_image,
      //                   CustomPaint(
      //                     size: Size.infinite,
      //                     painter: ProfileCardPainter(color: Colors.orange),
      //                   ),
      //                   ...enzymes(),
      //                   Positioned(
      //                     left: 400,
      //                     child: Container(
      //                       child: PopupMenuButton<String>(
      //                         itemBuilder: (context) =>
      //                             [PopupMenuItem(child: Text('a'))],
      //                       ),
      //                       width: 100,
      //                       height: 100,
      //                       color: Colors.red,
      //                     ),
      //                   ),
      //                 ],
      //               )),
      //         ),
      //       ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => {listDocs()},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
