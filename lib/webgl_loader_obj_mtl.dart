import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class WebGlLoaderObjLtl extends StatefulWidget {
  final String fileName;
  const WebGlLoaderObjLtl({Key? key, required this.fileName}) : super(key: key);

  @override
  State<WebGlLoaderObjLtl> createState() => _MyAppState();
}

class _MyAppState extends State<WebGlLoaderObjLtl> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;

  double dpr = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object;

  late three.Texture texture;

  late three.WebGLMultisampleRenderTarget renderTarget;

  dynamic sourceTexture;

  @override
  void initState() {
    super.initState();
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
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
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
                })),
          ],
        ),
      ],
    );
  }

  render() {
    int t = DateTime.now().millisecondsSinceEpoch;

    final gl = three3dRender.gl;

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
      renderTarget = three.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    camera = three.PerspectiveCamera(45, width / height, 1, 2000);
    camera.position.z = 250;

    // scene
    scene = three.Scene();
    scene.background = new three.Color(0x3c3c3c);

    var ambientLight = three.AmbientLight(0xcccccc, 1);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.8);
    pointLight.position.set(0, 0, 5);
    camera.add(pointLight);
    scene.add(camera);

    // texture
    var manager = three.LoadingManager();

    var mtlLoader = three_jsm.MTLLoader(manager);
    mtlLoader.setPath('assets/obj/lens/');
    var materials = await mtlLoader.loadAsync('ase022_E_body.mtl');
    await materials.preload();

    var loader = three_jsm.OBJLoader(null);
    loader.setMaterials(materials);
    object = await loader.loadAsync('assets/obj/lens/ase022_E_body.obj');

    // var textureLoader = three.TextureLoader(null);
    // textureLoader.flipY = true;
    // texture = await textureLoader.loadAsync(
    //     'assets/obj/male02/uv_grid_directx.jpg', null);

    // texture.magFilter = three.LinearFilter;
    // texture.minFilter = three.LinearMipmapLinearFilter;
    // texture.generateMipmaps = true;
    // texture.needsUpdate = true;
    // texture.flipY = true;

    // var plane = three.PlaneGeometry(100, 100);
    // mesh = three.Mesh(plane, three.MeshPhongMaterial({"map": texture}));
    // scene.add(mesh);

    object.scale.set(0.5, 0.5, 0.5);
    // object.setRotationFromAxisAngle(
    //     three.Vector3(1, 0, 0), -90 * three.Math.pi);
    object.position.set(-0.5, -0.65, 0);
    // object.rotation.set(0, 10, 0);
    scene.add(object);

    animate();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
