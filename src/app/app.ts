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

  private activePlanes: Plane[] = [];

  private tempRnArray: any = [];

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
  public updateNrIterations(nrIterations: number): void {
    for (let i = 0; i < this.activePlanes.length; i++) {
      const plane = this.activePlanes[i];
      plane.updateProps((p) => {
        p.params[0][0] = nrIterations;
      });
    }
  }

  public updateSpeedAnim(speedAnim: number): void {
    for (let i = 0; i < this.activePlanes.length; i++) {
      const plane = this.activePlanes[i];
      plane.updateProps((p) => {
        p.params[0][1] = speedAnim;
        // p.params[1][1] = h;
        // p.params[1][2] = 0;
        // p.params[1][3] = 0;
      });
    }
  }
  public updateRadiusSize(radiusSize: number): void {
    for (let i = 0; i < this.activePlanes.length; i++) {
      const plane = this.activePlanes[i];
      plane.updateProps((p) => {
        p.params[1][0] = radiusSize;
        // p.params[1][1] = h;
        // p.params[1][2] = 0;
        // p.params[1][3] = 0;
      });
    }
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
      // this.plane.updateProps((p) => {
      //   p.params[1][0] = w;
      //   p.params[1][1] = h;
      //   p.params[1][2] = 0;
      //   p.params[1][3] = 0;
      // });
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
        // this.plane.updateProps((p) => {
        //   p.params[0][0] = x;
        //   p.params[0][1] = y;
        //   p.params[0][2] = 0;
        //   p.params[0][3] = 0;
        // });
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

        this.easedMouse.x += (this.rawMouse.x - this.easedMouse.x) * 0.03;
        this.easedMouse.y += (this.rawMouse.y - this.easedMouse.y) * 0.03;

        // this.updateCameraAxis("x", this.easedMouse.x / 10);

        const canvas = this.engine.getCanvas();
        const rect = canvas.getBoundingClientRect();
        const w = rect.width;
        const h = rect.height;

        const endCameraX = (this.easedMouse.x * 10) / w - 5;
        const endCameraY = (this.easedMouse.y * 10) / h - 5;
        // this.updateCameraAxis("x", endCameraX);
        // this.updateCameraAxis("y", endCameraY);

        if (this.activePlanes) {
          for (let i = 0; i < this.activePlanes.length; i++) {
            const plane = this.activePlanes[i];
            plane.updateProps((p) => {
              // console.log(this.tempRnArray);
              p.params[0][2] = time + this.tempRnArray[i] * 10;
            });
          }
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
      code: shader9,
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

    setTimeout(() => {
      for (let i = 0; i < this.activePlanes.length; i++) {
        const plane = this.activePlanes[i];
        plane.updateProps((p) => {
          p.params[0][0] = 1;
          p.params[0][1] = 7;
          p.params[1][0] = 8.5;
          // p.params[1][1] = h;
          // p.params[1][2] = 0;
          // p.params[1][3] = 0;
        });
      }
    }, 20);

    const COUNT = 12;
    const COLS = 6;
    const SX = 4;
    const SY = 4;
    const angle = Math.PI * 0.25; // 45° tip around Y
    const c = Math.cos(angle);
    const s = Math.sin(angle);
    const offsetX = 4;
    const offsetY = 8;
    for (let i = 0; i < COUNT; i++) {
      const col = i % COLS; // 0…COLS-1
      const row = Math.floor(i / COLS); //    0…∞

      // 2) un-rotated position
      const x0 = col * SX - offsetX;
      const y0 = row * SY - offsetY; // your vertical offset
      const z0 = 0;

      // 3) rotate that point around world-Y
      const posX = 0; //x0 * c + z0 * s;
      const posZ = i; //-x0 * s + z0 * c;
      const posY = 0; //y0;
      const plane = new Plane(
        device,
        format,
        planeShaderModule,
        planeTexture,
        planeSampler,
        {
          posX,
          posY,
          posZ,
          rotX: 0, //Math.PI * 1,
          rotY: 0, //angle, // * Math.random() * 10, // so the faces point “into” the grid-plane
          rotZ: 0,
          scaleX: 2,
          scaleY: 2,
          scaleZ: 2,
          color: [Math.random(), Math.random(), Math.random(), 1],
          useTexture: false,
          params: [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
        }
      );
      this.scene.add(plane);
      this.activePlanes.push(plane);

      // Animate the plane
      const tween = gsap.to(plane.getProps(), {
        // posX: Math.random() * Math.random() * 10,
        // posY: posY + Math.random() * 1 - 0,
        posZ: Math.random() * Math.random() * 8 + 4,
        // rotX: 0,
        // rotY: angle,
        // rotZ: Math.random() * Math.PI * 2,
        // scaleX: Math.random() * 4 + 0.5,
        // scaleY: Math.random() * 4 + 0.5,
        delay: Math.random() * 5,
        duration: 10, // + Math.random() * 3,
        repeat: -1,
        yoyo: true,
        ease: "power4.inOut",
        onUpdate: () => plane.updateCameraTransform(),
        onComplete: () => {
          console.log("oncomplete");
        },
        onRepeat: () => {
          console.log("onstart");
          plane.updateProps((p) => {
            p.params[1][0] = Math.random() * 12;
            // p.params[1][1] = h;
            // p.params[1][2] = 0;
            // p.params[1][3] = 0;
          });
        },
      });

      plane.addTween(tween);
    }

    const tempRnArray: any = [];
    for (let i = 0; i < this.activePlanes.length; i++) {
      tempRnArray.push(Math.random());
    }
    this.tempRnArray = tempRnArray;
    console.log(tempRnArray);
    /*
    const COUNT_R = 64;
    const COLS_R = 8;
    const SX_R = 2;
    const SY_R = 2;
    const angle_R = -Math.PI * 0.25; // 45° tip around Y
    const c_R = Math.cos(angle_R);
    const s_R = Math.sin(angle_R);
    const offsetX_R = 1;
    const offsetY_R = 12;
    for (let i = 0; i < COUNT_R; i++) {
      const col = i % COLS_R; // 0…COLS-1
      const row = Math.floor(i / COLS_R); //    0…∞

      // 2) un-rotated position
      const x0 = col * SX_R + offsetX_R;
      const y0 = row * SY_R - offsetY_R; // your vertical offset
      const z0 = 0;

      // 3) rotate that point around world-Y
      const posX = x0 * c_R + z0 * s_R;
      const posZ = -x0 * s_R + z0 * c_R;
      const posY = y0;
      const plane = new Plane(
        device,
        format,
        planeShaderModule,
        planeTexture,
        planeSampler,
        {
          posX,
          posY,
          posZ,
          rotX: 0,
          rotY: angle_R, // so the faces point “into” the grid-plane
          rotZ: 0,
          scaleX: 1,
          scaleY: 1,
          scaleZ: 1,
          color: [Math.random(), Math.random(), Math.random(), 1],
          useTexture: false,
          params: [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
        }
      );
      this.scene.add(plane);
      this.activePlanes.push(plane);

      // Animate the plane
      const tween = gsap.to(plane.getProps(), {
        // posX: posX + i * 0.01,
        // posY: posY + Math.random() * 1 - 0,
        // posZ: Math.random() * rnMultiplierPos - 5,
        // rotX: Math.random() * Math.PI * 2,
        // rotY: Math.random() * Math.PI * 0.002,
        // rotZ: Math.random() * Math.PI * 2,
        scaleX: Math.random() * 4 + 0.5,
        // scaleY: Math.random() * 4 + 0.5,
        duration: 2 + Math.random() * 3,
        repeat: -1,
        yoyo: true,
        ease: "power4.inOut",
        onUpdate: () => plane.updateCameraTransform(),
      });

      plane.addTween(tween);
    }
      */

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
