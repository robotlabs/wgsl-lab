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

//* draw a rect and rotate around his own center
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>
) -> @location(0) vec4<f32> {
  
    let radius = 0.25;
    let angle = transform.params[0][2];
    let center = vec2<f32>(0.5, 0.0);
    var pt = worldPos.xy - center;
    let matRot = getRotationMatrix(angle);
    pt = matRot * pt;
    pt += center;
    let sq = rect(pt, vec2(0.2, 0), vec2(0.3), center);

    let color = vec3<f32>(1.0, 1.0, 0.0) * sq;
    return vec4<f32>(color, 1.0);
}


// float rect(vec2 pt, vec2 anchor, vec2 size, vec2 center){
//   //return 0 if not in rect and 1 if it is
//   //step(edge, x) 0.0 is returned if x < edge, and 1.0 is returned otherwise.
//   vec2 p = pt - center;
//   vec2 halfsize = size/2.0;
//   float horz = step(-halfsize.x - anchor.x, p.x) - step(halfsize.x - anchor.x, p.x);
//   float vert = step(-halfsize.y - anchor.y, p.y) - step(halfsize.y - anchor.y, p.y);
//   return horz*vert;
// }

// mat2 getRotationMatrix(float theta){
//   float s = sin(theta);
//   float c = cos(theta);
//   return mat2(c, -s, s, c);
// }

// mat2 getScaleMatrix(float scale){
//   return mat2(scale,0,0,scale);
// }

// void main (void)
// {
//   vec2 center = vec2(0.1, 0.3);
//   vec2 pt = vPosition.xy - center;
//   mat2 matr = getRotationMatrix(u_time);
//   mat2 mats = getScaleMatrix((sin(u_time)+1.0)/3.0 + 0.5);
//   pt = mats * matr * pt;
//   pt += center;
//   vec3 color = u_color * rect(pt, vec2(0.0), vec2(0.3), center);
//   gl_FragColor = vec4(color, 1.0); 
// }
// `
