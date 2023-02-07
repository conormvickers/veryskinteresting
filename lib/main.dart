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
        primarySwatch: Colors.indigo,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  Protein(this.positions, this.size, this.name, this.data, this.type,
      this.interactions, this.zoomLevel, this.above);
  List<Offset> positions;
  Size size;
  String name;
  String data;
  String type;
  List<List<String>> interactions;
  double zoomLevel;
  bool above;

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
  @override
  void initState() {
    super.initState();
    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    proteins.add(Protein(
        [
          Offset(290, 300),
          Offset(290, 300),
          Offset(390, 620),
        ],
        Size(80, 80),
        "Glucocorticoid Receptor",
        "Binds ligand in the cytosol then enters nucleas to affect gene transcription.",
        "enzyme",
        [
          ["Inflammatory Signals", "negative", "2", "2"],
        ],
        2,
        false));
    proteins.add(Protein(
        [
          Offset(300, 300),
          Offset(300, 300),
          Offset(400, 620),
        ],
        Size(40, 40),
        "GC Receptor",
        "Binds ligand in the cytosol then enters nucleas to affect gene transcription.",
        "enzyme",
        [
          ["IkB", "positive", "2", "2"],
          ["NFkB", "negative", "2", "2"]
        ],
        2,
        true));
    proteins.add(Protein(
        [Offset(800, 520)],
        Size(20, 20),
        "Inflammatory Signals",
        "Many pro-inflammatory signals.",
        "ligand",
        [],
        2,
        false));
    proteins.add(Protein(
        [
          Offset(10, 50),
        ],
        Size(80, 80),
        "Cortisol-Binding Globulin",
        "Typically 90% of protein bound. Free fraction is affected by CBG production. Conditions such as hypothyroidism and liver disease will reduce CBG and increase free fraction. Pregnancy and estrogen therapy will have the oppositae effect.",
        "enzyme",
        [],
        2,
        false));

    proteins.add(Protein(
        [
          Offset(0, 120),
        ],
        Size(40, 40),
        "CBG",
        "Typically 90% of protein bound. Free fraction is affected by CBG production. Conditions such as hypothyroidism and liver disease will reduce CBG and increase free fraction. Pregnancy and estrogen therapy will have the oppositae effect.",
        "enzyme",
        [],
        2,
        true));
    proteins.add(Protein(
        [Offset(110, 9.5)],
        Size(40, 40),
        "CBG",
        "Typically 90% of protein bound. Free fraction is affected by CBG production. Conditions such as hypothyroidism and liver disease will reduce CBG and increase free fraction. Pregnancy and estrogen therapy will have the oppositae effect.",
        "enzyme",
        [],
        2,
        true));
    proteins.add(Protein(
        [Offset(37, 54.5), Offset(316.5, 304.0), Offset(414.6, 622.7)],
        Size(10, 10),
        "Glucocorticoid",
        "Antiinflammatory steroid molecule",
        "ligand",
        [],
        2,
        true));
    proteins.add(Protein(
        [Offset(37, 54.5), Offset(316.5, 304.0), Offset(414.6, 622.7)],
        Size(20, 20),
        "Glucocorticoid",
        "Antiinflammatory steroid molecule",
        "ligand",
        [],
        2,
        false));
    proteins.add(Protein(
        [Offset(16.2, 123.8)], Size(10, 10), "", "", "ligand", [], 2, true));
    proteins.add(Protein(
        [Offset(125, 13.7)], Size(10, 10), "", "", "ligand", [], 2, true));
    proteins.add(Protein(
        [Offset(444.0, 750.0)],
        Size(20, 10),
        "IkB",
        "Binds to NFkB and inhibits its effects on transcription.",
        "ligand",
        [
          ["NFkB", "negative", "2", "2"]
        ],
        2,
        true));
    proteins.add(Protein(
        [Offset(500.0, 750.0)],
        Size(20, 10),
        "NFkB",
        "Produces a wide range of inflammatory cytokines.",
        "ligand",
        [
          ["IL-1", "negative", "2", "2"],
          ["TNFa", "negative", "2", "2"],
          ["IL-1", "positive", "0", "1"],
          ["TNFa", "positive", "0", "1"],
        ],
        2,
        true));
    proteins.add(Protein([Offset(745.4, 634.4)], Size(10, 10), "IL-1",
        "inflammatory cytokines.", "ligand", [], 2, true));
    proteins.add(Protein([Offset(745.4, 670.4)], Size(10, 10), "TNFa",
        "inflammatory cytokines.", "ligand", [], 2, true));

    List<int> lengths = proteins.map((e) => e.positions.length).toList();
    maxEnz = lengths.reduce(max) - 1;

    updateDrawer();

    pullProteins();
  }

  pullProteins() async {
    final responseRaw = await http.get(Uri.parse(
        "https://script.google.com/macros/s/AKfycbxuRCm1kiDeAXN72ZCQYV1N_eVU2APDramMiPq6Ab2hQlHqEmXOEgZx-jKCKUhy1XC6/exec"));
    final list = jsonDecode(responseRaw.body) as List<dynamic>;
    Map<String, List<dynamic>> proteinMaster = {};
    list.forEach((element) {
      proteinMaster[element[0]] = element;
    });
    int columnIndex = 0;
    proteinMaster.keys.toList().forEach((element) {
      if (element.length > 1) {
        proteins.add(Protein(
            [Offset(200 + (40 * columnIndex.toDouble()), 200)],
            Size(10, 10),
            proteinMaster[element]![0],
            proteinMaster[element]![8],
            proteinMaster[element]![7],
            [],
            0,
            true));
        columnIndex++;
      }
    });
    setState(() {});
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

  Widget nucleus() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      top: 780,
      left: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            child: CustomPaint(
              painter: DnaPainter(),
              child: Container(),
            ),
          ),
          Text("DNA")
        ],
      ),
    );
  }

  List<List<Offset>> enzymeLocations = [
    [
      Offset(300, 300),
      Offset(300, 300),
      Offset(400, 620),
    ],
    [
      Offset(20, 50),
    ]
  ];
  List<List<Offset>> ligandLocations = [
    [
      Offset(100, 20),
      Offset(315, 305),
      Offset(415, 625),
    ],
    [Offset(400, 725)],
    [Offset(500, 725)],
    [Offset(800, 745)],
    [Offset(830, 725)],
    [
      Offset(35, 55),
    ]
  ];
  List<String> enzymeNames = [
    "Glucocorticoid Receptor",
    "Cortisol-Binding Globulin"
  ];
  List<String> ligandNames = [
    "Glucocorticoid",
    "IkB",
    "NFkB",
    "IL-1",
    "TNFa",
    "Glucocorticoid (bound)"
  ];

  List<Size> ligandSize = [
    Size(10, 10),
    Size(30, 30),
    Size(30, 30),
    Size(10, 10),
    Size(10, 10),
    Size(10, 10),
    Size(10, 10),
  ];
  List<Size> enzymeSize = [
    Size(40, 40),
    Size(40, 40),
    Size(40, 40),
    Size(40, 40),
  ];

  List<Widget> enzymes() {
    List<Widget> rr = [];

    final zoom = _transformationController.value[0];

    proteins.forEach((protein) {
      final top = getSafePosition(protein.positions, enzPosIndex).dy;
      final left = getSafePosition(protein.positions, enzPosIndex).dx;
      final zoomOK = (zoom > protein.zoomLevel && protein.above) ||
          (zoom < protein.zoomLevel && !protein.above);

      rr.add(AnimatedPositioned(
        top: top,
        left: left,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: (zoomOK)
            ? CustomPaint(
                painter: painterShapes.containsKey(protein.type)
                    ? painterShapes[protein.type]
                    : LigandPainter(),
                child: Container(
                  width: protein.size.width,
                  height: protein.size.height,
                ),
              )
            : Container(),
      ));
    });

    return rr;
  }

  final painterShapes = {"ligand": LigandPainter(), "enzyme": EnzymePainter()};

  List<Widget> ligands() {
    List<Widget> rr = [];

    ligandNames.asMap().forEach((key, value) {
      var top = 0.0;
      var left = 0.0;
      if (enzPosIndex >= ligandLocations[key].length - 1) {
        top = ligandLocations[key].last.dy;
        left = ligandLocations[key].last.dx;
      } else {
        top = ligandLocations[key][enzPosIndex].dy;
        left = ligandLocations[key][enzPosIndex].dx;
      }

      rr.add(AnimatedPositioned(
        top: top,
        left: left,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: CustomPaint(
          painter: LigandPainter(),
          child: Container(
            width: ligandSize[key].width,
            height: ligandSize[key].height,
          ),
        ),
      ));
    });

    return rr;
  }

  // List<List<String>> interactions = [
  //   ["Glucocorticoid Receptor", "IkB", "positive", "2", "2"],
  //   ["Glucocorticoid Receptor", "NFkB", "negative", "2", "2"],
  //   ["IkB", "NFkB", "negative", "2", "2"],
  //   ["NFkB", "IL-1", "negative", "2", "2"],
  //   ["NFkB", "TNFa", "negative", "2", "2"],
  //   ["NFkB", "IL-1", "positive", "0", "1"],
  //   ["NFkB", "TNFa", "positive", "0", "1"]
  // ];
  List<Widget> arrows() {
    List<Widget> rr = [];

    List<String> allNames = proteins.map((e) => e.name).toList();
    print(allNames);

    // return rr;
    final zoom = _transformationController.value[0];

    proteins.asMap().forEach((key, protein) {
      if (protein.interactions.length > 0) {
        protein.interactions.asMap().forEach((ikey, ii) {
          final bprotein = proteins[allNames.indexOf(ii[0])];
          final stop = bprotein.getPosition();
          final start = protein.getPosition();

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
            rr.add(AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: CustomPaint(
                painter: ArrowPainter(
                    start +
                        Offset(protein.size.width / 2, protein.size.height / 2),
                    stop +
                        Offset(
                            bprotein.size.width / 2, bprotein.size.height / 2)),
                child: Container(),
              ),
            ));
          } else {
            rr.add(AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: CustomPaint(
                painter: InhibitPainter(
                    start +
                        Offset(protein.size.width / 2, protein.size.height / 2),
                    stop +
                        Offset(
                            bprotein.size.width / 2, bprotein.size.height / 2)),
                child: Container(),
              ),
            ));
          }
        });
      }
    });

    // interactions.asMap().forEach((key, value) {
    //   final a = value[0];
    //   final b = value[1];
    //   final c = value[2];
    //   final si = int.parse(value[3]);
    //   final sti = int.parse(value[4]);

    //   bool show = false;
    //   if (enzPosIndex >= si && enzPosIndex <= sti) {
    //     show = true;
    //   }

    //   Offset start;
    //   Size startBuff = Size(0, 0);
    //   Offset stop;
    //   Size stopBuff = Size(0, 0);

    //   if (ligandNames.contains(a)) {
    //     if (enzPosIndex <= ligandLocations[ligandNames.indexOf(a)].length - 1) {
    //       start = ligandLocations[ligandNames.indexOf(a)][enzPosIndex];
    //     } else {
    //       start = ligandLocations[ligandNames.indexOf(a)].last;
    //     }
    //     startBuff = ligandSize[ligandNames.indexOf(a)] / 2;
    //   } else if (enzymeNames.contains(a)) {
    //     if (enzPosIndex <= enzymeLocations[enzymeNames.indexOf(a)].length - 1) {
    //       start = enzymeLocations[enzymeNames.indexOf(a)][enzPosIndex];
    //     } else {
    //       start = enzymeLocations[enzymeNames.indexOf(a)].last;
    //     }
    //     startBuff = enzymeSize[enzymeNames.indexOf(a)] / 2;
    //   }

    //   if (ligandNames.contains(b)) {
    //     if (enzPosIndex <= ligandLocations[ligandNames.indexOf(b)].length - 1) {
    //       stop = ligandLocations[ligandNames.indexOf(b)][enzPosIndex];
    //     } else {
    //       stop = ligandLocations[ligandNames.indexOf(b)].last;
    //     }
    //     stopBuff = ligandSize[ligandNames.indexOf(b)] / 2;
    //   } else if (enzymeNames.contains(b)) {
    //     if (enzPosIndex <= enzymeLocations[enzymeNames.indexOf(b)].length - 1) {
    //       stop = enzymeLocations[enzymeNames.indexOf(b)][enzPosIndex];
    //     } else {
    //       stop = enzymeLocations[enzymeNames.indexOf(b)].last;
    //     }
    //     stopBuff = enzymeSize[enzymeNames.indexOf(b)] / 2;
    //   }

    //   if (c == 'positive') {
    //     rr.add(AnimatedOpacity(
    //       opacity: show ? 1 : 0,
    //       duration: Duration(milliseconds: 300),
    //       curve: Curves.easeInOut,
    //       child: CustomPaint(
    //         painter: ArrowPainter(
    //             start + Offset(startBuff.width, startBuff.height),
    //             stop + Offset(stopBuff.width, stopBuff.height)),
    //         child: Container(),
    //       ),
    //     ));
    //   } else {
    //     rr.add(AnimatedOpacity(
    //       opacity: show ? 1 : 0,
    //       duration: Duration(milliseconds: 300),
    //       curve: Curves.easeInOut,
    //       child: CustomPaint(
    //         painter: InhibitPainter(
    //             start + Offset(startBuff.width, startBuff.height),
    //             stop + Offset(stopBuff.width, stopBuff.height)),
    //         child: Container(),
    //       ),
    //     ));
    //   }
    // });

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
                print(_transformationController.value[0]);
                if (!zoomedInBool) {
                  if (_transformationController.value[0] > 2) {
                    print("zoom changed");
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
                  Column(
                    children: [Expanded(child: Container())],
                  ),
                  Row(
                    children: [Expanded(child: Container())],
                  ),
                  Center(
                    child: FittedBox(
                      child: Container(
                        width: 1000,
                        height: 1000,
                        child: GestureDetector(
                          onTapUp: (d) {
                            print(d.localPosition);
                            final zoom = _transformationController.value[0];
                            proteins.asMap().forEach(
                              (key, protein) {
                                final zoomOK = (zoom > protein.zoomLevel &&
                                        protein.above) ||
                                    (zoom < protein.zoomLevel &&
                                        !protein.above);
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
                              cellMembrane(),
                              nucleus(),
                              ...enzymes(),
                              ...arrows(),
                              ...labels()
                            ],
                          ),
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

      // Center(
      //   child: Column(
      //     children: [
      //       Expanded(
      //         child: Container(
      //           decoration: BoxDecoration(border: Border.all(width: 2)),
      //           child: InteractiveViewer(
      //             panEnabled: true, // Set it to false to prevent panning.
      //             boundaryMargin: EdgeInsets.all(80),
      //             constrained: true,
      //             minScale: 0.5,
      //             maxScale: 10,
      //             clipBehavior: Clip.none,
      //             onInteractionStart: _onInteractionStart,
      //             onInteractionEnd: (ScaleEndDetails) => {
      //               //print(_transformationController.value),
      //             },
      //             transformationController: _transformationController,

      //             child: Column(
      //               children: [
      //                 Container(
      //                   child: surfaceReceptors(),
      //                 ),
      //                 Container(
      //                     decoration: BoxDecoration(
      //                         border: Border.all(color: Colors.pink, width: 5),
      //                         borderRadius: BorderRadius.circular(40),
      //                         color: Colors.pink.withAlpha(50)),
      //                     child: FittedBox(
      //                       fit: BoxFit.fitWidth,
      //                       child: Stack(
      //                         children: [
      //                           enzymes(),
      //                           Container(
      //                             width: 500,
      //                             height: 500,
      //                             child: DirectGraph(
      //                               list: list,
      //                               cellWidth: 136.0,
      //                               cellPadding: 24.0,
      //                               orientation: MatrixOrientation.Vertical,
      //                             ),
      //                           ),
      //                         ],
      //                       ),
      //                     )),
      //                 Expanded(
      //                   child: Container(),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
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

    final dx = stop.dx - start.dx;
    final dy = stop.dy - start.dy;

    final angle = math.atan(dy / dx);

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

    final dx = stop.dx - start.dx;
    final dy = stop.dy - start.dy;

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

    canvas.drawArc(Rect.fromLTRB(0, 0, size.width, size.height), 0, 2 * math.pi,
        false, mempaint);

    final Paint nuclearPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    final midX = size.width / 2;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height - 300),
            width: 400,
            height: 400),
        0,
        2 * math.pi,
        false,
        nuclearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
