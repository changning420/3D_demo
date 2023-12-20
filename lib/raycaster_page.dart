import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as jsm;

class RaycasterPage extends StatefulWidget {
  final String fileName;
  const RaycasterPage({Key? key, required this.fileName}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<RaycasterPage> {
  final GlobalKey<jsm.DomLikeListenableState> _globalKey =
      GlobalKey<jsm.DomLikeListenableState>();
  jsm.DomLikeListenableState get domElement => _globalKey.currentState!;
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late List<three.Mesh> mesh = [];
  late three.Mesh singleMesh;

  three.Raycaster raycaster = three.Raycaster();
  three.Object3D? intersected;
  bool didClick = false;
  three.Vector2 mousePosition = three.Vector2();
  double movePosition = 0;

  double dpr = 1.0;

  bool disposed = false;

  late three.Texture texture;

  late three.WebGLRenderTarget renderTarget;

  dynamic? sourceTexture;

  bool loaded = false;

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }

  void onMouseDown(event) {
    print(" onMouseDown .............${event.clientX}");
    didClick = true;
  }

  void onMouseUp(event) {
    print(" onMouseUp .............${event.clientX}");
    didClick = false;
  }

  void onMouseMove(event) {
    pointer.x = (event.clientX / width) * 2 - 1;
    pointer.y = -(event.clientY / height) * 2 + 1;

    if (didClick && intersected != null) {
      double rotate = 0.05;
      if (movePosition > event.clientX) {
        rotate = -0.05;
      }

      setState(() {
        intersected!.rotation.y += rotate;
      });
    } else {
      print(event);
      mousePosition.x = event.clientX;
      mousePosition.y = event.clientY;
    }
    movePosition = event.clientX;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = width;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    print("three3dRender.initialize _options: $_options ");

    await three3dRender.initialize(options: _options);

    print(
        "three3dRender.initialize three3dRender: ${three3dRender.textureId} ");

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 200), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  void initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  void initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };

    print('initRenderer  dpr: $dpr _options: $_options');

    renderer = three.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);

      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initScene() {
    domElement.addEventListener('pointerdown', onMouseDown, false);
    domElement.addEventListener('pointermove', onMouseMove, false);
    domElement.addEventListener('mousemove', onMouseMove, false);
    domElement.addEventListener('pointerup', onMouseUp, false);
    initRenderer();
    initPage();
  }

  void initPage() {
    var ASPECTRATIO = width / height;

    var WIDTH = width * dpr;
    var HEIGHT = height * dpr;

    List<three.Camera> cameras = [];

    var subcamera = three.PerspectiveCamera(40, ASPECTRATIO, 0.1, 10);
    subcamera.viewport =
        three.Vector4(0, 0, three.Math.ceil(WIDTH), three.Math.ceil(HEIGHT));
    subcamera.position.x = -0.5;
    subcamera.position.y = 0.5;
    subcamera.position.z = 1.5;
    subcamera.position.multiplyScalar(2);
    subcamera.lookAt(three.Vector3(0, 0, 0));
    subcamera.updateMatrixWorld(false);
    cameras.add(subcamera);

    camera = three.ArrayCamera(cameras);
    // camera = new three.PerspectiveCamera(45, width / height, 1, 10);
    camera.position.z = 3;

    scene = three.Scene();

    var ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);

    camera.lookAt(scene.position);

    var light = three.DirectionalLight(0xffffff, null);
    light.position.set(0.5, 0.5, 1);
    light.castShadow = true;
    light.shadow!.camera!.zoom = 4; // tighter shadow map
    scene.add(light);

    var geometryBackground = three.PlaneGeometry(100, 100);
    var materialBackground = three.MeshPhongMaterial({"color": 0x000066});

    var background = three.Mesh(geometryBackground, materialBackground);
    background.receiveShadow = true;
    background.position.set(0, 0, -1);
    scene.add(background);

    mesh.add(three.Mesh(three.BoxGeometry(0.5, 0.5, 0.5),
        three.MeshPhongMaterial({"color": 0xff0000}))
      ..translateY(0.5));
    mesh.add(three.Mesh(three.BoxGeometry(0.5, 0.5, 0.5),
        three.MeshPhongMaterial({"color": 0x00ff00}))
      ..translateY(1));
    mesh.add(three.Mesh(three.BoxGeometry(0.5, 0.5, 0.5),
        three.MeshPhongMaterial({"color": 0x0000ff})));
    singleMesh = three.Mesh(three.BoxGeometry(0.5, 0.5, 0.5),
        three.MeshPhongMaterial({"color": 0x006606}))
      ..translateY(-0.5);
    mesh.add(singleMesh);
    scene.add(mesh[0]);
    scene.add(mesh[1]);
    scene.add(mesh[2]);
    scene.add(mesh[3]);
    loaded = true;
    animate();
  }

  void checkIntersection() {
    three.Vector2 convertPosition(three.Vector2 location) {
      Offset offset = Offset(0, 0); // screen position
      double x = (location.x / (width - offset.dx)) * 2 - 1;
      double y = -(location.y / (height - offset.dy)) * 2 + 1;
      return three.Vector2(x, y);
    }

    raycaster.setFromCamera(convertPosition(mousePosition), camera);
    bool isRaycaster = false;
    for (int i = 0; i < scene.children.length; i++) {
      if (scene.children[i] == mesh[0] ||
          scene.children[i] == mesh[1] ||
          scene.children[i] == mesh[2] ||
          scene.children[i] == mesh[3]) {
        isRaycaster = true;
      }
    }
    if (isRaycaster == false) {
      return;
    }
    List<three.Intersection> intersects =
        raycaster.intersectObject(mesh[3], false);
    void materialEmmisivity(double emmisive) {
      three.Material mat = intersected!.material!;
      List<String> split = mat.name.split('|');
      if (split.length > 1 && split[1] == 'g') {
        if (emmisive == 0) {
          mat.emissive!.r = .5;
          mat.emissive!.g = .5;
          mat.emissive!.b = .5;
        } else {
          mat.emissive!.r = 1;
          mat.emissive!.g = 1;
          mat.emissive!.b = 1;
        }
      } else {
        mat.emissive!.r = emmisive;
        mat.emissive!.g = emmisive;
        mat.emissive!.b = emmisive;
      }
    }

    if (intersects.isNotEmpty) {
      if (intersected != intersects.first.object) {
        if (intersected != null) {
          materialEmmisivity(0);
        }
        intersected = intersects.first.object;
        materialEmmisivity(0.55);
      }
    } else if (intersected != null) {
      materialEmmisivity(0);
      intersected = null;
    }
  }

  var INTERSECTED;
  double theta = 0;

  var pointer = three.Vector2();
  var radius = 5;
  void checkClick() {
    // theta += 0.1;

    // camera.position.x =
    //     radius * three.Math.sin(three.MathUtils.degToRad(theta));
    // camera.position.y =
    //     radius * three.Math.sin(three.MathUtils.degToRad(theta));
    // camera.position.z =
    //     radius * three.Math.cos(three.MathUtils.degToRad(theta));
    // camera.lookAt(scene.position);

    // camera.updateMatrixWorld();

    // find intersections
    raycaster.setFromCamera(pointer, camera);

    List intersects = raycaster.intersectObjects(scene.children, false);

    if (intersects.isNotEmpty) {
      if (INTERSECTED != intersects[0].object) {
        INTERSECTED = intersects[0].object;
        print('=========');
      }
    } else {
      INTERSECTED = null;
    }
  }

  void render() {
    final _gl = three3dRender.gl;
    renderer!.render(scene, camera);
    _gl.finish();
    checkClick();
    // checkIntersection();
    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  void animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          animate();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: jsm.DomLikeListenable(
              key: _globalKey,
              builder: (BuildContext context) {
                return Container(
                    width: width,
                    height: height,
                    color: Colors.red,
                    child: Builder(builder: (BuildContext context) {
                      if (kIsWeb) {
                        return three3dRender.isInitialized
                            ? HtmlElementView(
                                viewType: three3dRender.textureId!.toString())
                            : Container(
                                color: Colors.red,
                              );
                      } else {
                        return three3dRender.isInitialized
                            ? Texture(textureId: three3dRender.textureId!)
                            : Container(color: Colors.red);
                      }
                    }));
              }),
        ),
      ],
    );
  }
}
