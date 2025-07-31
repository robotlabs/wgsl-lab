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
  params:      array<vec4<f32>, 2>, 
};

@group(0) @binding(0) var<uniform> transform: Transform;
@group(0) @binding(1) var texSampler: sampler;
@group(0) @binding(2) var tex: texture_2d<f32>;

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
// Helper Functions
// -----------------------------------------
fn rotate(pt: vec2<f32>, theta: f32, aspect: f32) -> vec2<f32> {
  let c = cos(theta);
  let s = sin(theta);
  let mat = mat2x2<f32>(c, s, -s, c);
  var ptt = pt;
  ptt.y = pt.y / 10.0;
  ptt = mat * ptt;
  ptt.y *= aspect;
  return ptt;
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
  let u_time = transform.params[0].z;
  let u_duration = transform.params[0].w;
  let u_mouse = transform.params[0].xy;
  let u_resolution = transform.params[1].xy;

  // Reconstruct the position from uv (plane is from -1 to +1)
  let v_position = vec3<f32>(uv * 2.0 - vec2(1.0), 0.0);
  let len = length(v_position.xy);

  // Ripple effect
  let ripple = uv + v_position.xy / len * 0.03 * cos(len * 12.0 - u_time * 4.0);

  // Delta mix factor
  let delta = (((sin(u_time) + 1.0) / 2.0) * u_duration) / u_duration;

  let finalUV = mix(ripple, uv, delta);

  // Flip Y to match WebGPU convention
  let st = vec2(finalUV.x, 1.0 - finalUV.y);
  let texColor = textureSample(tex, texSampler, st);

  return vec4<f32>(texColor.rgb, 1.0);
}
