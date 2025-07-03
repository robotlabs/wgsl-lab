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
/// Uniform scale about a given `center` point
fn scale2D(
  st:     vec2<f32>,
  center: vec2<f32>,
  s:      f32
) -> vec2<f32> {
  // 1) translate so center → origin
  let p = st - center;
  // 2) scale
  let q = p * s;
  // 3) translate back
  return q + center;
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


fn circle(pt: vec2<f32>, center: vec2<f32>, radius: f32, edge_thickness: f32) -> f32{
    let p = pt - center;
    //* you can use len or distance.
    //** IMPORTANT THING TO UNDERSTAND: distance(a, b) == length(a - b)
    let len = length(p);
    let pct = distance(pt, center);
    let result = 1.0 - smoothstep(radius - edge_thickness, radius, pct);
    return result;
}
// -----------------------------------------
// Fragment shader
// -----------------------------------------
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
  // 1) Grid setup
  let time = transform.params[0][2] / 10.0;

  let tileCount = 4.0;
  let grid = uv * tileCount;
  let col  = i32(floor(grid.x));
  let row  = i32(floor(grid.y));

  // 2) Local UV in each cell
  var st = fract(grid);

  // 3) Draw the white box in every tile
  var boxMask = box(st, vec2<f32>(0.7, 0.7), 0.01);
  var color   = vec3<f32>(1.0) * boxMask;  // white square

    if (col == 1 && row == 2) {
        let base = color;
        let stScaled00 =   scale2D(st, vec2<f32>(0.2),  sin(time / 2.0) *1.4);
        let m1 = circle(stScaled00, vec2<f32>(0.2), 0.2, 0.01);
        let c1 = vec3<f32>(1.0, 0.0, 1.0);
        var colOut = mix(base, c1, m1);
        color = colOut;
    }
  // 4) In the chosen tiles, also draw a red circle inside the same box
  if ((col == 0 && row == 0) ||
      (col == 1 && row == 1) ||
      (col == 2 && row == 2)) {

          // 3) Draw the white box in every tile
        st = rotate2D(st, PI * 0.25 + time);
        boxMask = box(st, vec2<f32>(0.9, 0.9), 0.01);
        color   = vec3<f32>(1.0) * boxMask;  // white square

        // white square
        let base = color;

        // circle 1: red
        let stScaled =   scale2D(st, vec2<f32>(0.4), 1.4);
        let m1 = circle(stScaled, vec2<f32>(0.4), 0.2, 0.01);
        let c1 = vec3<f32>(1.0, 0.0, 0.0);
        var colOut = mix(base, c1, m1);

        // circle 2: green
        let m2 = circle(st, vec2<f32>(0.8), 0.1, 0.01);
        let c2 = vec3<f32>(0.0, 1.0, 0.0);
        colOut = mix(colOut, c2, m2);

        // circle 3: blue
        let stScaled2 =   scale2D(st, vec2<f32>(0.4), sin(time) * 2.0);
        let m3 = circle(stScaled2, vec2<f32>(0.4), 0.15, 0.01);
        let c3 = vec3<f32>(0.0, 0.0, 1.0);
        colOut = mix(colOut, c3, m3);

        color = colOut;
  }

  return vec4<f32>(color, 1.0);
}
