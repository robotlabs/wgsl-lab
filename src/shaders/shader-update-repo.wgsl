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

// -----------------------------------------
// Simplex Noise Functions
// -----------------------------------------

// Some useful functions
fn mod289_vec3(x: vec3<f32>) -> vec3<f32> { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

fn mod289_vec2(x: vec2<f32>) -> vec2<f32> { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

fn permute(x: vec3<f32>) -> vec3<f32> { 
  return mod289_vec3(((x * 34.0) + 1.0) * x); 
}

//
// Description : WGSL 2D simplex noise function
//      Author : Ian McEwan, Ashima Arts (original GLSL)
//  Converted to WGSL
//
fn snoise(v: vec2<f32>) -> f32 {
    // Precompute values for skewed triangular grid
    let C = vec4<f32>(0.211324865405187,    // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,    // 0.5*(sqrt(3.0)-1.0)
                      -0.577350269189626,   // -1.0 + 2.0 * C.x
                      0.024390243902439);   // 1.0 / 41.0
    
    // First corner (x0)
    let i = floor(v + dot(v, C.yy));
    let x0 = v - i + dot(i, C.xx);
    
    // Other two corners (x1, x2)
    var i1: vec2<f32>;
    if (x0.x > x0.y) {
        i1 = vec2<f32>(1.0, 0.0);
    } else {
        i1 = vec2<f32>(0.0, 1.0);
    }
    let x1 = x0.xy + C.xx - i1;
    let x2 = x0.xy + C.zz;
    
    // Do some permutations to avoid truncation effects in permutation
    let i_mod = mod289_vec2(i);
    let p = permute(
        permute(i_mod.y + vec3<f32>(0.0, i1.y, 1.0)) + 
        i_mod.x + vec3<f32>(0.0, i1.x, 1.0)
    );
    
    var m = max(0.5 - vec3<f32>(
        dot(x0, x0),
        dot(x1, x1),
        dot(x2, x2)
    ), vec3<f32>(0.0));
    m = m * m;
    m = m * m;
    
    // Gradients:
    //  41 pts uniformly over a line, mapped onto a diamond
    //  The ring size 17*17 = 289 is close to a multiple
    //      of 41 (41*7 = 287)
    let x = 2.0 * fract(p * C.www) - 1.0;
    let h = abs(x) - 0.5;
    let ox = floor(x + 0.5);
    let a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt(a0*a0 + h*h);
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    
    // Compute final noise value at P
    var g: vec3<f32>;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.y = a0.y * x1.x + h.y * x1.y;
    g.z = a0.z * x2.x + h.z * x2.y;
    
    return 130.0 * dot(m, g);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z;
    
    var st = uv;

    //* this is pointless because we are using in a plane square
    // st.x *= u_resolution.x / u_resolution.y;
    
    var color = vec3<f32>(0.0);
    let pos = st * 3.0;
    var DF = 0.0;
    
    // Add a random position
    var a = 0.0;
    var vel = vec2<f32>(0.0, -u_time * 0.1);//vec2<f32>(u_time * 0.1);
    // var vel = vec2<f32>(u_time * 0.1);

    var t = abs(sin(u_time / 4) + 2.0);
    DF += snoise(pos + vel) * t + 0.25;
    // DF += snoise(pos);// + vel) * .25 + 0.25;
    
    // Add a random position
    a = snoise(pos * vec2<f32>(cos(u_time * 0.15), sin(u_time * 0.1)) * 0.1) * 3.1415;
    vel = vec2<f32>(cos(a), sin(a));
    DF += snoise(pos + vel) * 0.25 + 0.25;
    
    color = vec3<f32>(smoothstep(0.44, 0.75, fract(DF)));
    
    return vec4<f32>(1.0 - color, 1.0);
}