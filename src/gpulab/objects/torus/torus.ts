// torus.ts - Updated with environment mapping
import { Object3D } from "../../core/types";
import gsap from "gsap";
import {
  makeRotationMatrix,
  makeScaleMatrix,
  makeTranslationMatrix,
  multiplyMatrices,
} from "../../core/matrix";
import { Camera } from "../../core/camera";
import { TorusProps } from "./torus-types";
import { createTorusGeometry, createSingleTorusPipeline } from "./torus-utils";

export class Torus implements Object3D {
  private device: GPUDevice;
  private format: GPUTextureFormat;
  private props: TorusProps;

  private vertexBuffer!: GPUBuffer;
  private indexBuffer!: GPUBuffer;
  private wireframeIndexBuffer!: GPUBuffer;
  private transformBuffer!: GPUBuffer;
  private pipeline!: GPURenderPipeline;
  private wireframePipeline!: GPURenderPipeline;
  private bindGroup!: GPUBindGroup;
  private wireframeBindGroup!: GPUBindGroup;

  // Environment mapping additions
  private envTexture!: GPUTexture;
  private envSampler!: GPUSampler;

  private camera!: Camera;

  private majorRadius: number;
  private minorRadius: number;
  private majorSegments: number;
  private minorSegments: number;
  private totalIndices: number = 0;
  private totalWireframeIndices: number = 0;

  private tweens: gsap.core.Tween[] = [];

  constructor(device: GPUDevice, format: GPUTextureFormat, props: TorusProps) {
    this.device = device;
    this.format = format;
    this.props = props;

    // Set torus-specific properties with defaults
    this.majorRadius = props.majorRadius ?? 1.0;
    this.minorRadius = props.minorRadius ?? 0.4;
    this.majorSegments = props.majorSegments ?? 32;
    this.minorSegments = props.minorSegments ?? 16;
  }

  setCamera(camera: Camera): void {
    this.camera = camera;
  }

  // Load the exact same environment texture from ShaderFrog example
  private async loadEnvironmentTexture(): Promise<void> {
    const faceUrls = [
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_px.jpg",
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_nx.jpg",
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_py.jpg",
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_ny.jpg",
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_pz.jpg",
      "https://s3-us-west-2.amazonaws.com/s.cdpn.io/2666677/skybox2_nz.jpg",
    ];

    // Create cubemap texture
    this.envTexture = this.device.createTexture({
      size: [512, 512, 6],
      format: "rgba8unorm",
      usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
      dimension: "2d",
      mipLevelCount: 1,
    });

    // Load and upload each face
    for (let i = 0; i < 6; i++) {
      const response = await fetch(faceUrls[i]);
      const imageBitmap = await createImageBitmap(await response.blob());

      this.device.queue.copyExternalImageToTexture(
        { source: imageBitmap },
        {
          texture: this.envTexture,
          origin: [0, 0, i],
        },
        [imageBitmap.width, imageBitmap.height]
      );
    }

    // Create sampler
    this.envSampler = this.device.createSampler({
      magFilter: "linear",
      minFilter: "linear",
      mipmapFilter: "linear",
      addressModeU: "clamp-to-edge",
      addressModeV: "clamp-to-edge",
      addressModeW: "clamp-to-edge",
    });
  }

  async init(): Promise<void> {
    // Load environment texture first
    await this.loadEnvironmentTexture();

    const { torusVertexBuffer, torusIndexBuffer, torusWireframeIndexBuffer } =
      createTorusGeometry(
        this.device,
        this.majorRadius,
        this.minorRadius,
        this.majorSegments,
        this.minorSegments
      );

    this.vertexBuffer = torusVertexBuffer;
    this.indexBuffer = torusIndexBuffer;
    this.wireframeIndexBuffer = torusWireframeIndexBuffer;

    // Calculate total indices
    this.totalIndices = this.majorSegments * this.minorSegments * 6;
    this.totalWireframeIndices = this.majorSegments * this.minorSegments * 12;

    // Create both solid and wireframe pipelines WITH environment mapping
    this.pipeline = createSingleTorusPipeline(
      this.device,
      this.format,
      this.props.shader,
      false // solid
    );

    this.wireframePipeline = createSingleTorusPipeline(
      this.device,
      this.format,
      this.props.shader,
      true // wireframe
    );

    this.transformBuffer = this.device.createBuffer({
      size: 320, // corrected to match updated WGSL struct
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    // Updated bind groups to include environment texture and sampler
    this.bindGroup = this.device.createBindGroup({
      layout: this.pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.transformBuffer } },
        {
          binding: 1,
          resource: this.envTexture.createView({ dimension: "cube" }),
        },
        { binding: 2, resource: this.envSampler },
      ],
    });

    this.wireframeBindGroup = this.device.createBindGroup({
      layout: this.wireframePipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: this.transformBuffer } },
        {
          binding: 1,
          resource: this.envTexture.createView({ dimension: "cube" }),
        },
        { binding: 2, resource: this.envSampler },
      ],
    });

    // Don't call updateCameraTransform here - camera isn't set yet
    // this.updateCameraTransform();
  }

  updateCameraTransform(): void {
    if (!this.transformBuffer) return;

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
      torusColor,
      params = [],
    } = this.props;

    // Ensure we have exactly two vec4 params (fallback to zero)
    const param0: number[] = params[0] ?? [0, 0, 0, 0];
    const param1: number[] = params[1] ?? [0, 0, 0, 0];

    const scale = makeScaleMatrix(scaleX, scaleY, scaleZ);
    const rotation = makeRotationMatrix(rotX, rotY, rotZ);
    const translation = makeTranslationMatrix(posX, posY, posZ);
    const model = multiplyMatrices(
      translation,
      multiplyMatrices(rotation, scale)
    );

    const view = this.camera.getViewMatrix();
    const proj = this.camera.getProjectionMatrix();

    // Offsets in floats according to shader struct:
    // modelTorus (16), modelGrid (16), view (16), proj (16),
    // torusColor (4), params[0] (4), params[1] (4), cameraPos (4) = 80 floats
    const OFF_MODEL_TORUS = 0;
    const OFF_MODEL_GRID = OFF_MODEL_TORUS + 16; // 16
    const OFF_VIEW = OFF_MODEL_GRID + 16; // 32
    const OFF_PROJ = OFF_VIEW + 16; // 48
    const OFF_COLOR = OFF_PROJ + 16; // 64
    const OFF_PARAM0 = OFF_COLOR + 4; // 68
    const OFF_PARAM1 = OFF_PARAM0 + 4; // 72
    const OFF_CAMERA = OFF_PARAM1 + 4; // 76

    const FLOAT_COUNT = OFF_CAMERA + 4; // 80

    const data = new Float32Array(FLOAT_COUNT);
    data.set(model, OFF_MODEL_TORUS);
    data.set(model, OFF_MODEL_GRID);
    data.set(view, OFF_VIEW);
    data.set(proj, OFF_PROJ);
    data.set(torusColor, OFF_COLOR);

    data.set(param0, OFF_PARAM0);
    data.set(param1, OFF_PARAM1);

    const cameraPos = this.camera.getPosition(); // should be [x,y,z]
    data.set([cameraPos[0], cameraPos[1], cameraPos[2], 1.0], OFF_CAMERA);

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
    this.envTexture?.destroy(); // Clean up environment texture

    // Help GC
    this.bindGroup = null as any;
    this.wireframeBindGroup = null as any;
    this.pipeline = null as any;
    this.wireframePipeline = null as any;
    this.camera = null as any;
    (this.props as any) = null;

    this.tweens.forEach((tween) => tween.kill());
    this.tweens = [];
  }

  run(time: number): void {}

  updateProps(callback: (props: TorusProps) => void): void {
    callback(this.props);
    this.updateCameraTransform();
  }

  getProps(): TorusProps {
    return this.props;
  }
}
