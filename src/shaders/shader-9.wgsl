struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix: mat4x4<f32>,
  projMatrix: mat4x4<f32>,
  color: vec4<f32>,
  useTexture  : vec4<f32>,
  params: array<vec4<f32>, 2>
};

@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>,  // 👈 new
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var output: VertexOutput;
  output.Position = transform.projMatrix * transform.viewMatrix * world;
  output.fragColor = transform.color;
  output.uv = (position.xy + vec2<f32>(1.0)) * 0.5;
  output.worldPos = world.xyz; // 👈 pass world-space position
  
  return output;
}




@fragment
fn fs_main(
  @builtin(position) fragCoord: vec4<f32>,
  @location(1) uv: vec2<f32>
) -> @location(0) vec4<f32> {
  // Normalize coordinates
//   let uResX = transform.params[1][0];
//   let uResY = transform.params[1][1];
//   var st = uv / uResX;
//   st.x *= transform.params[1][0] / uResY;

     var st = uv * 2.0 - vec2<f32>(1.0);
  let normalizedTime = sin(transform.params[0][2] / 10.0);
  let d = length(abs(st) - normalizedTime);

  let color = vec3<f32>(fract(d * 10.0));

  

  return vec4<f32>(color, 1.0);
  return vec4<f32>(vec3<f32>( smoothstep(0.3, 0.4,d)* smoothstep(0.6,0.5,d)) ,1.0);
}