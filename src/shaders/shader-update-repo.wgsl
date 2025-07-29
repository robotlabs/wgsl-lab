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

//* 2D noise (mcGuire)
fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);

    let a = random(i);
    let b = random(i + vec2(1.0, 0.0));
    let c = random(i + vec2(0.0, 1.0));
    let d = random(i + vec2(1.0, 1.0));

    let u = f * f * (3.0 - 2.0 * f);

    let finalValue = mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
    
    return finalValue;
}

// 3‑component hash
fn random3(p: vec3<f32>) -> f32 {
    return fract(sin(dot(p, vec3<f32>(12.9898,78.233,37.719))) * 43758.5453123);
}

// 3D noise by trilinear interpolation
fn noise3(p: vec3<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);

    // eight corners of the cube
    let a = random3(i + vec3<f32>(0,0,0));
    let b = random3(i + vec3<f32>(1,0,0));
    let c = random3(i + vec3<f32>(0,1,0));
    let d = random3(i + vec3<f32>(1,1,0));
    let e = random3(i + vec3<f32>(0,0,1));
    let f1= random3(i + vec3<f32>(1,0,1));
    let g = random3(i + vec3<f32>(0,1,1));
    let h = random3(i + vec3<f32>(1,1,1));

    // blend in X
    let xy0 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    let xy1 = mix(mix(e,f1,u.x), mix(g,h,u.x), u.y);
    // blend in Z (time)
    return mix(xy0, xy1, u.z);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let time = transform.params[0][2];

    // — base colors for our three bands —
    let c0 = vec3<f32>(0.7, 0.1, 0.1);  // deep red
    let c1 = vec3<f32>(0.8, 1.0, 0.0);  // brighter red
    let c2 = vec3<f32>(0.9, 0.7, 0.2);  // golden

    // — simple 3D noise for texture & edge softening —
    let scaleNoise = 10.0;
    let speed      = 0.2;
    let n          = noise3(vec3<f32>(uv * scaleNoise, time * speed));

    // a small, time‑varying wiggle on our boundaries:
    let wiggle = n * 0.02;

    // — define three vertical masks with soft, noisy edges —
    let eps = 0.01;
    // left band: uv.x ∈ [0, 0.3]
    let m0 = smoothstep(0.0 - eps + wiggle, 0.0 + eps + wiggle, uv.x)
           * (1.0 - smoothstep(0.2 - eps + wiggle, 0.2 + eps + wiggle, uv.x));
    // middle band: uv.x ∈ [0.3, 0.6]
    let m1 = smoothstep(0.4 - eps - wiggle, 0.4 + eps - wiggle, uv.x)
           * (1.0 - smoothstep(0.6 - eps - wiggle, 0.6 + eps - wiggle, uv.x));
    // right band: uv.x ∈ [0.6, 1.0]
    let m2 = smoothstep(0.78 - eps + wiggle, 0.78 + eps + wiggle, uv.x)
           * (1.0 - smoothstep(0.98 - eps + wiggle, 0.98 + eps + wiggle, uv.x));

    // — composite: start with black background —
    var col = vec3<f32>(0.0);

    // layer in each band
    col = mix(col, c0, m0);
    col = mix(col, c1, m1);
    col = mix(col, c2, m2);

    // — lightly modulate brightness by another noise for painterly texture —
    let tex = noise3(vec3<f32>(uv * (scaleNoise*2.0), time * speed*0.5)) * 0.1;
    col += tex;

    return vec4<f32>(col, 1.0);
}