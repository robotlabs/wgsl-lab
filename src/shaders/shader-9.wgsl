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


fn rect(pt: vec2<f32>, anchor: vec2<f32>, size: vec2<f32>, center: vec2<f32>) -> f32{
    let halfsize = size * 0.5;
    let p = pt - center;
    let horz = step(-halfsize.x - anchor.x, p.x) - step(halfsize.x- anchor.x, p.x);
    let vert = step(-halfsize.y - anchor.y, p.y) - step(halfsize.y - anchor.y, p.y);
    return horz * vert;
}

fn getRotationMatrix(theta: f32) -> mat2x2<f32>{
  let s = sin(theta);
  let c = cos(theta);
  return mat2x2<f32>(c, -s, s, c);
}

fn circle(pt: vec2<f32>, center: vec2<f32>, radius: f32, edge_thickness: f32) -> f32{
    let p = pt - center;
    //* you can use len or distance.
    //** IMPORTANT THING TO UNDERSTAND: distance(a, b) == length(a - b)
    let len = length(p);
    let pct = distance(pt, center);
    let result = 1.0 - smoothstep(radius - edge_thickness, radius, pct);
    return result;
}


//* draw a circle. tile 
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>
) -> @location(0) vec4<f32> {
    
    let center = vec2(0.0, 0.0);
    let radius = 0.3;
    let edge_thickness = 0.02;

    let tileCount = 3.0;
    let scaled = worldPos.xy * tileCount;
    let wrapped = fract(scaled);
    let p = wrapped - 0.5;

    let c = circle(p, center, radius, edge_thickness);

    let color = vec3<f32>(1.0, 1.0, 0.0) * c;
    return vec4<f32>(color, 1.0);
}
