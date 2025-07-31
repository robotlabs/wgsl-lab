// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform Struct
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>, // [0].z = u_time, [1].xy = resolution
};

@group(0) @binding(0) var<uniform> transform: Transform;

// -----------------------------------------
// Vertex Output
// -----------------------------------------
struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}

// -----------------------------------------
// Simplex Noise (Ashima)
// -----------------------------------------
fn mod289_f32(x: f32) -> f32 {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
fn mod289_vec2(x: vec2<f32>) -> vec2<f32> {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
fn mod289_vec3(x: vec3<f32>) -> vec3<f32> {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn permute(x: vec3<f32>) -> vec3<f32> {
  return mod289_vec3(((x * 34.0) + 1.0) * x);
}

fn snoise(v: vec2<f32>) -> f32 {
  let C = vec4<f32>(
    0.211324865405187,  // (3.0 - sqrt(3.0)) / 6.0
    0.366025403784439,  // 0.5 * (sqrt(3.0) - 1.0)
   -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439   // 1.0 / 41.0
  );

  var i = floor(v + dot(v, C.yy));
  let x0 = v - i + dot(i, C.xx);

  // ternary: if x0.x > x0.y then vec2(1,0) else vec2(0,1)
  let i1 = select(vec2<f32>(0.0, 1.0), vec2<f32>(1.0, 0.0), x0.x > x0.y);
  let x1 = x0 - i1 + C.xx;
  let x2 = x0 + C.zz;

  i = mod289_vec2(i);
  let p = permute(
    permute(
        vec3<f32>(i.y, i.y, i.y) + vec3<f32>(0.0, i1.y, 1.0)
    )
    + vec3<f32>(i.x, i.x, i.x)
    + vec3<f32>(0.0, i1.x, 1.0)
  );

  var m = max(vec3<f32>(0.5) - vec3<f32>(
    dot(x0, x0),
    dot(x1, x1),
    dot(x2, x2)
  ), vec3<f32>(0.0));

  m = m * m;
  m = m * m;

  let x = 2.0 * fract(p * C.www) - 1.0;
  let h = abs(x) - 0.5;
  let ox = floor(x + 0.5);
  let a0 = x - ox;

  m = m * (1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h));

  var g = vec3<f32>(0.0);
  g.x = a0.x * x0.x + h.x * x0.y;
  g.y = a0.y * x1.x + h.y * x1.y;
  g.z = a0.z * x2.x + h.z * x2.y;

  return 130.0 * dot(m, g);
}



// -----------------------------------------
// Ridge FBM
// -----------------------------------------
fn ridge(h: f32, offset: f32) -> f32 {
  var x = abs(h);
  x = offset - x;
  x = x * x;
  return x;
}

fn ridgedMF(p: vec2<f32>) -> f32 {
  let lacunarity = 2.0;
  let gain = 0.5;
  let offset = 0.9;
  var sum = 0.0;
  var freq = 1.0;
  var amp = 0.5;
  var prev = 1.0;

  for (var i = 0; i < 4; i++) {
    let n = ridge(snoise(p * freq), offset);
    sum += n * amp;
    sum += n * amp * prev;
    prev = n;
    freq *= lacunarity;
    amp *= gain;
  }

  return sum;
}

// -----------------------------------------
// Fragment Shader
// -----------------------------------------
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
  let resolution = transform.params[1].xy;
  var st = uv;
  st.x *= resolution.x / resolution.y;

  var color = vec3<f32>(0.0);
  color += ridgedMF(st * 3.0);

  return vec4<f32>(color, 1.0);
}
