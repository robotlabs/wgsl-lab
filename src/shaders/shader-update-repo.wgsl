// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform struct
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

// -----------------------------------------
// Vertex output
// -----------------------------------------
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
// Noise and FBM functions
// -----------------------------------------
fn random(st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);
    let a = random(i);
    let b = random(i + vec2<f32>(1.0, 0.0));
    let c = random(i + vec2<f32>(0.0, 1.0));
    let d = random(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

fn fbm(st_input: vec2<f32>) -> f32 {
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var st = st_input;

    for (var i: i32 = 0; i < 12; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.684;
    }

    return value;
}

// -----------------------------------------
// Fragment shader
// -----------------------------------------
@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    var st = uv;
    st.x *= u_resolution.x / u_resolution.y;

    var color = vec3<f32>(0.0);
    color += fbm(st * 3.0);

    return vec4<f32>(color, 1.0);
}
