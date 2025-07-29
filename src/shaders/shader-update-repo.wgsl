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

//* 2D random
fn random (st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

//* value noise by Inigo Quilez
fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);


    let u = f * f * (3.0 - 2.0 * f);

    let aa = mix(random(i + vec2<f32>(0.0, 0.0)), random(i + vec2<f32>(1.0, 0.0)), u.x );
    let bb = mix(random(i + vec2<f32>(0.0, 1.0)), random(i + vec2<f32>(1.0, 1.0)), u.x );

    let finalValue = mix(aa, bb, u.y);
    
    return finalValue;
}

// 2×2 rotation matrix around the origin
fn rotate2d(angle: f32) -> mat2x2<f32> {
    // mat2x2<f32>(col0.x, col0.y, col1.x, col1.y)
    return mat2x2<f32>(
        cos(angle), -sin(angle),
        sin(angle),  cos(angle)
    );
}

// a simple “striped” function
fn lines(pos: vec2<f32>, b: f32) -> f32 {
    // stretch the pattern
    let scale = 5.0;
    let p = pos * scale;

    // // smoothstep(edge0, edge1, x)
    // return smoothstep(
    //     0.0,
    //     0.5 + b * 0.5,
    //     abs(sin(p.x * 3.1415) + b * 2.0) * 0.5
    // );

    let v = abs(sin(p.x * 3.1415) + b * 2.0) * 0.5;
    let threshold: f32 = 0.5;            // regola spessore qui
    return step(threshold, v);           // linee “piene”, non sfumate
}

fn noiseSeeded(st: vec2<f32>, seed: f32) -> f32 {
    let i = floor(st);
    let f = fract(st);
    let u = f * f * (3.0 - 2.0 * f);
    // offset the random lookup by seed (same at all corners)
    let svec = vec2<f32>(seed, seed * 1.37);

    let a = random(i + svec + vec2<f32>(0.0, 0.0));
    let b = random(i + svec + vec2<f32>(1.0, 0.0));
    let c = random(i + svec + vec2<f32>(0.0, 1.0));
    let d = random(i + svec + vec2<f32>(1.0, 1.0));

    let aa = mix(a, b, u.x);
    let bb = mix(c, d, u.x);
    return mix(aa, bb, u.y);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let time = transform.params[0][2] / 50;

    // Prepare base UV for stripe pattern
    var st = uv.yx * vec2<f32>(5.0, 3.0);

    // --- Multi-octave noise approach (inspired by your GLSL snippet) ---
    var n: vec2<f32> = vec2<f32>(0.0);
    var pos: vec2<f32>;
    // octave 1 for x
    pos = vec2<f32>(uv.x * 1.4 + 0.01, uv.y - time * 0.69);
    n.x     = noise(pos * 12.0);
    // octave 2 for x
    pos = vec2<f32>(uv.x * 0.5 - 0.033, uv.y * 2.0 - time * 0.12);
    n.x    += noise(pos * 8.0);
    // octave 3 for x
    pos = vec2<f32>(uv.x * 0.94 + 0.02, uv.y * 3.0 - time * 0.61);
    n.x    += noise(pos * 4.0);

    // octave 1 for y
    pos = vec2<f32>(uv.x * 0.7 - 0.01, uv.y - time * 0.27);
    n.y     = noise(pos * 12.0);
    // octave 2 for y
    pos = vec2<f32>(uv.x * 0.45 + 0.033, uv.y * 1.9 - time * 0.61);
    n.y    += noise(pos * 8.0);
    // octave 3 for y
    pos = vec2<f32>(uv.x * 0.8 - 0.02, uv.y * 2.5 - time * 0.51);
    n.y    += noise(pos * 4.0);
    // normalize
    n       = n / 2.3;
    // -------------------------------------------------------------------

    // Use n.x to drive rotation angle organically
    let angle = (n.x * 2.0 - 1.0) * PI;  // remap [0,1]→[-π,π]
    st = rotate2d(angle) * st;

    // Use n.y to vary stripe softness parameter b
    let b     = mix(0.2, 0.5, n.y);      // blend between 0.2 and 0.8
    let pattern = lines(st, b);

    // define your two colors here:
    let colorA = vec3<f32>(1.0, 0.0, 0.6); // warm red
    let colorB = vec3<f32>(1.0, 0.3, 1.0); // cool blue
    // mix based on pattern (0 = all A, 1 = all B)
    let col = mix(colorA, colorB, pattern);
    return vec4<f32>(col, 1.0);

}