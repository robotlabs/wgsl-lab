import { vec3 } from "gl-matrix";
import { Pane } from "tweakpane";

interface CameraParams {
  cameraPosX: number;
  cameraPosY: number;
  cameraPosZ: number;
}

interface CustomParams {
  nrIterations: number;
  speedAnim: number;
  radiusSize: number;
}

export class GUIView {
  private app: {
    updateCameraAxis: (axis: "x" | "y" | "z", value: number) => void;
    updateNrIterations?: (value: number) => void;
    updateSpeedAnim?: (value: number) => void;
    updateCustomValueZ?: (value: number) => void;
  };

  private pane: Pane;
  private params: CameraParams;
  private customParams: CustomParams;

  constructor(app: GUIView["app"], cameraInitPos: vec3 = [0, 0, 0]) {
    this.app = app;
    this.params = {
      cameraPosX: cameraInitPos[0],
      cameraPosY: cameraInitPos[1],
      cameraPosZ: cameraInitPos[2],
    };

    this.customParams = {
      nrIterations: 1,
      speedAnim: 7,
      radiusSize: 8.5,
    };

    this.pane = new Pane();
    this.initBindings();
  }

  private initBindings(): void {
    // Camera controls
    const cameraFolder = this.pane.addFolder({ title: "Camera Position" });
    const cameraBindings: [keyof CameraParams, "x" | "y" | "z"][] = [
      ["cameraPosX", "x"],
      ["cameraPosY", "y"],
      ["cameraPosZ", "z"],
    ];

    for (const [paramKey, axis] of cameraBindings) {
      cameraFolder
        //@ts-ignore
        .addBinding(this.params, paramKey, {
          min: -40,
          max: 40,
          step: 0.1,
        })
        //@ts-ignore
        .on("change", (ev) => {
          this.app.updateCameraAxis(axis, ev.value);
        });
    }

    // Custom controls - separate bindings for each parameter
    const customFolder = this.pane.addFolder({ title: "Custom Controls" });

    // Nr Iterations control
    customFolder
      //@ts-ignore
      .addBinding(this.customParams, "nrIterations", {
        min: 1,
        max: 16,
        step: 1,
      })
      //@ts-ignore
      .on("change", (ev) => {
        if (this.app.updateNrIterations) {
          this.app.updateNrIterations(ev.value);
        } else {
          console.log("Nr Iterations changed to:", ev.value);
        }
      });

    // Speed Animation control
    customFolder
      //@ts-ignore
      .addBinding(this.customParams, "speedAnim", {
        min: 1,
        max: 15,
        step: 1,
      })
      //@ts-ignore
      .on("change", (ev) => {
        if (this.app.updateSpeedAnim) {
          this.app.updateSpeedAnim(ev.value);
        } else {
          console.log("Speed Animation changed to:", ev.value);
        }
      });

    // Custom Value Z control (customize as needed)
    customFolder
      //@ts-ignore
      .addBinding(this.customParams, "radiusSize", {
        min: -5,
        max: 20,
        step: 0.5,
      })
      //@ts-ignore
      .on("change", (ev) => {
        if (this.app.updateRadiusSize) {
          this.app.updateRadiusSize(ev.value);
        } else {
          console.log("Custom Value Z changed to:", ev.value);
        }
      });

    //@ts-ignore
    this.pane.addButton({ title: "Run Planes" }).on("click", () => {
      if ("runPlanes" in this.app && typeof this.app.runPlanes === "function") {
        this.app.runPlanes();
      } else {
        console.warn("runPlanes() is not defined on app.");
      }
    });
  }
}
