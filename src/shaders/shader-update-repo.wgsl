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
    let scale = 20.0;
    let p = pos * scale;

    // smoothstep(edge0, edge1, x)
    return smoothstep(
        0.0,
        0.5 + b * 0.5,
        abs(sin(p.x * 3.1415) + b * 2.0) * 0.5
    );
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let time = transform.params[0][2];

    let speed : f32 = 0.1;                       
    let v     : f32 = 1.0;//sin(transform.params[0][2] * speed) / 1;

    var st = uv.yx * vec2(10., 3. + v / 1);
    var pattern = st.x;

    st = rotate2d(noise(st * 1.0)) * st;

    pattern = lines(st, 0.5);
    

    let col = vec3<f32>(pattern);

    return vec4<f32>(col, 1.0);
}