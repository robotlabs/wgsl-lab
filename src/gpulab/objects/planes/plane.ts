import { Object3D } from "../../core/types";
import gsap from "gsap";
import {
  makeRotationMatrix,
  makeScaleMatrix,
  makeTranslationMatrix,
  multiplyMatrices,
} from "../../core/matrix";
import { Camera } from "../../core/camera";
import { PlaneProps } from "./plane-types";
import { createPlaneGeometry, createSinglePlanePipeline } from "./plane-utils";

export class Plane implements Object3D {
  private device: GPUDevice;
  private format: GPUTextureFormat;
  private props: PlaneProps;
  private shader: GPUShaderModule;
  private texture: GPUTexture;
  private sampler: GPUSampler;

  private vertexBuffer!: GPUBuffer;
  private indexBuffer!: GPUBuffer;
  private transformBuffer!: GPUBuffer;
  private pipeline!: GPURenderPipeline;
  private bindGroup!: GPUBindGroup;

  private camera!: Camera;

  private tweens: gsap.core.Tween[] = [];

  constructor(
    device: GPUDevice,
    format: GPUTextureFormat,
    shader: GPUShaderModule,
    texture: GPUTexture,
    sampler: GPUSampler,
    props: PlaneProps
  ) {
    this.device = device;
    this.format = format;
    this.shader = shader;
    this.texture = texture;
    this.sampler = sampler;
    this.props = props;
  }

  setCamera(camera: Camera): void {
    this.camera = camera;
  }

  init(): void {
    const { planeVertexBuffer, planeIndexBuffer } = createPlaneGeometry(
      this.device
    );
    this.vertexBuffer = planeVertexBuffer;
    this.indexBuffer = planeIndexBuffer;

    this.pipeline = createSinglePlanePipeline(
      this.device,
      this.format,
      this.shader
    );

    // after:
    const FLOAT_COUNT =
      3 * 16 + // model/view/proj
      4 + // color
      4 + // useTexture
      4 + // params0
      4; // params1 // = 64 floats total
    this.transformBuffer = this.device.createBuffer({
      size: FLOAT_COUNT * 4, // bytes
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    this.bindGroup = this.device.createBindGroup({
      layout: this.pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.transformBuffer } },
        { binding: 1, resource: this.sampler },
        { binding: 2, resource: this.texture.createView() },
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
      color,
      useTexture,
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

    const MAT_SIZE = 16; // floats per mat4x4
    const COLOR_SIZE = 4; // vec4
    const FLAG_SIZE = 4; // vec4 for useTexture + pad
    const PARAM_SLOTS = params.length; // number of vec4 slots
    const PARAM_SIZE = 4; // floats per vec4
    const FLOAT_COUNT =
      MAT_SIZE * 3 + // model, view, proj
      COLOR_SIZE + // color
      FLAG_SIZE + // useTexture
      PARAM_SLOTS * PARAM_SIZE;

    // 3) Offsets (in floats)
    const OFF_MODEL = 0;
    const OFF_VIEW = OFF_MODEL + MAT_SIZE;
    const OFF_PROJ = OFF_VIEW + MAT_SIZE;
    const OFF_COLOR = OFF_PROJ + MAT_SIZE;
    const OFF_FLAG = OFF_COLOR + COLOR_SIZE;
    const OFF_PARAMS = OFF_FLAG + FLAG_SIZE;

    const data = new Float32Array(FLOAT_COUNT);
    data.set(model, OFF_MODEL);
    data.set(view, OFF_VIEW);
    data.set(proj, OFF_PROJ);
    data.set(color, OFF_COLOR);
    data.set([useTexture ? 1 : 0, 0, 0, 0], OFF_FLAG);

    // write each params[i] at the correct offset
    for (let i = 0; i < PARAM_SLOTS; i++) {
      // props.params[i] should be a [number,number,number,number]
      data.set(params[i], OFF_PARAMS + i * PARAM_SIZE);
    }

    this.device.queue.writeBuffer(this.transformBuffer, 0, data);
  }

  render(pass: GPURenderPassEncoder): void {
    pass.setPipeline(this.pipeline);
    pass.setVertexBuffer(0, this.vertexBuffer);
    pass.setIndexBuffer(this.indexBuffer, "uint16");
    pass.setBindGroup(0, this.bindGroup);
    pass.drawIndexed(6); // 6 indices for a quad
  }

  addTween(tween: gsap.core.Tween) {
    this.tweens.push(tween);
  }

  destroy(): void {
    this.vertexBuffer?.destroy();
    this.indexBuffer?.destroy();
    this.transformBuffer?.destroy();

    // Help GC
    this.bindGroup = null as any;
    this.pipeline = null as any;
    this.shader = null as any;
    this.camera = null as any;
    (this.props as any) = null;

    this.tweens.forEach((tween) => tween.kill());
    this.tweens = [];
  }

  run(time: number): void {}

  updateProps(callback: (props: PlaneProps) => void): void {
    callback(this.props);
    this.updateCameraTransform();
  }

  getProps(): PlaneProps {
    return this.props;
  }
}
