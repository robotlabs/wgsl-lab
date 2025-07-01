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


fn rotate2d(angle: f32) -> mat2x2<f32> {
    let c = cos(angle);
    let s = sin(angle);
    return mat2x2<f32>(
        vec2<f32>(c, -s),
        vec2<f32>(s,  c)
    );
}

fn box(st: vec2<f32>, size: vec2<f32>) -> f32 {
    let halfSize = vec2<f32>(0.5) - size * 0.5;
    let uv = smoothstep(halfSize, halfSize + vec2<f32>(0.001), st) *
             smoothstep(halfSize, halfSize + vec2<f32>(0.001), vec2<f32>(1.0) - st);
    return uv.x * uv.y;
}

fn cross(st: vec2<f32>, size: f32) -> f32 {
    return box(st, vec2<f32>(size, size / 4.0)) +
           box(st, vec2<f32>(size / 4.0, size));
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) worldPos: vec3<f32>,
  @builtin(position) fragCoord: vec4<f32>
) -> @location(0) vec4<f32> {
    let u_time = transform.params[0][2] / 10.0;
    let u_mouse_x = transform.params[0][0] / 1.0 / transform.params[1][0];
    let u_mouse_y = 1.0 - transform.params[0][1] / 1.0 / transform.params[1][1];

    var st = uv;
    
    st -= vec2<f32>(u_mouse_x, u_mouse_y); // center at (0,0)
    st = rotate2d(sin(u_time) * 3.1415926) * st;
    st += vec2<f32>(0.5); // back to uv space

    let shape = cross(st, 0.4);
    let color = vec3<f32>(shape);

    return vec4<f32>(color, 1.0);
}

