import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class WebGlLoaderObj extends StatefulWidget {
  final String fileName;
  const WebGlLoaderObj({Key? key, required this.fileName}) : super(key: key);

  @override
  State<WebGlLoaderObj> createState() => _MyAppState();
}

class _MyAppState extends State<WebGlLoaderObj> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Camera camera1;
  late three.Camera camera2;
  late three.Mesh mesh;
  Map<String, three.Mesh> meshMap = {};

  three.Vector2 clickedPoint = three.Vector2(double.infinity, double.infinity);
  three.Raycaster raycaster = three.Raycaster();
  bool isAF = true;
  bool isUnLock = true;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D bodyObject;
  //物距调节环
  late three.Object3D regulatingRingObject;
  //光圈调节环
  late three.Object3D apertureRingObject;

  //AF/MF
  late three.Object3D aFOrMfButtonObject;
  //lock
  late three.Object3D lockButtonObject;

  //Fn1
  late three.Object3D fn1ButtonObject;
  //Fn2
  late three.Object3D fn2ButtonObject;

  late three.Texture texture;

  late three.WebGLRenderTarget renderTarget;

  num sale = 0.75;

  num bodyRotationY = 0;

  dynamic sourceTexture;

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();

  three_jsm.DomLikeListenableState get domElement => _globalKey.currentState!;

  late three_jsm.OrbitControls controls;

  late three_jsm.OrbitControls controls1;

  late three_jsm.OrbitControls controls2;

  late three_jsm.DragControls apertureRingControls;

  // three.Raycaster raycaster = three.Raycaster();
  three.Object3D? intersected;
  bool didClick = false;
  three.Vector2 mousePosition = three.Vector2();
  double movePosition = 0;

  @override
  void initState() {
    super.initState();
  }

  void onMouseDown(event) {
    print(" onMouseDown .............${event.clientX}");
    didClick = true;
    mousePosition.x = event.clientX;
    mousePosition.y = event.clientY;
    render();
  }

  void onMouseUp(event) {
    print(" onMouseUp .............${event.clientX}");
    didClick = false;
    mousePosition.x = event.clientX;
    mousePosition.y = event.clientY;
    // render();
  }

  double rotate = 0.1;
  void onMouseMove(event) {
    // pointer.x = (event.clientX / width) * 2 - 1;
    // pointer.y = -(event.clientY / height) * 2 + 1;

    if (didClick && intersected != null) {
      rotate = 0.1;
      if (movePosition > event.clientX) {
        rotate = -0.1;
        print('-------------');
      }

      // setState(() {
      //   intersected!.rotation.y += rotate;
      // });
    } else {
      print(event);
      mousePosition.x = event.clientX;
      mousePosition.y = event.clientY;
    }
    movePosition = event.clientX;
    render();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
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
          return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          rotateLeft();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
                key: _globalKey,
                builder: (context) {
                  return Container(
                      width: width,
                      height: height,
                      color: Colors.red,
                      child: Builder(builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(
                                  viewType: three3dRender.textureId!.toString())
                              : Container();
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container();
                        }
                      }));
                }),
          ],
        ),
      ],
    );
  }

  render() {
    int t = DateTime.now().millisecondsSinceEpoch;

    final gl = three3dRender.gl;

    checkIntersection();

    renderer!.render(scene, camera);

    int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${t1 - t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
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

  // double objSale = 0.0225;
  double objSale = 0.5;
  initPage() async {
    three.Group();
    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.z = 200; //200 , sale 0.5

    // scene

    scene = three.Scene();
    scene.background = three.Color(0xff363636);
    scene.fog = three.FogExp2(0xffffffff, 0.002);

    // _oldLight();
    _newLight();

    // texture

    // var textureLoader = three.TextureLoader(null);
    // textureLoader.flipY = true;
    // texture =
    //     await textureLoader.loadAsync('assets/objs/uv_grid_directx.jpg', null);

    // texture.magFilter = three.LinearFilter;
    // texture.minFilter = three.LinearMipmapLinearFilter;
    // texture.generateMipmaps = true;
    // texture.needsUpdate = true;
    // texture.flipY = true; // this flipY is only for web

    // controls

    // controls = three_jsm.OrbitControls(camera, _globalKey);

    // controls.enableDamping =
    //     true; // an animation loop is required when either damping or auto-rotation are enabled
    // controls.dampingFactor = 0.05;

    // controls.screenSpacePanning = false;
    // controls.maxZoom = 1;
    // controls.minZoom = 0.5;
    // controls.enableZoom = false;
    // controls.enabled = true;

    // controls.minDistance = 10;
    // controls.maxDistance = 1000;

    // // controls.minPolarAngle = 0.0;
    // controls.maxPolarAngle = three.Math.pi * 0.5;

    // controls.addEventListener('change', (event) {
    //   print('change==========${event.direction}');
    //   render();
    // });

    var manager = three.LoadingManager();

    var mtlLoader = three_jsm.MTLLoader(manager);

    bodyObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_body');
    scene.add(bodyObject);
    // object.traverse((child) {
    //   if (child is three.Mesh) {
    //     child.material.map = texture;
    //   }
    // });

    bodyObject.scale.set(objSale, objSale, objSale);
    bodyObject.rotateY(bodyRotationY);

    ///物距调节环
    regulatingRingObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_2');
    regulatingRingObject.scale.set(objSale, objSale, objSale);
    regulatingRingObject.position.set(-0.25, 7.5, 0); //-0.25
    scene.add(regulatingRingObject);
    meshMap
        .addAll({'Distance': regulatingRingObject.children.last as three.Mesh});
    _focusCenter();
    // var position =
    //     regulatingRingObject.getWorldPosition(regulatingRingObject.position);

    // print(
    //     'regulatingRingObject=======${position.x}-${position.y}-${position.z}');

    ///光圈调节环
    apertureRingObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_3');

    scene.add(apertureRingObject);
    apertureRingObject.scale.set(objSale, objSale, objSale);
    // apertureRingObject.position.set(21.58, 6.31, 0);
    // apertureRingObject.position.set(20, 6.31, 0);
    meshMap
        .addAll({'Aperture': apertureRingObject.children.first as three.Mesh});
    _apertureCenter();
    // var translationMatrix = three.Matrix4().makeTranslation(
    //     42,
    //     0, //-40,
    //     0);
    // apertureRingObject.applyMatrix4(translationMatrix);

    ///Fn1
    fn1ButtonObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_key_2');
    scene.add(fn1ButtonObject);
    fn1ButtonObject.scale.set(objSale, objSale, objSale);
    meshMap.addAll({'FN1': fn1ButtonObject.children.last as three.Mesh});

    ///Fn2
    fn2ButtonObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_key_1');
    scene.add(fn2ButtonObject);
    fn2ButtonObject.scale.set(objSale, objSale, objSale);
    meshMap.addAll({'FN2': fn2ButtonObject.children.last as three.Mesh});

    ///AF/MF
    aFOrMfButtonObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_key_3');
    scene.add(aFOrMfButtonObject);
    aFOrMfButtonObject.scale.set(objSale, objSale, objSale);
    meshMap.addAll({'AF': aFOrMfButtonObject.children.last as three.Mesh});

    // meshList.add(three.Mesh(three.BoxGeometry(5, 5, 5),
    //     three.MeshLambertMaterial({"color": 0xff00ff}))
    //   ..translateZ(20)
    //   ..translateY(-0.5));
    // scene.add(meshList[1]);

    ///lock
    lockButtonObject =
        await _createObject3D(manager, mtlLoader, objName: 'ase022_E_key_4');
    scene.add(lockButtonObject);
    lockButtonObject.scale.set(objSale, objSale, objSale);
    lockButtonObject.translateY(-0.52);
    lockButtonObject.rotateY(three.Math.pi * 0.02);
    meshMap.addAll({'Lock': lockButtonObject.children.last as three.Mesh});

    // apertureRingControls = three_jsm.ArcballControls(camera, _globalKey);
    // apertureRingControls.addEventListener('wheel', () {
    //   print('wheel=-=-=-=-=-=');
    // });
    var imageLoader = three.TextureLoader(null);
    var backImage = await imageLoader.loadAsync(
      'assets/obj/male02/primary_bg.png',
    );
    scene.background = backImage;

    animate();
  }

  void _newLight() {
    // var ambientLight = three.AmbientLight(0xffffffff, 1);
    // scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight.position.set(0, 0, 210);
    scene.add(pointLight);

    var dirLight1 = three.DirectionalLight(0xffffffff);
    dirLight1.position.set(0, 1, 210);
    scene.add(dirLight1);

    var dirLight2 = three.DirectionalLight(0xffffffff);
    dirLight2.position.set(0, 0, 210);
    scene.add(dirLight2);

    var dirLight3 = three.DirectionalLight(0xffffffff);
    dirLight3.position.set(5, 1, 210);
    scene.add(dirLight3);

    var dirLight4 = three.DirectionalLight(0xffffffff);
    dirLight4.position.set(-5, 0, 210);
    scene.add(dirLight4);

    // var dirLight5 = three.DirectionalLight(0xffffffff);
    // dirLight5.position.set(-5, 0, 200);
    // scene.add(dirLight5);

    var hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.set(2, 0, 210);
    scene.add(hemiLight);

    var hemiLight1 = three.HemisphereLight(0xffffffff, 0xff444444);
    hemiLight1.position.set(-2, 0, 210);
    scene.add(hemiLight1);
  }

  void _focusCenter() {
    var foundFocusGeometry = false;
    var focusCenter = three.Vector3();
    regulatingRingObject.traverse((child) {
      if (child is three.Mesh) {
        three.Mesh ms = child;
        if (ms.geometry != null && foundFocusGeometry == false) {
          var geometry = child.geometry!;
          geometry.computeBoundingBox();
          geometry.boundingBox!.getCenter(focusCenter);
          geometry.center();
          foundFocusGeometry = true;
        }
      }
    });
    regulatingRingObject.position.set(0.05, 27.5, 0);
  }

  void _apertureCenter() {
    var center = three.Vector3();
    var foundGeometry = false;
    apertureRingObject.traverse((child) {
      if (child is three.Mesh) {
        three.Mesh ms = child;
        if (ms.geometry != null && foundGeometry == false) {
          var geometry = child.geometry!;
          geometry.computeBoundingBox();
          geometry.boundingBox!.getCenter(center);
          geometry.center();
          foundGeometry = true;
        }
      }
    });
    // apertureRingObject.position.set(0.5, 2, 0.5);
    apertureRingObject.children.first.position.set(0.5, 4, 0.5);
    // apertureRingObject.children[apertureRingObject.children.length - 2].position
    //     .set(21.58, 6.31, 0);
  }

  void rotateAboutPoint(
      three.Object3D obj, three.Vector3 point, three.Vector3 axis, double theta,
      [bool pointIsWorld = false]) {
    if (pointIsWorld) {
      obj.parent!.localToWorld(obj.position); // compensate for world coordinate
    }

    obj.position.sub(point); // remove the offset
    obj.position.applyAxisAngle(axis, theta); // rotate the POSITION
    obj.position.add(point); // re-add the offset

    if (pointIsWorld) {
      obj.parent!
          .worldToLocal(obj.position); // undo world coordinates compensation
    }

    obj.rotateOnAxis(axis, theta); // rotate the OBJECT
  }

  void _oldLight() {
    var ambientLight = three.AmbientLight(0xffffffff, 1);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight.position.set(0, 10, 5);
    scene.add(pointLight);

    var dirLight1 = three.DirectionalLight(0xffffffff);
    dirLight1.position.set(1, 1, 5);
    scene.add(dirLight1);

    var dirLight2 = three.DirectionalLight(0xffffffff);
    dirLight2.position.set(-1, -1, -5);
    scene.add(dirLight2);

    var dirLight3 = three.DirectionalLight(0xffffffff);
    dirLight3.position.set(0, 10, 5);
    scene.add(dirLight3);

    var pointLight1 = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight1.position.set(0, 10, 15);
    camera.add(pointLight1);
    scene.add(camera);

    var pointLight2 = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight2.position.set(0, 20, 15);
    camera.add(pointLight2);
    scene.add(camera);

    var pointLight3 = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight3.position.set(0, 30, 15);
    camera.add(pointLight3);
    scene.add(camera);

    var pointLight4 = three.PointLight(0xffffffff, 1, 1, 0);
    pointLight4.position.set(0, 40, 15);
    camera.add(pointLight4);
    scene.add(camera);

    var hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.set(0, 20, 0);
    scene.add(hemiLight);

    var hemiLight1 = three.HemisphereLight(0xffffffff, 0xff444444);
    hemiLight1.position.set(0, 0, 15);
    scene.add(hemiLight1);
  }

  Future<three.Object3D> _createObject3D(
      three.LoadingManager manager, three_jsm.MTLLoader mtlLoader,
      {String? path, required String objName}) async {
    var mtlLoader = three_jsm.MTLLoader(manager);
    mtlLoader.setPath(path ?? 'assets/obj/lens/');
    var materials = await mtlLoader.loadAsync('$objName.mtl');
    await materials.preload();

    var loader = three_jsm.OBJLoader(null);
    loader.setMaterials(materials);

    return await loader.loadAsync('${path ?? 'assets/obj/lens/'}$objName.obj');
  }

  void rotateLeft() {
    bodyRotationY = three.Math.pi * 0.5;
    bodyObject.rotateY(bodyRotationY);
    regulatingRingObject.rotateY(bodyRotationY);
    // apertureRingObject.rotateY(bodyRotationY);
    fn1ButtonObject.rotateY(bodyRotationY);
    fn2ButtonObject.rotateY(bodyRotationY);
    aFOrMfButtonObject.rotateY(bodyRotationY);
    lockButtonObject.rotateY(bodyRotationY);
    render();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    // Future.delayed(Duration(milliseconds: 40), () {
    //   animate();
    // });
  }

  void checkIntersection() {
    three.Vector2 convertPosition(three.Vector2 location) {
      Offset offset = Offset(0, 0); // screen position
      double x = (location.x / (width - offset.dx)) * 2 - 1;
      double y = -(location.y / (height - offset.dy)) * 2 + 1;
      return three.Vector2(x, y);
    }

    //one
    raycaster.setFromCamera(convertPosition(mousePosition), camera);
    List<three.Intersection> intersects =
        raycaster.intersectObject(meshMap['AF'] as three.Mesh, false);
    _raycasterListen(intersects);

    //two
    List<three.Intersection> intersects1 =
        raycaster.intersectObject(meshMap['Lock'] as three.Mesh, false);
    _raycasterListen(intersects1);
    //3
    List<three.Intersection> intersects2 =
        raycaster.intersectObject(meshMap['FN1'] as three.Mesh, false);
    _raycasterListen(intersects2);
    //4
    List<three.Intersection> intersects3 =
        raycaster.intersectObject(meshMap['FN2'] as three.Mesh, false);
    _raycasterListen(intersects3);
    //5
    List<three.Intersection> intersects4 =
        raycaster.intersectObject(meshMap['Distance'] as three.Mesh, false);
    _raycasterListen(intersects4);
    //6
    List<three.Intersection> intersects5 =
        raycaster.intersectObject(meshMap['Aperture'] as three.Mesh, false);
    _raycasterListen(intersects5);
  }

  void _raycasterListen(List<three.Intersection> intersects, {int index = 0}) {
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
      print("intersects: ${intersects.length} ");
      if (intersected != intersects.first.object) {
        print(
            "intersects=====${intersects.first.object.id}:${aFOrMfButtonObject.children.last.id}");
        if (intersects.first.object.id == aFOrMfButtonObject.children.last.id) {
          print('点击了AF和MF按钮');
          isAF = !isAF;
          aFOrMfButtonObject.translateY(isAF ? 1 : -1);
        }
        if (intersects.first.object.id == lockButtonObject.children.last.id) {
          print('点击了lock按钮');
          isUnLock = !isUnLock;
          lockButtonObject.translateY(isUnLock ? 1.1 : -1.1);
        }
        if (intersects.first.object.id == fn1ButtonObject.children.last.id) {
          print('点击了fn1按钮');

          fn1ButtonObject.translateZ(0.05);
          Future.delayed(const Duration(milliseconds: 200), () {
            fn1ButtonObject.translateZ(-0.05);
          });
        }
        if (intersects.first.object.id == fn2ButtonObject.children.last.id) {
          print('点击了fn2按钮');
          fn2ButtonObject.translateZ(0.05);
          Future.delayed(const Duration(milliseconds: 200), () {
            fn2ButtonObject.translateZ(-0.05);
          });
        }
        if (intersects.first.object.id ==
            regulatingRingObject.children.last.id) {
          print('滚动物距');
          // fn2ButtonObject.translateZ(0.05);
          // Future.delayed(const Duration(milliseconds: 200), () {
          //   fn2ButtonObject.translateZ(-0.05);
          // });
          regulatingRingObject.rotateY(rotate);
          // rotateAboutPoint(regulatingRingObject, three.Vector3(0, 0, 0),
          //     three.Vector3(0, 1, 0), rotate, true);
        }
        if (intersects.first.object.id ==
            apertureRingObject.children.first.id) {
          print('滚动光圈');
          // fn2ButtonObject.translateZ(0.05);
          // Future.delayed(const Duration(milliseconds: 200), () {
          //   fn2ButtonObject.translateZ(-0.05);
          // });
          apertureRingObject.rotateY(rotate);
          // rotateAboutPoint(apertureRingObject, three.Vector3(0, 0, 0),
          //     three.Vector3(0, 1, 0), rotate);
          // apertureRingObject.rotateOnAxis(three.Vector3(0, 1, 1), 3.14);
        }
        if (intersected != null) {
          // materialEmmisivity(0);
        }
        intersected = intersects.first.object;
        // materialEmmisivity(0.55);
      }
    } else if (intersected != null) {
      materialEmmisivity(0);
      intersected = null;
    }
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
