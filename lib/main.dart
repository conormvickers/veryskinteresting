import 'dart:convert';
import 'dart:html';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:math' as math;

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

class Medication {
  Medication(this.name, this.gene, this.info);
  String name;
  String gene;
  String info;
}

List<Medication> allMedications = [
  Medication("Vismodegib", "SMO", ""),
  Medication("Vemurafenib\nDabrafenib", "BRAF", ""),
  Medication("Trametenib", "MEK", "")
];

List<Disease> allDiseases = [
  Disease(
    "Noonan Syndrome",
    "SHP2 SOS",
    "",
  ),
  Disease(
      "HRAS: Spitz, Costello, Phakomatosis Pigmentokeratotica\nNRAS: Congenital Nevi\nKRAS: Noonan",
      "RAS",
      ""),
  Disease("Gorlin", "PTCH", ""),
  Disease("LEOPARD", "PTPN", ""),
  Disease("GNAQ: Uveal Melanoma, Blue Nevus, Port Wine\nGNAS: Mccune Albright",
      "GNAQ", ""),
  Disease("NAME/LAME", "PKA", ""),
  Disease("Neurofibromatosus", "neurofibromin", ""),
  Disease("Melanoma non-sun exposed", "BRAF", ""),
  Disease("Cardiofacio Cutaneous Syndrome", "MEK", ""),
  Disease("Legius", "spred1", ""),
  Disease("SebK, Epidermal Nevus\nKippel-Trenauny, CLOVES ", "PI3K", ""),
  Disease("Neurofibromatosis 2, Cowden, Bannanyana", "PTEN", ""),
  Disease("Proteus", "AKT", ""),
  Disease("Tubeous Sclerosus", "Hamartin", ""),
  Disease("Birt-Hogg-Dube", "Folliculin", ""),
  Disease(
      "Incognentia Pigmenti\nHypohydrotic Ectodermal Dyspasia w/ Immunodefficiency",
      "NEMO",
      "")
];

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
  "PTPNII",
  "SHP2 SOS",
  "RAS:HRAS/NRAS/KRAS",
  "BRAF",
  "MEK",
  "ERK",
];

List<String> mtorpath = ["Tyrosine Kinase", "PI3K", "AKT", "mtor"];
List<String> antiTor = [
  "-PI3K",
  "PTEN Merlin",
  "-AKT",
  "Hamartin Tuberin",
  "-mtor",
  "Folliculin"
];

List<String> gprot = [
  "G-Protein CP:GNAQ/GNAS",
  "Adenylate Cyclase",
  "cAMP",
  "PKA"
];

List<String> ptchpath = ["SMO", "GLI"];
List<String> nemo = ["TNF-a", "NEMO", "IkB - NFkB - p50"];
List<String> antiNemo = ["-NEMO", "CYLD"];

List<String> ptch = ["-SMO", "PTCH"];
List<String> stopras = ["-RAS", "Neurofibromin", "-BRAF", "Spred1"];

List<List<String>> strings = [
  gprot,
  mapk,
  stopras,
  mtorpath,
  antiTor,
  ptchpath,
  ptch,
  nemo,
  antiNemo,
  ["Wnt", 'Frizzled', 'beta catenin'],
  ['-beta catenin', 'APC'],
  ["Cyclins,nuclear", 'Cell Cycle progression'],
  ["-cyclins,nuclear", "BAP, p57, p53, p16"]
];

List<Protein> mapkProteins = mapk.map((e) => Protein(e, GlobalKey())).toList();

List<List<Protein>> allProteins = [[]];

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    initImage();
    updateDrawer();

    allProteins = strings
        .map((e) => e.map((e) => Protein(e, GlobalKey())).toList())
        .toList();
    slideController = TransformationController();
  }

  final TransformationController _transformationController =
      TransformationController();
  Animation<Matrix4> _animationReset;
  AnimationController _controllerReset;

  void _onAnimateReset() {
    _transformationController.value = _animationReset.value;
    if (!_controllerReset.isAnimating) {
      _animationReset.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset.reset();
    }
  }

  void _animateResetInitialize() {
    _controllerReset.reset();
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(_controllerReset);
    _animationReset.addListener(_onAnimateReset);
    _controllerReset.forward();
  }

// Stop a running reset to home transform animation.
  void _animateResetStop() {
    _controllerReset.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset.reset();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_controllerReset.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  @override
  void dispose() {
    _controllerReset.dispose();
    super.dispose();
  }

  void listener(PhotoViewControllerValue value) {
    setState(() {
      //scaleCopy = value.scale;
    });
  }

  PhotoViewController controller;
  TransformationController slideController;
  Image _image;
  bool _loading = true;

  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  String url;
  firebase_storage.Reference ref;

  initImage([String item = 'Diseases']) async {
    await Firebase.initializeApp();
    ref = storage.ref().child(item).child('outfile.txt');
    url = await ref.getDownloadURL();
    print('got download url' + url);
    // setState(() {
    // _image = Image.network(url);
    final downloadedData = await ref.getData();
    // print(Utf8Decoder().convert(downloadedData));
    String decoded = Utf8Decoder().convert(downloadedData);
    List<String> split = decoded.split('[');
    List<List<String>> diseaseData = [];
    split.asMap().forEach((key, value) {
      if (value.contains(']') && value.contains('-')) {
        diseaseData.add([
          value.substring(0, value.indexOf('-')),
          value.substring(value.indexOf('-') + 2)
        ]);
      }
    });
    print('looking for #' + diseaseData.length.toString());
    allDiseases.asMap().forEach((key, value) {
      diseaseData.asMap().forEach((k, data) {
        final String a = data[0].toUpperCase().replaceAll(' ', '');
        final String b = value.name.toUpperCase().replaceAll(" ", "");
        if (b.contains(a)) {
          print("found data for " + value.name);
          value.info = value.info + data[1];
        }
      });
    });

    // _image.image.resolve(ImageConfiguration()).addListener(
    //   ImageStreamListener(
    //     (info, call) {
    //       print('Networkimage is fully loaded and saved');
    //       setState(() {
    //         _loading = false;
    //       });
    //       // do something
    //     },
    //   ),
    // );
    // });
    setState(() {});
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
          title: Text(name),
          content: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlue),
                    borderRadius: BorderRadius.circular(15)),
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(child: Text(info)),
              ),
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

  Widget surfaceReceptors() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Text('EGFR'),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text('Epidermal Growth Factor'),
                Text('FGFR'),
                Text('VEGF'),
                Text('EGFR'),
                Transform.rotate(
                    angle: 180 * math.pi / 180,
                    child: Icon(
                      Icons.cleaning_services_sharp,
                      color: Colors.blue,
                    ))
              ],
            ),
          ),
          Expanded(
            child: Text('EGFR'),
          ),
          Expanded(
            child: Text('EGFR'),
          ),
          Expanded(
            child: Text('EGFR'),
          ),
        ],
      ),
    );
  }

  Widget enzymes() {
    List<Widget> a = [];
    List<Widget> b = [];

    allProteins.asMap().forEach((num, pathway) {
      a.add(Column(
        children: [
          Container(
            width: 100,
          )
        ],
      ));
      List<Widget> colStuff = [];
      pathway.asMap().forEach((key, value) {
        String name = 'No name';
        String info = 'No info';
        Widget diseaseState = Container();
        allDiseases.asMap().forEach((n, disease) {
          if (value.name.toUpperCase().contains(disease.gene.toUpperCase())) {
            name = disease.name;
            info = disease.info;
            print(name + ' {} ' + info + '\\' + disease.gene.toUpperCase());
            diseaseState = GestureDetector(
              onTap: () => {_showDialog(context, name, info)},
              child: Container(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    name,
                    style: TextStyle(color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.orange,
                  )),
            );
          }
        });
        Widget vs = Container();
        if (value.name.contains(':')) {
          List<Widget> vbox = [];
          List<String> variants =
              value.name.substring(value.name.indexOf(':') + 1).split('/');
          variants.asMap().forEach((v, variant) {
            vbox.add(Container(
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.lightBlueAccent,
                ),
                child: Text(
                  variant,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ));
          });
          vs = (Column(
            children: vbox,
          ));
        }

        Widget medicationState = Container();
        allMedications.asMap().forEach((n, medication) {
          if (value.name
              .toUpperCase()
              .contains(medication.gene.toUpperCase())) {
            String mname = medication.name;
            String minfo = medication.info;
            medicationState = GestureDetector(
              onTap: () => {_showDialog(context, mname, minfo)},
              child: Container(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    mname,
                    style: TextStyle(color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.lightGreen,
                  )),
            );
          }
        });

        Widget main = Container();
        if (true) {
          main = Container(
            key: value.key,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.lightBlue,
            ),
            child: Text(
              value.name.contains(':')
                  ? value.name.substring(0, value.name.indexOf(':'))
                  : value.name,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          );
        } else {
          main = Row(
            children: [
              Icon(
                Icons.arrow_left,
                color: Colors.red,
              ),
              Icon(Icons.stop_circle_outlined, color: Colors.red),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.red,
                ),
                child: Text(
                  value.name.contains(':')
                      ? value.name.substring(0, value.name.indexOf(':'))
                      : value.name,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              diseaseState
            ],
          );
        }
        colStuff.add(Container(
          child: Row(
            children: [vs, main, diseaseState, medicationState],
          ),
        ));
        if (key < pathway.length - 1) {
          colStuff.add(Container(
            child: Icon(
              Icons.arrow_downward_outlined,
              color: Colors.green,
            ),
          ));
        }
      });
      Column col = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: colStuff,
      );
      if (pathway[0].name.toUpperCase().contains(",NUCLEAR")) {
        b.add(col);
      } else {
        a.add(col);
      }
    });

    Widget nucleus = Container(
      padding: EdgeInsets.all(50),
      child: Container(
        padding: EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withAlpha(50),
          border: Border.all(width: 10, color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: b,
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: a,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        nucleus
      ],
    );
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
        title: Text("Very SKINteresting"),
      ),
      drawer: Drawer(
        child: ListView(
          children: drawerItems,
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(width: 2)),
                child: InteractiveViewer(
                  panEnabled: true, // Set it to false to prevent panning.
                  boundaryMargin: EdgeInsets.all(80),
                  constrained: true,
                  minScale: 0.5,
                  maxScale: 10,
                  clipBehavior: Clip.none,
                  onInteractionStart: _onInteractionStart,
                  onInteractionEnd: (ScaleEndDetails) => {
                    //print(_transformationController.value),
                  },
                  transformationController: _transformationController,

                  child: Column(
                    children: [
                      Expanded(
                        child: Container(),
                      ),
                      Container(
                        child: surfaceReceptors(),
                      ),
                      Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.pink, width: 5),
                              borderRadius: BorderRadius.circular(40),
                              color: Colors.pink.withAlpha(50)),
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Stack(
                              children: [
                                enzymes(),
                              ],
                            ),
                          )),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
        onPressed: () => {_animateResetInitialize()},
        tooltip: 'Increment',
        child: Icon(Icons.fullscreen),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
