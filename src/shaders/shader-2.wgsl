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
  
 // mouse in pixels:
  let mx = transform.params[0][0];
  let my = transform.params[0][1];

  // resolution in pixels:
  let rx = transform.params[1].x;
  let ry = transform.params[1].y;

  // normalize to [0,1]:
  let u = 1.0 - (mx / rx);
  let v = my / ry;

  // now you can use u,v however you like:
  // return vec4<f32>(u, u, 0.0, 1.0);
  return vec4<f32>(u, v, 0.0, 1.0);
  // return vec4<f32>(paramsColor);
}