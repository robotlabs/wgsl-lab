// -----------------------------------------
// Constants
// -----------------------------------------
const PI:  f32 = 3.141592653589793;
const PI2: f32 = PI * 2.0;

// -----------------------------------------
// Your existing Transform & VS (unchanged)
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>,  // [0].z = u_time, [1].xy = u_resolution
};
@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv       : vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}


@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z;
    // let u_mouse = transform.params[1].yz;


    let mouse_px    = transform.params[0].xy;
    let resolution = transform.params[1].xy;
    let u_mouse    = mouse_px / resolution;
    // let st = uv * 2.0 - vec2<f32>(1.0);

    let u_center_mouse = vec2<f32>(u_mouse.x, 1.0 - u_mouse.y);
    // let st = (uv - centerUV) * 2.0;
    
    var st = uv;

    // Base color
    var color: vec3<f32> = vec3<f32>(0.0);

    // Cell positions
    var points: array<vec2<f32>, 5>;
    points[0] = vec2<f32>(0.83, 0.75);
    points[1] = vec2<f32>(0.60, 0.07);
    points[2] = vec2<f32>(0.28, 0.64);
    points[3] = vec2<f32>(0.31, 0.26);
    points[4] = u_center_mouse;

    // Find minimum distance to any point
    var m_dist: f32 = 1.0;
    for (var i: u32 = 0u; i < 5u; i = i + 1u) {
        let d: f32 = distance(st, points[i]);
        m_dist = min(m_dist, d);
    }

    // Draw the distance field
    color = color + vec3<f32>(m_dist);

    // Optional isolines (commented out)
    // color = color - vec3<f32>(step(0.7, abs(sin(50.0 * m_dist)))) * 0.3;

    return vec4<f32>(color, 1.0);
}