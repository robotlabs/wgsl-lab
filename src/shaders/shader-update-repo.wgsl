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

fn quadraticBezier(x: f32, a: f32, b: f32) -> f32 {
    let epsilon = 0.00001;
    let a_clamped = clamp(a, 0.0, 1.0);
    let b_clamped = clamp(b, 0.0, 1.0);

    // avoid division by zero if a == 0.5
    let a_safe = select(a_clamped, a_clamped + epsilon, a_clamped == 0.5);

    let om2a = 1.0 - 2.0 * a_safe;
    let t = (sqrt(a_safe * a_safe + om2a * x) - a_safe) / om2a;
    let y = (1.0 - 2.0 * b_clamped) * (t * t) + (2.0 * b_clamped) * t;

    return y;
}

fn oscillateBetween(a: f32, b: f32, time: f32, speed: f32) -> f32 {
  let t = sin(time * speed) * 0.5 + 0.5; // oscillates in [0, 1]
  return mix(a, b, t);
}

@fragment
fn fs_main(@location(1) uv: vec2<f32>) -> @location(0) vec4<f32> {
    // Control points a and b
    let anchorA_Base = 0.75;
    let anchorB_Base = 0.25;



    let speed1 = 0.5; // 1 cycle per 2π seconds
    let speed2 = 1.0; // 1 cycle per 2π seconds
    let maxOscillate = 0.75;
    let animatedA = oscillateBetween(anchorA_Base, anchorA_Base - maxOscillate, transform.params[0][2], speed1);
    let animatedB = oscillateBetween(anchorB_Base, anchorB_Base + maxOscillate, transform.params[0][2], speed2);
    // Bézier curve value at uv.x
    let y = quadraticBezier(uv.x, animatedA, animatedB);
    //   let y = quadraticBezier(uv.x, 0.5, 0.5); // a & b centered

    // Draw the green curve
    let edge = plot2(uv, y);

    // White below, black above
    let baseColor = select(vec3<f32>(0.0), vec3<f32>(1.0), uv.y < y);

    // Mix in green curve line
    let finalColor = mix(baseColor, vec3<f32>(0.0, 1.0, 0.0), edge);

    return vec4<f32>(finalColor, 1.0);
}

// fn fs_main(@location(1) uv: vec2<f32>) -> @location(0) vec4<f32> {
//   let anchorA = 0.75;
//   let anchorB = 0.25;
//   let speed = 1.0;
//   let amp = 0.75;

//   let animatedA = oscillateBetween(anchorA, anchorA - amp, transform.params[0][2], speed);
//   let animatedB = 0.0;//oscillateBetween(anchorB, anchorB + amp, transform.params[0][2], speed);

//   let y = quadraticBezier(uv.x, animatedA, animatedB);
//   let edge = plot2(uv, y);
//   let base = select(vec3<f32>(0.0), vec3<f32>(1.0), uv.y < y);
//   let color = mix(base, vec3<f32>(0.0, 1.0, 0.0), edge);
//   return vec4<f32>(color, 1.0);
// }