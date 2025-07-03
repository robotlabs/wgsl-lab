struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>,
};

@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv:        vec2<f32>,
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  let world    = transform.modelMatrix * vec4<f32>(position, 1.0);
  var output: VertexOutput;
  output.Position = transform.projMatrix * transform.viewMatrix * world;
  output.fragColor = transform.color;
  // assume your quad’s positions run from -1..1 in XY
  output.uv = (position.xy + vec2<f32>(1.0)) * 0.5;
  return output;
}

// — Bernstein basis
fn B0(t: f32) -> f32 { return (1.0 - t)*(1.0 - t)*(1.0 - t); }
fn B1(t: f32) -> f32 { return 3.0*t*(1.0 - t)*(1.0 - t); }
fn B2(t: f32) -> f32 { return 3.0*t*t*(1.0 - t); }
fn B3(t: f32) -> f32 { return t*t*t; }

fn cubicBezierNearlyThroughTwoPoints(
    x: f32,
    a: f32, b: f32,   // “must‐pass-near” point #1
    c: f32, d: f32    // “must-pass-near” point #2
) -> f32 {
  let eps: f32 = 1e-5;

  // clamp the “through” points inside (0,1)
  let aa = clamp(a, eps, 1.0 - eps);
  let bb = clamp(b, eps, 1.0 - eps);

  // fixed endpoints
  let x0 = 0.0; let y0 = 0.0;
  let x4 = aa;  let y4 = bb;
  let x5 = c;   let y5 = d;
  let x3 = 1.0; let y3 = 1.0;

  // choose parameter values for the “near” constraints
  let t1 = 0.3;
  let t2 = 0.7;

  // precompute Bernstein at t1
  let B0t1 = B0(t1);
  let B1t1 = B1(t1);
  let B2t1 = B2(t1);
  let B3t1 = B3(t1);
  // and at t2
  let B0t2 = B0(t2);
  let B1t2 = B1(t2);
  let B2t2 = B2(t2);
  let B3t2 = B3(t2);

  // setup two linear eqns
  let ccx = x4 - x0 * B0t1 - x3 * B3t1;
  let ccy = y4 - y0 * B0t1 - y3 * B3t1;
  let ffx = x5 - x0 * B0t2 - x3 * B3t2;
  let ffy = y5 - y0 * B0t2 - y3 * B3t2;

  // solve for interior controls x2,y2 then x1,y1
  var x2 = (ccx - (ffx * B1t1) / B1t2)
         / (B2t1 - (B1t1 * B2t2) / B1t2);
  var y2 = (ccy - (ffy * B1t1) / B1t2)
         / (B2t1 - (B1t1 * B2t2) / B1t2);

  var x1 = (ccx - x2 * B2t1) / B1t1;
  var y1 = (ccy - y2 * B2t1) / B1t1;

  x1 = clamp(x1, eps, 1.0 - eps);
  x2 = clamp(x2, eps, 1.0 - eps);

  // now evaluate the standard cubic Bézier at parameter x
  // control points: (0,0), (x1,y1), (x2,y2), (1,1)
  let A = 1.0 - 3.0*x2 + 3.0*x1 - 0.0;
  let B = 3.0*x2 - 6.0*x1 + 0.0;
  let C = 3.0*x1 - 0.0;
  let D = 0.0;

  let E = 1.0 - 3.0*y2 + 3.0*y1 - 0.0;
  let F = 3.0*y2 - 6.0*y1 + 0.0;
  let G = 3.0*y1 - 0.0;
  let H = 0.0;

  var t = x;
  // Newton–Raphson to invert x→t
  for (var i = 0; i < 5; i = i + 1) {
    let fx  = A*t*t*t + B*t*t + C*t + D;
    let dfx = 3.0*A*t*t + 2.0*B*t + C;
    t = clamp(t - (fx - x) / dfx, 0.0, 1.0);
  }

  // evaluate y(t)
  return clamp(E*t*t*t + F*t*t + G*t + H, 0.0, 1.0);
}

@fragment
fn fs_main(@location(1) uv: vec2<f32>) -> @location(0) vec4<f32> {
  // pick two points to “nearly” pass through
  let time = 0.0;//transform.params[0][2] / 90.0;
  let px1 = 0.1;  let py1 = 0.3  + time;

  let px2 = 0.2;  let py2 = 1.0;

  let y = cubicBezierNearlyThroughTwoPoints(uv.x, px1, py1, px2, py2);

  let edge = smoothstep(y - 0.005, y, uv.y)
           - smoothstep(y, y + 0.005, uv.y);
  let base = select(vec3<f32>(0.0), vec3<f32>(1.0), uv.y < y);
  let color = mix(base, vec3<f32>(0.0, 1.0, 0.0), edge);

  return vec4<f32>(color, 1.0);
}
