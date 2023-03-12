import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:graphite/core/matrix.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:math' as math;
import 'package:arrow_path/arrow_path.dart';
import 'package:http/http.dart' as http;

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
        primaryColor: Colors.grey,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage() : super();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Protein {
  Protein(
      this.positions,
      this.size,
      this.name,
      this.data,
      this.shape,
      this.celllocation,
      this.interactions,
      this.zoomLevel,
      this.above,
      this.key);
  List<Offset> positions;
  Size size;
  String name;
  String data;
  String shape;
  String celllocation;
  List<List<String>> interactions;
  double zoomLevel;
  bool above;
  GlobalKey key;

  Offset getPosition() {
    if (positions.length - 1 <= enzPosIndex) {
      return positions.last;
    }
    return positions[enzPosIndex];
  }
}

int enzPosIndex = 0;
int maxEnz = 0;

String rawDatas = """

[--]

""";

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<Widget> postframeArrows = [];

  AnimationController? animationController;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    animation =
        CurveTween(curve: Curves.fastOutSlowIn).animate(animationController!);

    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    updateDrawer();

    pullProteins();
  }

  List<List<List<Protein>>> pathways = [];
  List<int> proteinBreaks = [];
  pullProteins() async {
    final responseRaw = await http.get(Uri.parse(
        "https://script.google.com/macros/s/AKfycbxuRCm1kiDeAXN72ZCQYV1N_eVU2APDramMiPq6Ab2hQlHqEmXOEgZx-jKCKUhy1XC6/exec"));
    final list = jsonDecode(responseRaw.body) as List<dynamic>;
    List<dynamic> proteinMaster = [];
    proteinBreaks = [];
    list.forEach((element) {
      proteinMaster.add(element);
    });
    int columnIndex = 0;
    int rowVar = 0;
    int rowIndex = 0;
    int sameRow = 0;
    pathways = [];
    proteinMaster.forEach((element) {
      if (element[0] == "") {
        pathways.add([]);
        proteinBreaks.add(proteins.length);
      } else {
        rowVar = (rowVar + 7) % 25;
        if (element[0] != "Protein") {
          if (element[2] == "membrane") {
            columnIndex++;
            rowIndex = 0;
          }
          List<List<String>> interactions = [];
          if ((element[4] as String).length > 1) {
            final afters = (element[4] as String).split(",");
            final effects = (element[5] as String).split(",");
            afters.asMap().forEach((num, element) {
              interactions.add([element.trim(), effects[num].trim(), "0", "0"]);
            });
          }

          var name = (element[0] as String).trim();
          if (name.startsWith("-")) {
            name = name.substring(1);
            sameRow = sameRow + 40;
          } else if (name.startsWith("^")) {
            name = name.substring(1);
            sameRow = -60;
          } else {
            sameRow = 0;
            rowIndex++;
          }
          var off = Offset(sameRow + 100 * columnIndex.toDouble() + rowVar,
              60 * rowIndex.toDouble());
          if (element == "DNA") {
            off = Offset(400, 780);
          }
          double aa = 10;
          if ((element[8] is int)) {
            aa = element[8];
          }
          final toadd = Protein(
              [off],
              Size(aa, aa),
              name,
              (element[9] as String).trim(),
              (element[7] as String).trim(),
              (element[2] as String).trim(),
              interactions,
              0,
              true,
              GlobalKey());
          proteins.add(toadd);
          if (toadd.name == "SUFU") {
            print("here");
          }
          if ((element[0] as String).startsWith("-")) {
            pathways.last.last.add(toadd);
          } else if ((element[0] as String).startsWith("^")) {
            pathways.last.last.insert(0, toadd);
          } else {
            pathways.last.add([toadd]);
          }
        }
      }
    });
    spreadOutProteins();
  }

  List<Protein> proteins = [];

  final TransformationController _transformationController =
      TransformationController();
  late Animation<Matrix4> _animationReset;
  late AnimationController _controllerReset;

  void _onAnimateReset() {
    _transformationController.value = _animationReset.value;
    if (!_controllerReset.isAnimating) {
      _animationReset.removeListener(_onAnimateReset);
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
    _animationReset.removeListener(_onAnimateReset);
    _controllerReset.reset();
  }

  @override
  void dispose() {
    _controllerReset.dispose();
    super.dispose();
  }

  List<Widget> drawerItems = [];

  updateDrawer() {
    setState(() {});
  }

  List<List<String>> info = [
    [
      "Cortisol-Binding Globulin",
      """
Transports cortisol throughout blood stream. 
      Levels will affect the free fraction of corticosteroids avaliable to exert their effect on cells. 
      Hypothyroidism, liver disease, renal disease, obesity will all reduce the production of CBG and increase free fraction. 
      Estrogen therapy, pregnancy, hyperthyroidism will increase CBG and decrease free fraction
      """
    ],
    [
      "Glucocorticoid Receptor",
      "Binds ligand in cytosol then transports to nucleus"
    ]
  ];

  Widget cellMembrane() {
    return Container(
      child: CustomPaint(
        painter: MembranePainter(),
        child: Container(),
      ),
    );
  }

  var zoomPath = 0;
  Widget enzymes() {
    List<Widget> rowsofareas = [];

    List<Widget> rowsextracell = [];
    List<Widget> rowmembrane = [];
    List<Widget> rowcytosol = [];
    List<Widget> rowdna = [];
    List<Widget> bottom = [];

    int pathwayIndex = 0;
    pathways.forEach((rowsofproteins) {
      List<Widget> colsextracell = [];
      List<Widget> colmembrane = [];
      List<Widget> colcytosol = [];
      List<Widget> coldna = [];

      pathwayIndex++;
      int nnew = pathwayIndex;

      rowsofproteins.forEach((proteinlist) {
        List<Widget> thisrow = [];
        proteinlist.forEach((protein) {
          final top = getSafePosition(protein.positions, enzPosIndex).dy;
          final left = getSafePosition(protein.positions, enzPosIndex).dx;
          final zoomOK = true;
          // (zoom > protein.zoomLevel && protein.above) ||
          //     (zoom < protein.zoomLevel && !protein.above);

          Widget label = Container();

          if (protein.name.length > 0) {
            label = (AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              top: 0,
              left: 0,
              child: (zoomOK)
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(15)),
                      child: Text(protein.name))
                  : Container(),
            ));
          }

          thisrow.add(GestureDetector(
            onTap: () {
              setState(() {
                zoomPath = nnew;
                print(zoomPath);
                updateArrows();
              });
            },
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  child: Container(
                    // width: protein.size.width,
                    // height: protein.size.height,
                    // AnimatedPositioned(
                    // top: top,
                    // left: left,
                    //duration: Duration(milliseconds: 300),
                    // curve: Curves.easeInOut,

                    key: protein.key,

                    child: (zoomOK)
                        ? CustomPaint(
                            painter: painterShapes.containsKey(protein.shape)
                                ? painterShapes[protein.shape]
                                : LigandPainter(),
                            child: Container(
                              width: protein.size.width,
                              height: protein.size.height,
                            ),
                          )
                        : Container(),
                  ),
                ),
                label
              ],
            ),
          ));
        });
        if (proteinlist.first.name == "DNA") {
          bottom.add(Row(children: thisrow));
        } else if (proteinlist.first.celllocation == "extracellular") {
          colsextracell.add(Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: thisrow,
          ));
        } else if (proteinlist.first.celllocation == "membrane") {
          colmembrane.add(Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: thisrow,
          ));
        } else if (proteinlist.first.celllocation == "cytosol") {
          colcytosol.add(Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: thisrow,
          ));
        } else if (proteinlist.first.celllocation == "nucleus") {
          coldna.add(Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: thisrow,
          ));
        }
      });
      var flexy = 1;
      if (pathwayIndex == zoomPath) {
        flexy = 3;
      }
      // if (colsextracell.length > 0) {
      rowsextracell.add(Expanded(
          flex: flexy,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: colsextracell)));
      // }
      // if (colmembrane.length > 0) {
      rowmembrane.add(Expanded(
          flex: flexy,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: colmembrane)));
      // }
      // if (colcytosol.length > 0) {
      rowcytosol.add(Expanded(
          flex: flexy,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: colcytosol)));
      // }
      // if (coldna.length > 0) {
      rowdna.add(Expanded(
          flex: flexy,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: coldna)));
      // }
    });
    return Column(children: [
      Expanded(
          child: Row(mainAxisSize: MainAxisSize.max, children: rowsextracell)),
      Container(
          child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.amber)),
              height: 5,
              child: Row(children: [Expanded(child: Container())]),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.max, children: rowmembrane),
        ],
      )),
      Expanded(
          child: Row(mainAxisSize: MainAxisSize.max, children: rowcytosol)),
      Expanded(
        child: Stack(
          children: [
            Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.deepPurple)),
              height: 5,
              child: Row(children: [Expanded(child: Container())]),
            ),
            Row(mainAxisSize: MainAxisSize.max, children: rowdna),
          ],
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: bottom)
    ]);
  }

  final painterShapes = {
    "ligand": LigandPainter(),
    "enzyme": EnzymePainter(),
    "dna": DnaPainter(),
    "transmembrane": TransMembranePainter(),
    "surface": SurfacePainter(),
    "channel": ChannelPainter()
  };

  List<Widget> arrows() {
    List<Widget> rr = [];

    List<String> allNames = proteins.map((e) => e.name).toList();

    final zoom = _transformationController.value[0];

    final box = interactiveKey.currentContext!.findRenderObject() as RenderBox;
    final boxOffset = box.localToGlobal(Offset.zero);

    proteins.asMap().forEach((key, protein) {
      if (protein.interactions.length > 0) {
        protein.interactions.asMap().forEach((ikey, ii) {
          final bprotein = proteins[allNames.indexOf(ii[0])];
          print(protein.name + " to " + bprotein.name);

          final renderBox =
              protein.key.currentContext!.findRenderObject() as RenderBox;
          final start = (renderBox.localToGlobal(Offset.zero) - boxOffset);

          final renderBoxb =
              bprotein.key.currentContext!.findRenderObject() as RenderBox;
          final stop = (renderBoxb.localToGlobal(Offset.zero) - boxOffset);

          final si = int.parse(ii[2]);
          final sti = int.parse(ii[3]);

          bool show = false;
          if (enzPosIndex >= si && enzPosIndex <= sti) {
            final zoomOK = (zoom > protein.zoomLevel && protein.above) ||
                (zoom < protein.zoomLevel && !protein.above);
            if (zoomOK) {
              show = true;
            }
          }

          if (ii[1] == 'positive') {
            rr.add(IgnorePointer(
              child: AnimatedOpacity(
                opacity: show ? 1 : 0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: CustomPaint(
                  painter: ArrowPainter(
                      start +
                          Offset(
                              protein.size.width / 2, protein.size.height / 2),
                      stop +
                          Offset(bprotein.size.width / 2,
                              bprotein.size.height / 2)),
                  child: Container(),
                ),
              ),
            ));
          } else {
            rr.add(IgnorePointer(
              child: AnimatedOpacity(
                opacity: show ? 1 : 0,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: CustomPaint(
                  painter: InhibitPainter(
                      start +
                          Offset(
                              protein.size.width / 2, protein.size.height / 2),
                      stop +
                          Offset(bprotein.size.width / 2,
                              bprotein.size.height / 2)),
                  child: Container(),
                ),
              ),
            ));
          }
        });
      }
    });

    return rr;
  }

  List<Widget> labels() {
    List<Widget> rr = [];

    final zoom = _transformationController.value[0];

    proteins.asMap().forEach((key, protein) {
      final zoomOK = (zoom > protein.zoomLevel && protein.above) ||
          (zoom < protein.zoomLevel && !protein.above);
      final location = getSafePosition(protein.positions, enzPosIndex);
      final size = protein.size;
      if (protein.name.length > 0) {
        rr.add(AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          top: location.dy + size.height + 5,
          left: location.dx,
          child: (zoomOK)
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(15)),
                  child: Text(protein.name))
              : Container(),
        ));
      }
    });

    return rr;
  }

  Offset getSafePosition(List<Offset> enzlig, int index) {
    if (enzlig.length - 1 <= index) {
      return enzlig.last;
    }
    return enzlig[index];
  }

  bool zoomedInBool = false;

  spreadOutProteins() {
    // double colwidth = 100;
    // var columnIndex = 0;
    // var pathHeight = 600;
    // pathways.forEach((element) {
    //   if (element.length > 0) {
    //     if (element.length < 3) {
    //       pathHeight = 200;
    //     } else {
    //       pathHeight = 600;
    //     }

    //     final heightPart = pathHeight / element.length;
    //     double currHeight = 90;

    //     element.forEach((proteinRow) {
    //       if (proteinRow.first.celllocation == "extracellular") {
    //         currHeight = 50;
    //       } else if (proteinRow.first.celllocation == "membrane") {
    //         currHeight = 90;
    //       } else if (proteinRow.first.celllocation == "nucleus") {
    //         currHeight = 850;
    //       } else {}

    //       int i = 1;
    //       var positions = [];
    //       if (proteinRow.length.isEven) {
    //         proteinRow.forEach((element) {
    //           positions.add(((i) / (proteinRow.length + 1)) * (colwidth));

    //           i++;
    //         });
    //       } else {
    //         proteinRow.forEach((element) {
    //           positions.add(colwidth / 2 +
    //               (i - (proteinRow.length / 2).ceil()) *
    //                   (colwidth / 2) /
    //                   (proteinRow.length));
    //           i++;
    //         });
    //       }
    //       i = 0;

    //       proteinRow.forEach((p) {
    //         var h = currHeight;
    //         if (p.celllocation != "membrane") {
    //           h = currHeight + i * 20;
    //         }
    //         p.positions.first =
    //             Offset(positions[i] + columnIndex * colwidth, h);
    //         i++;

    //         if (p.name == "DNA") {
    //           p.positions.first = Offset(400, 900);
    //         }
    //       });

    //       currHeight = currHeight + heightPart;
    //     });
    //     columnIndex++;
    //   }
    // });
    updateArrows();
    setState(() {});
    print("done set state");
  }

  updateArrows() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      postframeArrows = arrows();
      setState(() {});
    });
  }

  GlobalKey interactiveKey = GlobalKey();

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
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(80),
              constrained: true,
              minScale: 0.5,
              maxScale: 10,
              clipBehavior: Clip.none,
              onInteractionEnd: (details) {
                if (!zoomedInBool) {
                  if (_transformationController.value[0] > 2) {
                    zoomedInBool = true;
                    setState(() {});
                  }
                } else {
                  if (_transformationController.value[0] < 2) {
                    zoomedInBool = false;
                    setState(() {});
                  }
                }
              },
              transformationController: _transformationController,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      key: interactiveKey,
                      child: GestureDetector(
                        onTapUp: (d) {
                          final zoom = _transformationController.value[0];
                          proteins.asMap().forEach(
                            (key, protein) {
                              final zoomOK = (zoom > protein.zoomLevel &&
                                      protein.above) ||
                                  (zoom < protein.zoomLevel && !protein.above);
                              if (zoomOK && protein.data.length > 0) {
                                if (d.localPosition.dx >=
                                        protein.getPosition().dx &&
                                    d.localPosition.dx <
                                        protein.getPosition().dx +
                                            protein.size.width &&
                                    d.localPosition.dy >=
                                        protein.getPosition().dy &&
                                    d.localPosition.dy <
                                        protein.getPosition().dy +
                                            protein.size.height) {
                                  final data = protein.data;
                                  showMenu(
                                      context: context,
                                      position: RelativeRect.fromLTRB(
                                          d.globalPosition.dx,
                                          d.globalPosition.dy,
                                          d.globalPosition.dx,
                                          d.globalPosition.dy),
                                      items: [
                                        PopupMenuItem(
                                            enabled: false,
                                            child: Text(
                                              data,
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ))
                                      ]);
                                }
                              }
                            },
                          );
                        },
                        child: Stack(
                          children: [
                            // cellMembrane(),
                            // nucleus(),
                            // ...enzymes(),
                            enzymes(),
                            ...postframeArrows,
                            // ...labels()
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    _animateResetInitialize();
                  },
                  child: Icon(Icons.fullscreen),
                ),
                OutlinedButton(
                  onPressed: () {
                    // _animateResetInitialize();
                    if (enzPosIndex > 0) {
                      enzPosIndex--;
                    }
                    setState(() {});
                  },
                  child: Icon(Icons.skip_previous),
                ),
                OutlinedButton(
                  onPressed: () {
                    // _animateResetInitialize();
                    if (enzPosIndex < maxEnz) {
                      enzPosIndex++;
                    }
                    setState(() {});
                  },
                  child: Icon(Icons.skip_next),
                ),
                OutlinedButton(
                  onPressed: () {
                    enzPosIndex = 0;
                    setState(() {});
                  },
                  child: Icon(Icons.restart_alt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InhibitPainter extends CustomPainter {
  InhibitPainter(this.start, this.stop);
  Offset start = Offset(0, 0);
  Offset stop = Offset(100, 100);
  @override
  void paint(Canvas canvas, Size size) {
    Path path;

    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    var dx = stop.dx - start.dx;
    var dy = stop.dy - start.dy;

    final angle = math.atan(dy / dx);
    if (dx == 0) {
      dx = 1;
    }
    if (dy == 0) {
      dy = 1;
    }

    final sf = Offset(start.dx + 20 * dx.sign * cos(angle),
        start.dy + 20 * dx.sign * sin(angle));
    final sd = Offset(stop.dx - 20 * dx.sign * cos(angle),
        stop.dy - 20 * dx.sign * sin(angle));

    path = Path();

    path.moveTo(sf.dx, sf.dy);
    // path.relativeCubicTo(0, 0, start.dx, stop.dy, stop.dx, stop.dy);
    path.lineTo(sd.dx, sd.dy);

    final ap1 = Offset(sd.dx + dx.sign * cos(angle + pi * 1 / 2) * 10,
        sd.dy + dx.sign * sin(angle + pi * 1 / 2) * 10);
    final ap2 = Offset(sd.dx + dx.sign * cos(angle - pi * 1 / 2) * 10,
        sd.dy + dx.sign * sin(angle - pi * 1 / 2) * 10);

    path.lineTo(ap1.dx, ap1.dy);
    path.lineTo(sd.dx, sd.dy);
    path.lineTo(ap2.dx, ap2.dy);
    canvas.drawPath(path, paint..color = Colors.red);
  }

  @override
  bool shouldRepaint(InhibitPainter oldDelegate) => true;
}

class ArrowPainter extends CustomPainter {
  ArrowPainter(this.start, this.stop);
  Offset start = Offset(0, 0);
  Offset stop = Offset(100, 100);
  @override
  void paint(Canvas canvas, Size size) {
    Path path;

    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    var dx = stop.dx - start.dx;
    var dy = stop.dy - start.dy;

    if (dx == 0) {
      dx = 1;
    }
    if (dy == 0) {
      dy = 1;
    }

    final angle = math.atan(dy / dx);

    final sf = Offset(start.dx + 20 * dx.sign * cos(angle),
        start.dy + 20 * dx.sign * sin(angle));
    final sd = Offset(stop.dx - 20 * dx.sign * cos(angle),
        stop.dy - 20 * dx.sign * sin(angle));

    path = Path();

    path.moveTo(sf.dx, sf.dy);
    // path.relativeCubicTo(0, 0, start.dx, stop.dy, stop.dx, stop.dy);
    path.lineTo(sd.dx, sd.dy);

    final ap1 = Offset(sd.dx + dx.sign * cos(angle + pi * 5 / 6) * 10,
        sd.dy + dx.sign * sin(angle + pi * 5 / 6) * 10);
    final ap2 = Offset(sd.dx + dx.sign * cos(angle - pi * 5 / 6) * 10,
        sd.dy + dx.sign * sin(angle - pi * 5 / 6) * 10);

    path.lineTo(ap1.dx, ap1.dy);
    path.lineTo(sd.dx, sd.dy);
    path.lineTo(ap2.dx, ap2.dy);
    canvas.drawPath(path, paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => true;
}

class EnzymePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint mempaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    Path path = Path();
    path.moveTo((size.width / 2) + (size.width / 2) * math.cos(math.pi * 3 / 8),
        (size.height / 2) - (size.height / 2) * math.sin(math.pi * 3 / 8));

    path.addArc(Rect.fromLTRB(0, 0, size.width, size.height), -math.pi * 3 / 8,
        math.pi * 7 / 4);
    path.lineTo(size.width / 2 + math.cos(math.pi * 5 / 4) * size.width / 4,
        size.height / 4 - (size.height * math.cos(math.pi / 4) / 4));
    path.addArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 1 / 4),
            width: size.height / 2,
            height: size.height / 2),
        math.pi * 5 / 4,
        -math.pi * 3 / 2);
    path.lineTo((size.width / 2) + (size.width / 2) * math.cos(math.pi * 3 / 8),
        (size.height / 2) - (size.height / 2) * math.sin(math.pi * 3 / 8));

    canvas.drawPath(path, mempaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class LigandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint mempaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    canvas.drawArc(Rect.fromLTRB(0, 0, size.width, size.height), 0, 2 * math.pi,
        false, mempaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TransMembranePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dnaPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke;
    final shortside = 20.0;
    Path dnapath = Path();
    final longside = 30.0;
    var xoffset = 0.0;
    final step = size.width / 4;
    for (int i = 0; i < 3; i++) {
      if (i == 0) {
        dnapath.moveTo(xoffset, 0);
      } else {
        dnapath.moveTo(xoffset, size.height * 1 / 6);
      }

      dnapath.lineTo(0 + xoffset, size.height * 5 / 6);
      dnapath.addArc(
          Rect.fromCenter(
              center:
                  Offset(xoffset + size.width * 1 / 16, size.height * 5 / 6),
              width: size.width / 8,
              height: size.height / 8),
          pi,
          -pi);
      dnapath.moveTo(xoffset + step / 2, size.height * 5 / 6);
      dnapath.lineTo(xoffset + step / 2, size.height * 1 / 6);
      dnapath.addArc(
          Rect.fromCenter(
              center: Offset(xoffset + size.width * 1 / 16 + step / 2,
                  size.height * 1 / 6),
              width: size.width / 8,
              height: size.height / 8),
          pi,
          pi);
      xoffset = xoffset + step;
    }
    dnapath.moveTo(xoffset, size.height * 1 / 6);
    dnapath.lineTo(0 + xoffset, size.height);
    canvas.drawPath(dnapath, dnaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ChannelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dnaPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path = Path();
    final w = size.width;
    final h = size.height;
    path.addArc(Rect.fromLTWH(0.3 * w, 0, 0.1 * w, h), 0, 2 * pi);
    path.addArc(Rect.fromLTWH(0.7 * w, 0, 0.1 * w, h), 0, 2 * pi);
    canvas.drawPath(path, dnaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dnaPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..color = Colors.purple
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0.4 * w, 1 * h);
    path.lineTo(0.4 * w, 0.2 * h);
    path.lineTo(0.3 * w, 0);
    path.moveTo(0.6 * w, 1 * h);
    path.lineTo(0.6 * w, 0.2 * h);
    path.lineTo(0.7 * w, 0);
    canvas.drawPath(path, dnaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DnaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dnaPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.0;
    Path dnapath = Path();
    final longside = 30.0;
    final shortside = 20.0;
    for (int i = 0; i < 8; i++) {
      if (i == 0) {
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            -math.pi * 3 / 4, math.pi * 3 / 4);
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            math.pi * 3 / 4, -math.pi * 3 / 4);
      } else if (i == 7) {
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            math.pi, math.pi * 3 / 4);
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            math.pi, -math.pi * 3 / 4);
      } else {
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            math.pi, math.pi);
        dnapath.addArc(Rect.fromLTWH(i * longside, 0, longside, shortside),
            math.pi, -math.pi);
      }
      final x0 = i * longside;
      final y0 = shortside * 5 / 6;
      final y1 = shortside * 18 / 20;

      dnapath.moveTo(x0 + longside * 1 / 2, 0 + y1);
      dnapath.lineTo(x0 + longside * 1 / 2, shortside - y1);
      dnapath.moveTo(x0 + longside * 1 / 4, 0 + y0);
      dnapath.lineTo(x0 + longside * 1 / 4, shortside - y0);
      dnapath.moveTo(x0 + longside * 3 / 4, 0 + y0);
      dnapath.lineTo(x0 + longside * 3 / 4, shortside - y0);
    }
    canvas.drawPath(dnapath, dnaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MembranePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint mempaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6.0;

    canvas.drawLine(Offset(0, 100), Offset(1000, 100), mempaint);

    final Paint nuclearPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    final midX = size.width / 2;
    canvas.drawLine(Offset(0, 800), Offset(1000, 800), nuclearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
