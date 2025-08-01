import { GUIView } from "@/gui/guiView";
//* libs */
import Stats from "stats.js";
import gsap from "gsap";

//* shaders */
import cubeShader from "@/shaders/cube-shader.wgsl";
import singlePlaneShader from "@/shaders/plane-shader.wgsl";
import shader1 from "@/shaders/shader-1.wgsl";
import shader2 from "@/shaders/shader-2.wgsl";
import shader3 from "@/shaders/shader-3.wgsl";
import shader4 from "@/shaders/shader-4.wgsl";
import shader5 from "@/shaders/shader-5.wgsl";
import shader6 from "@/shaders/shader-6.wgsl";
import shader9 from "@/shaders/shader-9.wgsl";
import shader12 from "@/shaders/shader-12.wgsl";
import shaderRepo from "@/shaders/shader-update-repo.wgsl";

import { Sphere } from "@/gpulab/objects/spheres/sphere";
import sphereShader from "@/shaders/sphere-shader.wgsl";
import noiseSphereShader from "@/shaders/noise-sphere-shader.wgsl";

//* gpu lab */
import { Engine } from "@/gpulab/core/engine";
import { Scene } from "@/gpulab/core/scene";
import { CameraAxis } from "@/gpulab/core/types";

//* cubes
import { Cube } from "@/gpulab/objects/cubes/cube";

//* planes
import { Plane } from "@/gpulab/objects/planes/plane";

import { createTextureFromImage } from "@/gpulab/objects/planes/plane-utils";
import { vec3 } from "gl-matrix";
import { GLBModel } from "@/gpulab/objects/glb/glb-model";

export default class App {
  private stats!: ReturnType<typeof Stats>;
  private engine!: Engine;
  private scene!: Scene;
  private plane: Plane;
  private cube: Cube;
  private sphere: Sphere;
  private noiseSphere: Sphere;

  private rawMouse = { x: 0, y: 0 };
  private easedMouse = { x: 0, y: 0 };

  constructor() {}

  async init(canvas: HTMLCanvasElement): Promise<void> {
    var cameraInitPos: vec3 = [0, 0, 17];

    new GUIView(this, cameraInitPos);
    const datGUIRoot = document.querySelector(".tp-dfwv");
    if (datGUIRoot) {
      (datGUIRoot as HTMLElement).style.position = "fixed";
      (datGUIRoot as HTMLElement).style.top = "0px";
      (datGUIRoot as HTMLElement).style.right = "0px";
      (datGUIRoot as HTMLElement).style.zIndex = "889900998";
    }
    this.initStats();

    this.engine = new Engine({ canvas }, cameraInitPos);
    await this.engine.init();

    this.scene = new Scene(this.engine.getCamera());
    this.engine.setScene(this.scene);

    const device = this.engine.getDevice();
    const format = this.engine.getFormat();

    // this.testCubes(device, format);
    // this.testPlanes(device, format);
    this.testSpheres(device, format);

    this.setupListeners();
    this.startRendering();
  }

  private initStats(): void {
    this.stats = new Stats();
    this.stats.showPanel(0);

    const dom = this.stats.dom;
    dom.style.position = "fixed";
    dom.style.top = "0px";
    dom.style.left = "0px";
    dom.style.zIndex = "9999999";

    document.body.appendChild(this.stats.dom);
  }

  //* from gui
  public updateCameraAxis(axis: CameraAxis, value: number): void {
    const camera = this.engine.getCamera();
    const [x, y, z] = camera.getPosition();

    const newPos: [number, number, number] = [
      axis === "x" ? value : x,
      axis === "y" ? value : y,
      axis === "z" ? value : z,
    ];

    camera.setPosition(newPos);
    this.scene.updateCameraTransform();
    //@ts-ignore
    window.camera = camera;
  }

  public runPlanes() {
    this.scene.clear();
    const device = this.engine.getDevice();
    const format = this.engine.getFormat();

    this.testPlanes(device, format);
  }

  updateResolution = () => {
    const canvas = this.engine.getCanvas();
    const rect = canvas.getBoundingClientRect();
    const w = rect.width;
    const h = rect.height;
    if (this.plane) {
      this.plane.updateProps((p) => {
        p.params[1][0] = w;
        p.params[1][1] = h;
        p.params[1][2] = 0;
        p.params[1][3] = 0;
      });
    }
    // Add this block for the cube
    if (this.cube) {
      this.cube.updateProps((p) => {
        p.params[1][0] = w;
        p.params[1][1] = h;
        p.params[1][2] = 0;
        p.params[1][3] = 0;
      });
    }
    if (this.sphere) {
      this.sphere.updateProps((p) => {
        p.params[1][0] = w;
        p.params[1][1] = h;
        p.params[1][2] = 0;
        p.params[1][3] = 0;
      });
    }
  };

  private setupListeners(): void {
    const canvas = this.engine.getCanvas();

    // 1a) initial

    // 1b) on resize
    window.addEventListener("resize", () => {
      this.engine.resize();
      this.engine
        .getCamera()
        .setAspect(canvas.clientWidth / canvas.clientHeight);
      this.scene.updateCameraTransform();
      this.updateResolution();
    });

    this.updateResolution();

    // 2) pointermove in CSS space
    canvas.addEventListener("pointermove", (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left; // CSS px
      const y = e.clientY - rect.top; // CSS px

      this.rawMouse.x = e.clientX - rect.left;
      this.rawMouse.y = e.clientY - rect.top;

      // debug

      if (this.plane) {
        this.plane.updateProps((p) => {
          p.params[1][2] = x;
          p.params[1][3] = y;
        });
      }
      if (this.cube) {
        this.cube.updateProps((p) => {
          p.params[1][2] = x;
          p.params[1][3] = y;
        });
      }

      if (this.sphere) {
        this.sphere.updateProps((p) => {
          p.params[1][2] = x;
          p.params[1][3] = y;
        });
      }
    });
  }

  private startRendering(): void {
    const camera = this.engine.getCamera();
    const canvas = this.engine.getCanvas();
    camera.setAspect(canvas.width / canvas.height);

    let time = 0;
    let startTimer = false;
    setTimeout(() => (startTimer = true), 300);

    gsap.ticker.add(() => {
      this.stats.begin();
      if (startTimer) {
        time += 0.05;
        this.scene.run(time);

        // if (this.plane) {
        //   this.plane.updateProps((p) => {
        //     p.params[0][2] = time;
        //   });
        // }
        if (this.plane) {
          // Interpolate
          this.easedMouse.x += (this.rawMouse.x - this.easedMouse.x) * 0.05;
          this.easedMouse.y += (this.rawMouse.y - this.easedMouse.y) * 0.05;

          this.plane.updateProps((p) => {
            p.params[0][0] = this.easedMouse.x;
            p.params[0][1] = this.easedMouse.y;
            p.params[0][2] = time;
          });
        }
        if (this.cube) {
          // Interpolate (using the same eased mouse values)
          this.easedMouse.x += (this.rawMouse.x - this.easedMouse.x) * 0.05;
          this.easedMouse.y += (this.rawMouse.y - this.easedMouse.y) * 0.05;

          this.cube.updateProps((p) => {
            p.params[0][0] = this.easedMouse.x;
            p.params[0][1] = this.easedMouse.y;
            p.params[0][2] = time;
            // You can add p.params[0][3] for duration if needed
          });
        }

        if (this.sphere) {
          this.easedMouse.x += (this.rawMouse.x - this.easedMouse.x) * 0.05;
          this.easedMouse.y += (this.rawMouse.y - this.easedMouse.y) * 0.05;

          this.sphere.updateProps((p) => {
            p.params[0][0] = this.easedMouse.x;
            p.params[0][1] = this.easedMouse.y;
            p.params[0][2] = time;
          });
        }

        if (this.noiseSphere) {
          this.easedMouse.x += (this.rawMouse.x - this.easedMouse.x) * 0.05;
          this.easedMouse.y += (this.rawMouse.y - this.easedMouse.y) * 0.05;

          this.noiseSphere.updateProps((p) => {
            p.params[0][0] = this.easedMouse.x;
            p.params[0][1] = this.easedMouse.y;
            p.params[0][2] = time;
          });
        }
      }
      this.engine.render();
      this.stats.end();
    });
  }

  private testCubes(device: GPUDevice, format: GPUTextureFormat): void {
    const cubeShaderModule = device.createShaderModule({ code: cubeShader });

    const cube = new Cube(device, format, {
      posX: 0,
      posY: 0,
      posZ: 0,
      rotX: 0.6,
      rotY: 0.8,
      rotZ: 0.5,
      scaleX: 1,
      scaleY: 1,
      scaleZ: 1,
      cubeColor: [0.3, 0.3, 0.5, 1],
      shader: cubeShaderModule,
      wireframe: false,
      params: [
        [0.0, 0.0, 0.0, 0.0], // u_mouse.xy, u_time, u_duration
        [0.0, 0.0, 0.0, 0.0], // u_resolution.xy, etc.
      ],
    });
    this.scene.add(cube);
    this.cube = cube;
    setTimeout(() => {
      cube.updateCameraTransform();
    }, 0);

    // const rnMultiplierPos = 10;
    // for (let i = 0; i < 1000; i++) {
    //   const cube = new Cube(device, format, {
    //     posX: Math.random() * rnMultiplierPos - 3,
    //     posY: Math.random() * rnMultiplierPos - 3,
    //     posZ: Math.random() * rnMultiplierPos - 0,
    //     rotX: Math.random() * rnMultiplierPos,
    //     rotY: Math.random() * rnMultiplierPos,
    //     rotZ: Math.random() * rnMultiplierPos,
    //     scaleX: Math.random() * 1,
    //     scaleY: Math.random() * 1,
    //     scaleZ: Math.random() * 1,
    //     cubeColor: [Math.random(), Math.random(), Math.random(), 1],
    //     shader: cubeShaderModule,
    //   });
    //   this.scene.add(cube);

    //   const tween = gsap.to(cube.getProps(), {
    //     posX: Math.random() * rnMultiplierPos - 3,
    //     posY: Math.random() * rnMultiplierPos - 3,
    //     posZ: Math.random() * rnMultiplierPos - 0,
    //     rotX: Math.random() * rnMultiplierPos,
    //     rotY: Math.random() * rnMultiplierPos,
    //     rotZ: Math.random() * rnMultiplierPos,
    //     scaleX: Math.random() * 1,
    //     scaleY: Math.random() * 1,
    //     scaleZ: Math.random() * 1,
    //     duration: 4,
    //     repeat: -1,
    //     yoyo: true,
    //     ease: "power4.inOut",
    //     onUpdate: () => cube.updateCameraTransform(),
    //   });

    //   cube.addTween(tween);
    // }
  }

  private async testPlanes(
    device: GPUDevice,
    format: GPUTextureFormat
  ): Promise<void> {
    const planeShaderModule = device.createShaderModule({
      code: shaderRepo,
    });

    // Create shared texture and sampler
    const planeTexture = await createTextureFromImage(
      device,
      // "./images/rino.jpg"
      "./images/marlene.png"
      // "./images/woody.png"
      // "./images/test1.png"
      // "./images/test2.png"
    );
    const planeSampler = device.createSampler({
      magFilter: "linear",
      minFilter: "linear",
      addressModeU: "repeat",
      addressModeV: "repeat",
    });

    const plane = new Plane(
      device,
      format,
      planeShaderModule,
      planeTexture,
      planeSampler,
      {
        posX: 0,
        posY: 0,
        posZ: 5,
        rotX: 0,
        rotY: 0,
        rotZ: 0,
        scaleX: 1,
        scaleY: 1,
        scaleZ: 1,
        color: [1.0, 0, 0, 1.0],
        useTexture: true,
        params: [
          [0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0],
        ],
      }
    );
    this.scene.add(plane);

    this.plane = plane;
    this.updateResolution();

    // setTimeout(() => {
    //   plane.updateProps((p) => {
    //     p.params[0] = [0.0, 0.0, 0.0, 1.0];
    //   });
    // }, 1000);

    // gsap.to(plane.getProps().params[0], {
    //   duration: 2,
    //   ease: "sine.inOut",
    //   repeat: -1,
    //   yoyo: true,

    //   // GSAP lets you target array indices by numeric keys
    //   0: 0.0, // animate element [0] of the array → transform.params[0].x

    //   onUpdate: () => {
    //     // after each tween tick, write the new uniforms
    //     plane.updateCameraTransform();
    //   },
    // });
  }

  // Add sphere test method
  private async testSpheres(
    device: GPUDevice,
    format: GPUTextureFormat
  ): Promise<void> {
    const sphereShaderModule = device.createShaderModule({
      code: sphereShader,
    });

    const noiseSphereShaderModule = device.createShaderModule({
      code: noiseSphereShader,
    });

    const sphere = new Sphere(device, format, {
      posX: 0,
      posY: 0,
      posZ: 0,
      rotX: 0,
      rotY: 0,
      rotZ: 0,
      scaleX: 1,
      scaleY: 1,
      scaleZ: 1,
      sphereColor: [0.8, 0.4, 0.9, 1],
      shader: sphereShaderModule,
      wireframe: false,
      geometryType: "uv",
      segments: { width: 32, height: 16 },
      params: [
        [0.0, 0.0, 0.0, 0.0], // u_mouse.xy, u_time, u_duration
        [0.0, 0.0, 0.0, 0.0], // u_resolution.xy, etc.
      ],
    });
    // this.scene.add(sphere);
    // this.sphere = sphere; // Store reference

    // Load the fire texture
    const fireTexture = await createTextureFromImage(
      device,
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/explosion.png"
    );

    const fireSampler = device.createSampler({
      magFilter: "linear",
      minFilter: "linear",
      addressModeU: "clamp-to-edge", // Important for vertical gradient
      addressModeV: "clamp-to-edge",
    });
    const noiseSphere = new Sphere(device, format, {
      posX: 0,
      posY: 0,
      posZ: 0,
      rotX: 0,
      rotY: 0,
      rotZ: 0,
      scaleX: 1,
      scaleY: 1,
      scaleZ: 1,
      sphereColor: [1.0, 1.0, 0.0, 1],
      shader: noiseSphereShaderModule, // Use the simple one first
      wireframe: false, // Try wireframe: true to see the geometry structure
      geometryType: "icosahedron",
      subdivisions: 4,
      texture: fireTexture, // ADD THIS
      sampler: fireSampler,
      params: [
        [0.0, 0.0, 0.0, 0.0],
        [0.0, 0.0, 0.0, 0.0],
      ],
    });
    this.scene.add(noiseSphere);
    this.noiseSphere = noiseSphere;

    setTimeout(() => {
      noiseSphere.updateCameraTransform();
    }, 0);
  }
}
