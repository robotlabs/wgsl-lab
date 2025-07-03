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

fn plot(st: vec2<f32>) -> f32 {    
    return smoothstep(0.01, 0.0, abs(st.y - st.x));
}
fn plot2(st: vec2<f32>, pct:f32)  -> f32 {
  return  smoothstep( pct-0.02, pct, st.y) -
          smoothstep( pct, pct+0.02, st.y);
}

fn slopeFromT(t: f32, A: f32, B: f32, C: f32) -> f32 {
  return 1.0 / (3.0 * A * t * t + 2.0 * B * t + C);
}

fn xFromT(t: f32, A: f32, B: f32, C: f32, D: f32) -> f32 {
  return A * t * t * t + B * t * t + C * t + D;
}

fn yFromT(t: f32, E: f32, F: f32, G: f32, H: f32) -> f32 {
  return E * t * t * t + F * t * t + G * t + H;
}

fn constrain(x: f32, minVal: f32, maxVal: f32) -> f32 {
  return clamp(x, minVal, maxVal);
}

fn cubicBezier(x: f32, a: f32, b: f32, c: f32, d: f32) -> f32 {
  let y0a = 0.0;
  let x0a = 0.0;
  let y1a = b;
  let x1a = a;
  let y2a = d;
  let x2a = c;
  let y3a = 1.0;
  let x3a = 1.0;

  let A = x3a - 3.0 * x2a + 3.0 * x1a - x0a;
  let B = 3.0 * x2a - 6.0 * x1a + 3.0 * x0a;
  let C = 3.0 * x1a - 3.0 * x0a;
  let D = x0a;

  let E = y3a - 3.0 * y2a + 3.0 * y1a - y0a;
  let F = 3.0 * y2a - 6.0 * y1a + 3.0 * y0a;
  let G = 3.0 * y1a - 3.0 * y0a;
  let H = y0a;

  var currentt = x;
  for (var i = 0; i < 5; i = i + 1) {
    let currentx = xFromT(currentt, A, B, C, D);
    let slope = slopeFromT(currentt, A, B, C);
    currentt = constrain(currentt - (currentx - x) * slope, 0.0, 1.0);
  }

  return yFromT(currentt, E, F, G, H);
}

@fragment
fn fs_main(@location(1) uv: vec2<f32>) -> @location(0) vec4<f32> {
  // control points
  let p0x = 0.6; // x1
  let p0y = 0.0; // y1
  let p1x = 0.2; // x2
  let p1y = 1.0; // y2

  let y = cubicBezier(uv.x, p0x, p0y, p1x, p1y);

  // draw green curve line
  let edge = smoothstep(y - 0.01, y, uv.y) - smoothstep(y, y + 0.01, uv.y);

  // below the curve white, above black
  let base = select(vec3<f32>(0.0), vec3<f32>(1.0), uv.y < y);
  let color = mix(base, vec3<f32>(0.0, 1.0, 0.0), edge);

  return vec4<f32>(color, 1.0);
}