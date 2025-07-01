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
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var output: VertexOutput;
  output.Position = transform.projMatrix * transform.viewMatrix * world;
  output.fragColor = transform.color;
  
  return output;
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
) -> @location(0) vec4<f32> {
  
  let finalColor = fragColor.rgba;
//   let finalColor = fragColor.grba;
// let r = transform.params[0][0];
// let g = transform.params[0][1];
// let b = transform.params[0][2];

// let r2 = transform.params[1][0];
// let g2 = transform.params[1][1];
// let b2 = transform.params[1][2];
//   return vec4<f32>(r2, g2, b2, 1.0);
  
  return vec4<f32>(finalColor);
}