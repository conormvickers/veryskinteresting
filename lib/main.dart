import 'dart:html';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

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
        primarySwatch: Colors.indigo,
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

class Disease {
  Disease(this.name, this.gene, this.info, [this.activating]);
  String name;
  String gene;
  String info;
  bool activating;
}
Disease noonan = Disease("Noonan Syndrome", "SHP2 SOS", "Noonan syndrome: lower extremity lymphedema, "
    "CALM, multiple nevi, light/curly/rough hair, hypertelorism, ulerythema ophryogenes, webbed neck, "
    "lowered nuchal hairline, and low set ears (note: allelic with LEOPARD syndrome – both have pulmonic stenosis)",  );
Disease costello = Disease("Costello", "RAS" , "AD, one of the RASopathies; mutations in HRAS (85%) > "
    "KRAS (10%–15%). Lax skin on hands and feet, coarse facies, low-set ears, deep palmoplantar creases, "
    "periorificial papillomas, acanthosis nigricans, and curly hair");

class Drug {
  Drug(this.name, this.gene, this.info);
  String name;
  String gene;
  String info;
}



class Protein {
  Protein(this.name, this.key);
  String name;
  GlobalKey key;
}

List<String> mapk = [
  "Tyrosine Kinase",
  "SHP2 SOS",
  "RAS:KRAS/HRAS/NRAS",
  "BRAF",
  "MEK",
  "ERK",
  "Cyclins,n"
];

List<String> gprot = ["G-Protein CP:QNAQ/QNAS"];

List<String> stopras = ["-Neurofibromin"];

List<Protein> mapkProteins = mapk.map((e) => Protein(e, GlobalKey())).toList();


List<List<Protein>> allProteins = [[]];
List<Disease> allDiseases = [];

class ProfileCardPainter extends CustomPainter {
  ProfileCardPainter({@required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    allProteins.asMap().forEach((numberOfPath, pathway) {
      List<Offset> points = [];
      pathway.asMap().forEach((key, value) {
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
        points.add(box);
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
      final p1 = Offset(0, 0);
      final p2 = Offset(500, 500);
      final paint = Paint()
        ..color = Colors.pink
        ..strokeWidth = 4;
      canvas.drawLine(p1, p2, paint);
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
    super.initState();
    initImage();
    updateDrawer();
    List<List<String>> strings = [gprot, mapk, stopras];         //TODO: add all pathways
    allProteins = strings
        .map((e) => e.map((e) => Protein(e, GlobalKey())).toList())
        .toList();

     allDiseases = [noonan, costello];

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


  void _showDialog(BuildContext context, String name, String info) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title:  Text(name),
          content:  Column(
            mainAxisSize: MainAxisSize.min,

            children: <Widget>[
              Text(info)
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('done'),
            ),
          ],
        );
      },
    );
  }

  Widget nuclear() {
    List<Widget> a = [];

    allProteins.asMap().forEach((num, pathway) {

      List<Widget> colStuff = [];
      pathway.asMap().forEach((key, value) {

        if (value.name.contains(',')) {
          if (value.name.substring(value.name.indexOf(',') ).contains('n')  ) {

            String name = 'No name';
            String info = 'No info';
            Widget diseaseState = Container();
            allDiseases.asMap().forEach((n, disease) {
              if (value.name.toUpperCase().contains( disease.gene.toUpperCase() ) ) {
                name = disease.name;
                info = disease.info;
                diseaseState = GestureDetector(
                  onTap: () => {
                    _showDialog(context, name, info)
                  },
                  child: Container(


                      child: Text(name),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.red,
                      )),
                );
              }
            });

            colStuff.add(Container(

              child: Row(
                children: [
                  Container(
                    key: value.key,
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.lightBlue,
                    ),
                    child: Text(value.name.contains(':') ? value.name.substring(0, value.name.indexOf(':')) : value.name),
                  ),
                  diseaseState
                ],
              ),
            ));


            if (value.name.contains(':')) {
              List<Widget> vbox = [];
              List<String> variants = value.name.substring(value.name.indexOf(':') + 1).split('/');
              variants.asMap().forEach((v, variant) {
                vbox.add(Container(

                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.lightGreen,
                    ),
                    child: Text(variant),
                  ),
                ));
              });
              colStuff.add(Row(children: vbox,));
            }

            if (key < pathway.length - 1) {
              colStuff.add(Container(

                child: Icon(
                  Icons.arrow_downward_outlined,
                  color: Colors.green,
                ),
              ));
            }

          }
        }


      });
      Column col = Column(
        children: colStuff,
      );
      a.add(col);


    });
    return Row( children: a,) ;
  }

  List<Widget> enzymes() {
    List<Widget> a = [];

    allProteins.asMap().forEach((num, pathway) {
      if (pathway[0].name.substring(0,1) == '-') {
        List<Widget> colStuff = [];
        pathway.asMap().forEach((key, value) {
          colStuff.add(
            Container(height: 500,),);
          colStuff.add(Container(width: 100, height: 100, color: Colors.red,)
          );
        });
        Column col = Column(
          children: colStuff,
        );
        a.add(col);
    }else{
        List<Widget> colStuff = [];
        pathway.asMap().forEach((key, value) {
          if (!value.name.contains(',')) {
            String name = 'No name';
            String info = 'No info';
            Widget diseaseState = Container();
            allDiseases.asMap().forEach((n, disease) {
              if (value.name.toUpperCase().contains( disease.gene.toUpperCase() ) ) {
                name = disease.name;
                info = disease.info;
                diseaseState = GestureDetector(
                  onTap: () => {
                    _showDialog(context, name, info)
                  },
                  child: Container(
        
        
              child: Text(name),
              decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.red,
              )),
                );
              }
            });
        
            colStuff.add(Container(
        
              child: Row(
                children: [
                  Container(
                    key: value.key,
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.lightBlue,
                    ),
                    child: Text(value.name.contains(':') ? value.name.substring(0, value.name.indexOf(':')) : value.name),
                  ),
                  diseaseState
                ],
              ),
            ));
        
        
            if (value.name.contains(':')) {
              List<Widget> vbox = [];
              List<String> variants = value.name.substring(value.name.indexOf(':') + 1).split('/');
              variants.asMap().forEach((v, variant) {
                vbox.add(Container(
        
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.lightGreen,
                    ),
                    child: Text(variant),
                  ),
                ));
              });
              colStuff.add(Row(children: vbox,));
            }
        
            if (key < pathway.length - 1) {
              colStuff.add(Container(
        
                child: Icon(
                  Icons.arrow_downward_outlined,
                  color: Colors.green,
                ),
              ));
            }
          }
        
        
        });
        Column col = Column(
          children: colStuff,
        );
        a.add(col);
      }


    });
    return [Row( children: a, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,) ];
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
          constrained: true,
          minScale: 0.5,
          maxScale: 10,

          child: Container(
              // height: 100,
              // width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 5),
                borderRadius: BorderRadius.circular(40)
              ),
              
              child: FittedBox(
                child: Stack(
                  children: [
                    Container(
                      color: Colors.blue.withAlpha(50),
                      width: 1000,
                      height: 1000,
                    ),
                    ...enzymes(),
                    Container(
                      width: 1000,
                      height: 1000,
                      child: Column(
                        children: [
                          Expanded(child: Container(),),
                          Expanded(child: Container(
                            padding: EdgeInsets.all(50),
                            child: Container(
                              child: nuclear(),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple, width: 5),
                                borderRadius: BorderRadius.circular(40)
                            ),),
                          ))
                        ],
                      ),
                    )
                    // CustomPaint(
                    //   size: Size(1000, 1000),
                    //   painter: ProfileCardPainter(color: Colors.orange),
                    // ),
                  ],
                ),
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
