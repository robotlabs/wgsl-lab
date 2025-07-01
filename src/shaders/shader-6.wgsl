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



//* using step
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>
) -> @location(0) vec4<f32> {

let mx = transform.params[0][0];
  let my = transform.params[0][1];

  // resolution in pixels:
  let rx = transform.params[1].x;
  let ry = transform.params[1].y;

  // normalize to [0,1]:
  let u = -1.0 + (mx / rx) * 2.0 ;
  let v = 1.0 - (my / ry) * 2.0;

  //* step and smoothstep example
  var color = vec3<f32>(0.0);
  color.r = step(u, worldPos.x);
  color.g = step(v, worldPos.y);
//   return vec4<f32>(color, 1.0);

    var color2= vec3<f32>(0.0);
  color2.r = smoothstep(u, u+ 0.1, worldPos.x);
  color2.g = smoothstep(v, v + 0.1, worldPos.y);
  return vec4<f32>(color2, 1.0);

  
}