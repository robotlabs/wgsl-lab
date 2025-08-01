import { Object3D } from "../../core/types";
import gsap from "gsap";
import {
  makeRotationMatrix,
  makeScaleMatrix,
  makeTranslationMatrix,
  multiplyMatrices,
} from "../../core/matrix";
import { Camera } from "../../core/camera";
import { SphereProps } from "./sphere-types";
import {
  createSphereGeometry,
  createSingleSpherePipeline,
} from "./sphere-utils";
import { createIcosahedronGeometry } from "./icosahedron-geometry-utils";

export class Sphere implements Object3D {
  private device: GPUDevice;
  private format: GPUTextureFormat;
  private props: SphereProps;
  private shader: GPUShaderModule;

  private vertexBuffer!: GPUBuffer;
  private indexBuffer!: GPUBuffer;
  private wireframeIndexBuffer!: GPUBuffer;
  private transformBuffer!: GPUBuffer;
  private pipeline!: GPURenderPipeline;
  private wireframePipeline!: GPURenderPipeline;
  private bindGroup!: GPUBindGroup;
  private wireframeBindGroup!: GPUBindGroup;

  private camera!: Camera;

  private radius: number = 1;
  private widthSegments: number = 32;
  private heightSegments: number = 16;
  private totalIndices: number = 0;
  private totalWireframeIndices: number = 0;

  private tweens: gsap.core.Tween[] = [];

  constructor(device: GPUDevice, format: GPUTextureFormat, props: SphereProps) {
    this.device = device;
    this.format = format;
    this.props = props;
  }

  setCamera(camera: Camera): void {
    this.camera = camera;
  }

  init(): void {
    const geometryType = this.props.geometryType || "uv";

    const geometryData =
      geometryType === "icosahedron"
        ? createIcosahedronGeometry(
            this.device,
            this.props.radius || 1,
            this.props.subdivisions || 2
          )
        : createSphereGeometry(
            this.device,
            this.props.radius || 1,
            this.props.segments?.width || 32,
            this.props.segments?.height || 16
          );

    const {
      sphereVertexBuffer,
      sphereIndexBuffer,
      sphereWireframeIndexBuffer,
      indexCount,
      wireframeIndexCount,
    } = geometryData;

    this.vertexBuffer = sphereVertexBuffer;
    this.indexBuffer = sphereIndexBuffer;
    this.wireframeIndexBuffer = sphereWireframeIndexBuffer;
    this.totalIndices = indexCount;
    this.totalWireframeIndices = wireframeIndexCount;

    // Fallbacks (white 1x1 texture & default sampler)
    const fallbackSampler = this.device.createSampler({
      magFilter: "linear",
      minFilter: "linear",
    });

    const fallbackTexture = this.device.createTexture({
      size: [1, 1, 1],
      format: "rgba8unorm",
      usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
    });

    this.device.queue.writeTexture(
      { texture: fallbackTexture },
      new Uint8Array([255, 255, 255, 255]),
      { bytesPerRow: 4 },
      { width: 1, height: 1, depthOrArrayLayers: 1 }
    );

    // Layout always expects 3 bindings
    const bindGroupLayout = this.device.createBindGroupLayout({
      label: "Single Sphere Bind Group Layout",
      entries: [
        {
          binding: 0,
          visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT,
          buffer: { type: "uniform" },
        },
        {
          binding: 1,
          visibility: GPUShaderStage.FRAGMENT,
          sampler: { type: "filtering" },
        },
        {
          binding: 2,
          visibility: GPUShaderStage.FRAGMENT,
          texture: { sampleType: "float" },
        },
      ],
    });

    this.pipeline = createSingleSpherePipeline(
      this.device,
      this.format,
      this.props.shader,
      bindGroupLayout,
      false
    );

    this.wireframePipeline = createSingleSpherePipeline(
      this.device,
      this.format,
      this.props.shader,
      bindGroupLayout,
      true
    );

    // Buffer layout: 4 mat4 + vec4 color + vec4 * n
    const MAT_SIZE = 16;
    const COLOR_SIZE = 4;
    const PARAM_SLOTS = this.props.params?.length || 0;
    const PARAM_SIZE = 4;
    const FLOAT_COUNT = MAT_SIZE * 4 + COLOR_SIZE + PARAM_SLOTS * PARAM_SIZE;

    this.transformBuffer = this.device.createBuffer({
      size: FLOAT_COUNT * 4,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    // Unified bind group with fallback resources
    this.bindGroup = this.device.createBindGroup({
      layout: this.pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.transformBuffer } },
        { binding: 1, resource: this.props.sampler ?? fallbackSampler },
        {
          binding: 2,
          resource: (this.props.texture ?? fallbackTexture).createView(),
        },
      ],
    });

    this.wireframeBindGroup = this.device.createBindGroup({
      layout: this.wireframePipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.transformBuffer } },
        { binding: 1, resource: fallbackSampler },
        { binding: 2, resource: fallbackTexture.createView() },
      ],
    });

    this.updateCameraTransform();
  }

  updateCameraTransform(): void {
    const {
      posX,
      posY,
      posZ,
      rotX,
      rotY,
      rotZ,
      scaleX,
      scaleY,
      scaleZ,
      sphereColor,
      params = [],
    } = this.props;

    const scale = makeScaleMatrix(scaleX, scaleY, scaleZ);
    const rotation = makeRotationMatrix(rotX, rotY, rotZ);
    const translation = makeTranslationMatrix(posX, posY, posZ);
    const model = multiplyMatrices(
      translation,
      multiplyMatrices(rotation, scale)
    );

    const view = this.camera.getViewMatrix();
    const proj = this.camera.getProjectionMatrix();

    // Calculate buffer layout
    const MAT_SIZE = 16; // floats per mat4x4
    const COLOR_SIZE = 4; // vec4
    const PARAM_SLOTS = params.length; // number of vec4 slots
    const PARAM_SIZE = 4; // floats per vec4
    const FLOAT_COUNT =
      MAT_SIZE * 4 + // modelSphere, modelGrid, view, proj (4 matrices)
      COLOR_SIZE + // sphereColor
      PARAM_SLOTS * PARAM_SIZE;

    // Offsets (in floats)
    const OFF_MODEL_SPHERE = 0;
    const OFF_MODEL_GRID = OFF_MODEL_SPHERE + MAT_SIZE;
    const OFF_VIEW = OFF_MODEL_GRID + MAT_SIZE;
    const OFF_PROJ = OFF_VIEW + MAT_SIZE;
    const OFF_COLOR = OFF_PROJ + MAT_SIZE;
    const OFF_PARAMS = OFF_COLOR + COLOR_SIZE;

    const data = new Float32Array(FLOAT_COUNT);
    data.set(model, OFF_MODEL_SPHERE);
    data.set(model, OFF_MODEL_GRID); // Using same model matrix for both
    data.set(view, OFF_VIEW);
    data.set(proj, OFF_PROJ);
    data.set(sphereColor, OFF_COLOR);

    // Write each params[i] at the correct offset
    for (let i = 0; i < PARAM_SLOTS; i++) {
      data.set(params[i], OFF_PARAMS + i * PARAM_SIZE);
    }

    this.device.queue.writeBuffer(this.transformBuffer, 0, data);
  }

  render(pass: GPURenderPassEncoder): void {
    const isWireframe = (this.props as any).wireframe || false;

    if (isWireframe) {
      pass.setPipeline(this.wireframePipeline);
      pass.setVertexBuffer(0, this.vertexBuffer);
      pass.setIndexBuffer(this.wireframeIndexBuffer, "uint16");
      pass.setBindGroup(0, this.wireframeBindGroup);
      pass.drawIndexed(this.totalWireframeIndices);
    } else {
      pass.setPipeline(this.pipeline);
      pass.setVertexBuffer(0, this.vertexBuffer);
      pass.setIndexBuffer(this.indexBuffer, "uint16");
      pass.setBindGroup(0, this.bindGroup);
      pass.drawIndexed(this.totalIndices);
    }
  }

  addTween(tween: gsap.core.Tween) {
    this.tweens.push(tween);
  }

  destroy(): void {
    this.vertexBuffer?.destroy();
    this.indexBuffer?.destroy();
    this.wireframeIndexBuffer?.destroy();
    this.transformBuffer?.destroy();

    // Help GC
    this.bindGroup = null as any;
    this.wireframeBindGroup = null as any;
    this.pipeline = null as any;
    this.wireframePipeline = null as any;
    this.shader = null as any;
    this.camera = null as any;
    (this.props as any) = null;

    this.tweens.forEach((tween) => tween.kill());
    this.tweens = [];
  }

  run(time: number): void {}

  updateProps(callback: (props: SphereProps) => void): void {
    callback(this.props);
    this.updateCameraTransform();
  }

  getProps(): SphereProps {
    return this.props;
  }
}
