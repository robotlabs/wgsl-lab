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
  
  return output;
}


// mix color based on screen position

//* using frag coord, so based on the total screen
// @fragment
// fn fs_main(
//   @location(0) fragColor: vec4<f32>,
//   @builtin(position) fragCoord: vec4<f32>
// ) -> @location(0) vec4<f32> {
//   let res = transform.params[1].xy;
//   let uv = fragCoord.xy / res;

//   let color = mix(vec3<f32>(1.0, 0.0, 0.0), vec3<f32>(0.0, 0.0, 1.0), uv.y);
//   return vec4<f32>(color, 1.0);
// }

//* using uv coord, so based on my geometry
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>
) -> @location(0) vec4<f32> {
  let color = mix(vec3<f32>(1.0, 0.0, 0.0), vec3<f32>(0.0, 0.0, 1.0), uv.y);
  return vec4<f32>(color, 1.0);
}