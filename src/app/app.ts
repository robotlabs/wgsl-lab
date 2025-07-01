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

  constructor() {}

  async init(canvas: HTMLCanvasElement): Promise<void> {
    var cameraInitPos: vec3 = [0, 0, 7];

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
    this.testPlanes(device, format);

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
      console.log(w, h);
      this.plane.updateProps((p) => {
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

      // debug
      console.log("mouse CSS px:", x, y);

      if (this.plane) {
        this.plane.updateProps((p) => {
          p.params[0][0] = x;
          p.params[0][1] = y;
          p.params[0][2] = 0;
          p.params[0][3] = 0;
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

        if (this.plane) {
          this.plane.updateProps((p) => {
            p.params[0] = [time, 0.0, 0.0, 1.0];
          });
        }
      }
      this.engine.render();
      this.stats.end();
    });
  }

  private testCubes(device: GPUDevice, format: GPUTextureFormat): void {
    const cubeShaderModule = device.createShaderModule({ code: cubeShader });

    //** single cube */
    const rnMultiplierPos = 10;
    for (let i = 0; i < 1000; i++) {
      const cube = new Cube(device, format, {
        posX: Math.random() * rnMultiplierPos - 3,
        posY: Math.random() * rnMultiplierPos - 3,
        posZ: Math.random() * rnMultiplierPos - 0,
        rotX: Math.random() * rnMultiplierPos,
        rotY: Math.random() * rnMultiplierPos,
        rotZ: Math.random() * rnMultiplierPos,
        scaleX: Math.random() * 1,
        scaleY: Math.random() * 1,
        scaleZ: Math.random() * 1,
        cubeColor: [Math.random(), Math.random(), Math.random(), 1],
        shader: cubeShaderModule,
      });
      this.scene.add(cube);

      const tween = gsap.to(cube.getProps(), {
        posX: Math.random() * rnMultiplierPos - 3,
        posY: Math.random() * rnMultiplierPos - 3,
        posZ: Math.random() * rnMultiplierPos - 0,
        rotX: Math.random() * rnMultiplierPos,
        rotY: Math.random() * rnMultiplierPos,
        rotZ: Math.random() * rnMultiplierPos,
        scaleX: Math.random() * 1,
        scaleY: Math.random() * 1,
        scaleZ: Math.random() * 1,
        duration: 4,
        repeat: -1,
        yoyo: true,
        ease: "power4.inOut",
        onUpdate: () => cube.updateCameraTransform(),
      });

      cube.addTween(tween);
    }
  }

  private async testPlanes(
    device: GPUDevice,
    format: GPUTextureFormat
  ): Promise<void> {
    const planeShaderModule = device.createShaderModule({
      code: shader3,
    });

    // Create shared texture and sampler
    const planeTexture = await createTextureFromImage(
      device,
      "./images/marlene.png"
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
        useTexture: false,
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
}
