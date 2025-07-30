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

fn random2( p: vec2<f32> ) -> vec2<f32> {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z / 10;
    let mouse_px    = transform.params[0].xy;
    let resolution = transform.params[1].xy;
    let u_mouse    = mouse_px / resolution;
    let u_center_mouse = vec2<f32>(u_mouse.x, 1.0 - u_mouse.y);
    
    var st = uv;

    st *= 10.;
  // Tile the space
    let i_st = floor(st);
    let f_st = fract(st);

    var color = vec3(0.);
    
     var m_dist: f32 = 2.0;  // minimum distance
    var m_point: vec2<f32>;  // minimum point

    // Search in 3x3 neighborhood
    for (var j: i32 = -1; j <= 1; j++) {
        for (var i: i32 = -1; i <= 1; i++) {
            let neighbor = vec2<f32>(f32(i), f32(j));
            var point = random2(i_st + neighbor);
            point = 0.2 + 0.5 * sin(u_time + 12.0 * PI * point);
            let diff = neighbor + point - f_st;
            let dist = length(diff);

            if (dist < m_dist) {
                m_dist = dist;
                m_point = point;
            }
        }
    }

    // Assign color using closest point
    color += dot(m_point, vec2<f32>(0.1, 0.9));

    // Show isolines (commented out in original)
    color -= abs(sin(60.0 * m_dist)) * 0.04;

    // Draw cell center
    // color += 1.0 - step(0.05, m_dist);

    // Draw grid
    // color.r += step(0.98, f_st.x) + step(0.98, f_st.y);

    return vec4<f32>(color, 1.0);
}