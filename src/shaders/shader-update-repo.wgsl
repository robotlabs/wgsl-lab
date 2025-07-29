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

    let speed : f32 = 1.0;                       
    let v     : f32 = sin(transform.params[0][2] * speed) / 1;
    // 1) map UV into noise space
    let st = uv * (5.0);

    // 2) sample noise
    // let n0 = noise(st);

    // 3) estimate gradient via small offsets
    let eps = 0.1;
    let timeM = time * 0.01;
    let dx  = noise(st + vec2<f32>(eps, timeM)) - noise(st - vec2<f32>(eps, 2.0 ));
    let dy  = noise(st + vec2<f32>(1.0, eps)) - noise(st - vec2<f32>(timeM, eps));

    // 4) gradient magnitude = “distance field”
    let dist = length(vec2<f32>(dx, dy));

    // 5) turn that into contour stripes
    let stripes = fract(dist * (20.0 + 0));

    // 6) smoothstep for soft lines
    // let line = smoothstep(0.48, 0.52, stripes);
    // let line = step(0.52, stripes);
    let line = step(0.4, stripes);

    // 7) color ramp between two hues
    let col = mix(
      vec3<f32>(0.2, 0.7, 1.0),   // flat areas
      vec3<f32>(1.0, 0.8, 0.2),   // edges
      line
    );

    // let col2 = vec3(n0);
    return vec4<f32>(col, 1.0);
}