// -----------------------------------------
// Constants
// -----------------------------------------
const PI:  f32 = 3.141592653589793;
const PI2: f32 = PI * 2.0;

// -----------------------------------------
// Your existing Transform & VS (unchanged)
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>,  // [0].z = u_time, [1].xy = u_resolution
};
@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv       : vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}

// -----------------------------------------
// Helpers
// -----------------------------------------
fn rotate2D(st: vec2<f32>, angle: f32) -> vec2<f32> {
  // rotate about the center (0.5,0.5)
  let p = st - vec2<f32>(0.5);
  let c = cos(angle);
  let s = sin(angle);
  let x = p.x * c - p.y * s;
  let y = p.x * s + p.y * c;
  return vec2<f32>(x, y) + vec2<f32>(0.5);
}

fn tile(st: vec2<f32>, zoom: f32) -> vec2<f32> {
  return fract(st * zoom);
}

fn box(st: vec2<f32>, size: vec2<f32>, smoothEdges: f32) -> f32 {
  // convert size param into half-box extents
  let half = vec2<f32>(0.5) - size * 0.5;
  let aa   = vec2<f32>(smoothEdges * 0.5);
  let uv1  = smoothstep(half, half + aa, st);
  let uv2  = smoothstep(half, half + aa, vec2<f32>(1.0) - st);
  return uv1.x * uv1.y * uv2.x * uv2.y;
}

// -----------------------------------------
// Fragment shader
// -----------------------------------------
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
  // start with normalized UV
  let time = transform.params[0][2] / 10.0;

  let tileCount = 4.0;
  let grid = uv * tileCount;
  let col      = i32(floor(grid.x));
  let row      = i32(floor(grid.y));

  var st = fract(grid);

  // 2) Rotate each tile by 45°
    if ((col == 0 && row == 0) ||
      (col == 1 && row == 1) ||
      (col == 2 && row == 2)) {
    // shape = 1;
    st = rotate2D(st, PI * 0.25 + time);
  }
  

  // 3) Draw the box inside each rotated tile
  let b = box(st, vec2<f32>(0.7, 0.7), 0.01);

  // 4) Output as grayscale
  let color = vec3<f32>(b);
  return vec4<f32>(color, 1.0);
}
