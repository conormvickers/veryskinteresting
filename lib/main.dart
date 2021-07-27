import 'dart:convert';
import 'dart:html';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:math' as math;
import 'package:dotted_border/dotted_border.dart';
import 'package:arrow_path/arrow_path.dart';

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
  Medication("Vismodegib", "SMO ", ""),
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

List<List<String>> strings = [
  ["G-Protein CP:GNAQ/GNAS,new", "Adenylate Cyclase", "cAMP", "PKA"],
  [
    "Tyrosine Kinase,new",
    "PTPNII",
    "SHP2 SOS",
    "RAS:HRAS/NRAS/KRAS",
    "BRAF",
    "MEK",
    "ERK",
  ],
  ["Neurofibromin,suppressor,spacer3", "Spred1,suppressor"],
  ["Tyrosine Kinase,new", "PI3K", "AKT", "mtor"],
  [
    "PTEN Merlin,suppressor,spacer1",
    "Hamartin Tuberin,suppressor",
    "Folliculin,suppressor"
  ],
  ["SMO ,new", "GLI"],
  ["PTCH,suppressor"],
  ["TNF-a,new", "NEMO", "IkB - NFkB - p50"],
  ["CYLD,suppressor,spacer1"],
  ["Wnt,new", 'Frizzled', 'beta catenin'],
  ['APC,suppressor,spacer2'],
  ["Cyclins,nuclear", 'Cell Cycle progression'],
  ["Slow cycle:p57/p16,suppressor,nuclear", "BAP,nuclear,suppressor"],
  ["CDKN2A,nuclear", "p14", "MDA2", 'P53,suppressor'],
  [
    "Inducers:Cigarrette Smoke/Rifampin/Phenytoin/Phenobarbitol,endo,new",
    "1A2,font80"
  ],
  [
    "Substrates:Floroquinolones/Macrolides except Azithro/Warfarin/Caffeine,endo,suppressor,spacer1.7"
  ],
  ["Inducers:Rifampin/Carbamezapine,endo,new", "2C9,font80"],
  ["Substrates:Phenytoin/Fluconazole,endo,suppressor,spacer1.5"],
  ["Inducers:Rifampin/Carbamezapine/Phenytoin,endo,new", "2D6,font80"],
  [
    "Substrates:Metoprolol/Terbinafine/SSRI/TCA/Doxepin,endo,suppressor,spacer1.5"
  ],
  ["Inducers:Rifampin/Carbamezapine/Phenytoin,endo,new", "3A4,font80"],
  [
    "Substrates:Warfarin/Statin/'azole' aintifungals/Antihistamines/Tacrolimus/Cyclosporin,endo,suppressor,spacer1"
  ],
  [
    "Calcium Response,nuclear,new",
    "CREBBP",
    "p63",
    "Telomere Repair",
    "DNA coils"
  ]
];

List<List<Protein>> allProteins = [[]];

class ProfileCardPainter extends CustomPainter {
  ProfileCardPainter({@required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // allProteins.asMap().forEach((numberOfPath, pathway) {
    //   List<Offset> points = [];
    //   pathway.asMap().forEach((key, value) {
    //     GlobalKey gkey = value.key;
    //     final b = (gkey.currentContext.findRenderObject() as RenderBox)
    //         .getTransformTo(gkey.currentContext.findRenderObject().parent)
    //         .getTranslation();
    //     final d = (gkey.currentContext.findRenderObject() as RenderBox).size;
    //     var hOffset = 0.0;
    //     if (key.isEven) {
    //       hOffset = d.height;
    //     }
    //     Offset box = Offset(b.x + (d.width / 2), b.y + hOffset);
    //     points.add(box);
    //   });
    //   points.asMap().forEach((n, point) {
    //     if (n > 0 && n < points.length) {
    //       final p1 = point;
    //       final p2 = points[n - 1];
    //       final paint = Paint()
    //         ..color = Colors.pink
    //         ..strokeWidth = 4;
    //       canvas.drawLine(p1, p2, paint);
    //     }
    //   });
    final p1 = Offset(0, 0);
    final p2 = Offset(500, 500);
    final paint = Paint()
      ..color = Colors.pink
      ..strokeWidth = 4;
    canvas.drawLine(p1, p2, paint);
  }
  // });

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
    List<Widget> c = [];

    allProteins.asMap().forEach((num, pathway) {
      List<Widget> colStuff = [];
      pathway.asMap().forEach((key, value) {
        String name = 'No name';
        String info = 'No info';
        Widget diseaseState = Container();
        allDiseases.asMap().forEach((n, disease) {
          if (value.name.toUpperCase().contains(disease.gene.toUpperCase())) {
            name = disease.name;
            info = disease.info;
            // print(name + ' {} ' + info + '\\' + disease.gene.toUpperCase());
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
          List<String> commas = value.name.split(',');
          String name = value.name;
          if (commas.length > 1) {
            name = commas[0];
          }
          List<Widget> vbox = [];
          List<String> variants =
              name.substring(name.indexOf(':') + 1).split('/');
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
        String unsplit = value.name;
        List<String> commas = unsplit.split(',');
        bool oncoOrNah = true;
        String title = value.name;
        if (commas.length > 1) {
          title = commas[0];
        }
        double font;
        commas.forEach((element) {
          if (element.toUpperCase().contains("SUPPRESSOR")) {
            oncoOrNah = false;
          }
          if (element.toUpperCase().contains("FONT")) {
            double a = double.parse(element.substring(4));
            font = a;
          }
          if (element.toUpperCase().contains("SPACER")) {
            double a = double.parse(element.substring(6));
            colStuff.add(Container(
              height: 75 * a,
            ));
          }
        });
        if (oncoOrNah) {
          main = Container(
            key: value.key,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.lightBlue,
            ),
            child: Text(
              title.contains(':')
                  ? title.substring(0, title.indexOf(':'))
                  : title,
              style: TextStyle(color: Colors.white, fontSize: font ?? 20),
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
                  title.contains(':')
                      ? title.substring(0, title.indexOf(':'))
                      : title,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          );
        }
        colStuff.add(Container(
          child: Row(
            children: [main, vs, diseaseState, medicationState],
          ),
        ));
        if (key < pathway.length - 1) {
          if (oncoOrNah) {
            colStuff.add(
              Container(
                height: 10,
                width: 100,
              ),
            );
            colStuff.add(
              Container(
                height: 40,
                width: 100,
                child: CustomPaint(
                  painter: ArrowPainter(true),
                ),
              ),
            );
            colStuff.add(
              Container(
                height: 10,
                width: 100,
              ),
            );
          } else {
            colStuff.add(Container(
              height: 20,
            ));
          }
        }
      });
      Column col = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: colStuff,
      );

      if (pathway[0].name.toUpperCase().contains(",NUCLEAR")) {
        if (pathway[0].name.toUpperCase().contains(",NEW")) {
          b.add(Container(
            width: 100,
          ));
        }
        b.add(col);
      } else if (pathway[0].name.toUpperCase().contains(",ENDO")) {
        if (pathway[0].name.toUpperCase().contains(",NEW")) {
          c.add(Container(
            width: 100,
          ));
        }
        c.add(col);
      } else {
        if (pathway[0].name.toUpperCase().contains(",NEW")) {
          a.add(Container(
            width: 100,
          ));
        }
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

    List<Widget> prettyEndo = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: c,
      ),
    ];
    if (c.length > 2) {
      prettyEndo = [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: c.sublist(0, c.length ~/ 2),
        ),
        Container(
          height: 100,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: c.sublist(c.length ~/ 2),
        ),
      ];
    }
    Widget endo = Container(
      padding: EdgeInsets.all(50),
      child: DottedBorder(
        color: Colors.purpleAccent,
        strokeWidth: 10,
        dashPattern: [10, 30],
        child: Column(children: prettyEndo),
        padding: EdgeInsets.all(50),
      ),
    );

    return Column(
      children: [
        Row(
          children: a,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        Row(
          children: [nucleus, endo],
        )
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => {_animateResetInitialize()},
        tooltip: 'Increment',
        child: Icon(Icons.fullscreen),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class InhibitPainter extends CustomPainter {
  InhibitPainter(this.upDown);
  bool upDown = false;
  @override
  void paint(Canvas canvas, Size size) {
    TextSpan textSpan;
    TextPainter textPainter;
    Path path;

    // The arrows usually looks better with rounded caps.
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    /// Draw a single arrow.s
    path = Path();
    if (upDown) {
      path.moveTo(size.width * 0.5, 0);
      path.relativeLineTo(size.width * 0.5, size.height);
    } else {
      path.moveTo(0, size.height * 0.50);
      path.relativeLineTo(size.width, size.height * 0.5);
    }

    path = ArrowPath.make(path: path);
    canvas.drawPath(path, paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => true;
}

class ArrowPainter extends CustomPainter {
  ArrowPainter(this.upDown);
  bool upDown = false;
  @override
  void paint(Canvas canvas, Size size) {
    TextSpan textSpan;
    TextPainter textPainter;
    Path path;

    // The arrows usually looks better with rounded caps.
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    /// Draw a single arrow.s
    path = Path();
    if (upDown) {
      path.moveTo(size.width * 0.5, 0);
      path.relativeCubicTo(
          0, 0, size.width * 0.25, size.height / 4, 0, size.height);
    } else {
      path.moveTo(0, size.height * 0.50);
      path.relativeCubicTo(
          0, 0, size.width * 0.25, size.height / 4, size.width, 0);
    }

    path = ArrowPath.make(path: path);
    canvas.drawPath(path, paint..color = Colors.blue);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => true;
}
