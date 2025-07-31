// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform struct (unchanged)
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>, // [0].z = u_time, [1].xy = u_resolution
};

@group(0) @binding(0) var<uniform> transform: Transform;

// -----------------------------------------
// Vertex Output
// -----------------------------------------
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

// -----------------------------------------
// Noise Functions
// -----------------------------------------
fn random(st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);
    let a = random(i);
    let b = random(i + vec2<f32>(1.0, 0.0));
    let c = random(i + vec2<f32>(0.0, 1.0));
    let d = random(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

fn fbm(st_input: vec2<f32>) -> f32 {
    var v: f32 = 0.0;
    var a: f32 = 0.5;
    var st = st_input;

    let shift = vec2<f32>(100.0, 100.0);
    let rot = mat2x2<f32>(
        cos(0.5), sin(0.5),
        -sin(0.5), cos(0.5)
    );

    for (var i = 0; i < 5; i++) {
        v += a * noise(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }

    return v;
}


// -----------------------------------------
// Fragment Shader
// -----------------------------------------
@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z;

    var st = uv * 3.0;
    st.x *= u_resolution.x / u_resolution.y;

    var q = vec2<f32>(0.0);
    q.x = fbm(st + 0.0 * u_time);
    q.y = fbm(st + vec2<f32>(1.0, 0.0));

    var r = vec2<f32>(0.0);
    r.x = fbm(st + 1.0 * q + vec2<f32>(1.7, 9.2) + 0.15 * u_time);
    r.y = fbm(st + 1.0 * q + vec2<f32>(8.3, 2.8) + 0.126 * u_time);

    let f = fbm(st + r);

    var color = mix(
        vec3<f32>(0.101961, 0.619608, 0.666667),
        vec3<f32>(0.666667, 0.666667, 0.498039),
        clamp(f * f * 4.0, 0.0, 1.0)
    );

    color = mix(
        color,
        vec3<f32>(0.0, 0.0, 0.164706),
        clamp(length(q), 0.0, 1.0)
    );

    color = mix(
        color,
        vec3<f32>(0.666667, 1.0, 1.0),
        clamp(abs(r.x), 0.0, 1.0)
    );

    let finalColor = (f*f*f + 0.6*f*f + 0.5*f) * color;
    return vec4<f32>(finalColor, 1.0);
}
