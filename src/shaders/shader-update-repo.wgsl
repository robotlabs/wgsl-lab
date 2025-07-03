struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>, // [0].xy = mouse, [0].z = time, [1].xy = resolution
};
@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv       : vec2<f32>,
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  // exactly your original vertex shader:
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}

// ------------------------------------------
// Constants
// ------------------------------------------
const PI:  f32 = 3.141592653589;
const PI2: f32 = 6.28318530718;

// ------------------------------------------
// Helper functions
// ------------------------------------------
fn getDelta(val: f32) -> f32 {
  return (sin(val) + 1.0) * 0.5;
}

fn circle(
  pt: vec2<f32>,
  center: vec2<f32>,
  radius: f32,
  line_width: f32,
  edge_thickness: f32
) -> f32 {
  let d = length(pt - center);
  let inner = radius - line_width * 0.5 - edge_thickness;
  let outer = radius + line_width * 0.5 + edge_thickness * 0.5;
  return smoothstep(inner, inner + edge_thickness, d)
       - smoothstep(radius + line_width*0.5, outer, d);
}

fn line(x: f32, y: f32, line_width: f32) -> f32 {
  return smoothstep(x - line_width*0.5, x, y)
       - smoothstep(x, x + line_width*0.5, y);
}

fn sweep(
  pt: vec2<f32>,
  center: vec2<f32>,
  radius: f32,
  line_width: f32,
  edge_thickness: f32,
  time: f32
) -> f32 {
  let d = pt - center;
  let theta = fract(time * (1.0 / 4.0)) * PI2;
  let p = vec2<f32>(cos(theta), sin(theta)) * radius;
  let h = clamp(dot(d, p) / dot(p, p), 0.0, 1.0);
  let l = length(d - p * h);

  var gradient = 0.0;
  if (length(d) < radius) {
    let raw = theta - atan2(d.y, d.x);
    let angle = fract(raw * (1.0 / PI2)) * (PI2 * 0.5);  // mod(raw, PI2)
    gradient = clamp(1.0 - angle, 0.0, 1.0) * 1.5;
  }
  return gradient + 1.0 - smoothstep(line_width, line_width + edge_thickness, l);
}

fn polygon(
  pt: vec2<f32>,
  center: vec2<f32>,
  radius: f32,
  sides: i32,
  rotate: f32,
  edge_thickness: f32
) -> f32 {
  let p = pt - center;
  let theta = atan2(p.x, p.y) + PI + rotate;
  let rad   = PI2 / f32(sides);
  let d     = cos(floor(0.5 + theta / rad) * rad - theta) * length(p);
  return 1.0 - smoothstep(radius, radius + edge_thickness, d);
}

// ------------------------------------------
// Fragment shader
// ------------------------------------------
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
  let time = transform.params[0].z / 20.0;

  var color = vec3<f32>(0.0);

  // axes
  color += line(uv.y, 0.5, 0.002) * vec3<f32>(0.8);
  color += line(uv.x, 0.5, 0.002) * vec3<f32>(0.8);

  // concentric circles
  color += circle(uv, vec2<f32>(0.5), 0.3, 0.002, 0.001) * vec3<f32>(0.8);
  color += circle(uv, vec2<f32>(0.5), 0.2, 0.002, 0.001) * vec3<f32>(0.8);
  color += circle(uv, vec2<f32>(0.5), 0.1, 0.002, 0.001) * vec3<f32>(0.8);

  // sweeping arm (blue)
  color += sweep(uv, vec2<f32>(0.5), 0.3, 0.003, 0.001, time)
         * vec3<f32>(0.1, 0.3, 1.0);

  // rotating small triangles (white)
  
  color += polygon(
    uv,
    vec2<f32>(0.9 - sin(time * 3.0) * 0.05, 0.5),
    0.005, 3, -PI/6.0, 0.001
  ) * vec3<f32>(1.0);
  color += polygon(
    uv,
    vec2<f32>(0.1 - sin(time * 3.0 + PI) * 0.05, 0.5),
    0.005, 3,  PI/6.0, 0.001
  ) * vec3<f32>(1.0);
  color += polygon(
    uv,
    vec2<f32>(0.5, 0.9 - sin(time * 3.0) * 0.05),
    0.005, 3,  PI,     0.001
  ) * vec3<f32>(1.0);
  color += polygon(
    uv,
    vec2<f32>(0.5, 0.1 - sin(time * 3.0 + PI) * 0.05),
    0.005, 3,  0.0,    0.001
  ) * vec3<f32>(1.0);

  return vec4<f32>(color, 1.0);
}