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

  private rawMouse = { x: 0, y: 0 };
  private easedMouse = { x: 0, y: 0 };

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

      this.rawMouse.x = e.clientX - rect.left;
      this.rawMouse.y = e.clientY - rect.top;

      // debug

      if (this.plane) {
        this.plane.updateProps((p) => {
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
      }
      this.engine.render();
      this.stats.end();
    });
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
      "./images/rino.jpg"
      // "./images/marlene.png",
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
}
