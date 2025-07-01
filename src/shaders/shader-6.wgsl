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


fn rect(pt: vec2<f32>, size: vec2<f32>, center: vec2<f32>) -> f32{
    let halfsize = size * 0.5;
    let p = pt - center;
    let horz = step(-halfsize.x, p.x) - step(halfsize.x, p.x);
    let vert = step(-halfsize.y, p.y) - step(halfsize.y, p.y);
    return horz * vert;
}

//* draw a rect
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>
) -> @location(0) vec4<f32> {
  
    let center = vec2<f32>(0.70, 0);
    let square = rect(worldPos.xy, vec2<f32>(0.5, 0.5), center);

    let color = vec3<f32>(1.0, 1.0, 0.0) * square;
    return vec4<f32>(color, 1.0);
}