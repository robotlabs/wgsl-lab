import { vec3 } from "gl-matrix";
import { Pane } from "tweakpane";

interface CameraParams {
  cameraPosX: number;
  cameraPosY: number;
  cameraPosZ: number;
}

export class GUIView {
  private app: {
    updateCameraAxis: (axis: "x" | "y" | "z", value: number) => void;
  };

  private pane: Pane;
  private params: CameraParams;

  constructor(app: GUIView["app"], cameraInitPos: vec3 = [0, 0, 0]) {
    this.app = app;
    this.params = {
      cameraPosX: cameraInitPos[0],
      cameraPosY: cameraInitPos[1],
      cameraPosZ: cameraInitPos[2],
    };

    this.pane = new Pane();
    this.initBindings();
  }

  private initBindings(): void {
    const bindings: [keyof CameraParams, "x" | "y" | "z"][] = [
      ["cameraPosX", "x"],
      ["cameraPosY", "y"],
      ["cameraPosZ", "z"],
    ];

    for (const [paramKey, axis] of bindings) {
      this.pane
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
