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




// hash 1D
fn random1(x: f32) -> f32 {
    return fract(sin(x) * 43758.5453123);
}

// noise 1D periodica di periodo `p`
fn noisePeriodic(x: f32, p: f32) -> f32 {
    let i  = floor(x);
    let f  = fract(x);
    // wrap degli indici interi in [0, p)
    let i0 = i - floor(i / p) * p;
    let i1 = i0 + 1.0;
    let i1w = i1 - floor(i1 / p) * p;
    // easing cubico
    let u = f * f * (3.0 - 2.0 * f);
    // interpolazione tra random1(i0) e random1(i1w)
    return mix(random1(i0), random1(i1w), u);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let time = transform.params[0][2];
    let st = uv * 2.0 - vec2<f32>(1.0);
    let angle  = atan2(st.y, st.x);
    let radius = length(st);
    let a = (angle + PI) / (2.0 * PI);

    let speed : f32 = 0.2;                       
    let v     : f32 = sin(transform.params[0][2] * speed);

    // noise periodica
    let cycles = 8.0;   
    let raw    = a * cycles + time * 0.2+ 0;
    let n      = noisePeriodic(raw, cycles);
    let r      = 0.5 + n * (0.05  + v / 10);

    //** smooth border
    let thickness = 0.05;
    // let d = smoothstep(r, r - thickness, radius);
    // let outsideCol  = vec3<f32>(1.0, 1.0, 0.0); 
    // let insideCol = vec3<f32>(0.0, v, v); 

    //no smooth border
    let d = step(r, radius);
    let insideCol  = vec3<f32>(1.0, 1.0, 0.0); 
    let outsideCol = vec3<f32>(0.0, v, v); 
    


    let color = mix(outsideCol, insideCol, d);

    return vec4<f32>(color, 1.0);
}
