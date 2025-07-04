// -----------------------------------------
// Constants (if you need them later)
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
  params:      array<vec4<f32>, 2>,  // [0].z = u_time
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
// Portable random()  
// -----------------------------------------
fn random(st: vec2<f32>) -> f32 {
  return fract(sin(dot(st, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

// -----------------------------------------
// Portable truchetPattern()
// -----------------------------------------
fn truchetPattern(st: vec2<f32>, idx_in: f32) -> vec2<f32> {
  var idx = fract((idx_in - 0.5) * 2.0);
  var p   = st;
  if (idx > 0.75) {
    p = vec2<f32>(1.0) - p;
  } else if (idx > 0.5) {
    p = vec2<f32>(1.0 - p.x, p.y);
  } else if (idx > 0.25) {
    p = vec2<f32>(1.0 - p.x, 1.0 - p.y);
  }
  return p;
}

// -----------------------------------------
// Fragment shader: Truchet maze + variants
// -----------------------------------------
@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    // time (in seconds)
    let time = transform.params[0][2];

    // normalized coords from uv
    var st = uv;

    // scale up to 10×10 grid
    st *= 10.0;

    // optional experiments:
    // st = (st - vec2<f32>(5.0)) * (abs(sin(time * 0.2)) * 5.0);
    // st.x += time * 3.0;

    // integer + fractional parts
    let ipos = floor(st);  // integer tile coords
    let fpos = fract(st);  // local 0–1 within tile

    // apply static
    var tile = truchetPattern(fpos, random(ipos));
    // or animate random patterns
    let speed1 = 0.0000001;
    let speed2 = 0.0000001;
    let seed = random(ipos + vec2<f32>(time * speed1, time * speed2));
    tile = truchetPattern(fpos, seed);

    // base color
    var colorVal: f32 = 0.0;

    // Maze pattern
    colorVal = smoothstep(tile.x - 0.3, tile.x, tile.y)
             - smoothstep(tile.x, tile.x + 0.3, tile.y);

    // Circles
    colorVal = (step(length(tile), 0.6) - step(length(tile), 0.4))
             + (step(length(tile - vec2<f32>(1.0)), 0.6)
              - step(length(tile - vec2<f32>(1.0)), 0.4));

    // Truchet (2 triangles)
    // colorVal = step(tile.x, tile.y);

    return vec4<f32>(vec3<f32>(colorVal), 1.0);
}
