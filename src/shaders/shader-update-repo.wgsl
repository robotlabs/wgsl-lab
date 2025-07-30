// Author: Stefan Gustavson (converted to WGSL)
// Title: Classic 3D cellular noise

// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform struct
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

@vertex fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}

// Permutation polynomial: (34x^2 + x) mod 289
fn permute(x: vec3<f32>) -> vec3<f32> {
  return ((34.0 * x + 1.0) * x) % 289.0;
}

// Cellular noise, returning F1 and F2 in a vec2.
// 3x3x3 search region for good F2 everywhere, but a lot
// slower than the 2x2x2 version.
fn cellular(P: vec3<f32>) -> vec2<f32> {
  let K = 0.142857142857;     // 1/7
  let Ko = 0.428571428571;    // 1/2-K/2
  let K2 = 0.020408163265306; // 1/(7*7)
  let Kz = 0.166666666667;    // 1/6
  let Kzo = 0.416666666667;   // 1/2-1/6*2
  let jitter = 1.0;           // smaller jitter gives more regular pattern

  let Pi = floor(P) % 289.0;
  let Pf = fract(P) - 0.5;

  let Pfx = Pf.x + vec3<f32>(1.0, 0.0, -1.0);
  let Pfy = Pf.y + vec3<f32>(1.0, 0.0, -1.0);
  let Pfz = Pf.z + vec3<f32>(1.0, 0.0, -1.0);

  let p = permute(Pi.x + vec3<f32>(-1.0, 0.0, 1.0));
  let p1 = permute(p + Pi.y - 1.0);
  let p2 = permute(p + Pi.y);
  let p3 = permute(p + Pi.y + 1.0);

  let p11 = permute(p1 + Pi.z - 1.0);
  let p12 = permute(p1 + Pi.z);
  let p13 = permute(p1 + Pi.z + 1.0);

  let p21 = permute(p2 + Pi.z - 1.0);
  let p22 = permute(p2 + Pi.z);
  let p23 = permute(p2 + Pi.z + 1.0);

  let p31 = permute(p3 + Pi.z - 1.0);
  let p32 = permute(p3 + Pi.z);
  let p33 = permute(p3 + Pi.z + 1.0);

  let ox11 = fract(p11 * K) - Ko;
  let oy11 = (floor(p11 * K) % 7.0) * K - Ko;
  let oz11 = floor(p11 * K2) * Kz - Kzo;

  let ox12 = fract(p12 * K) - Ko;
  let oy12 = (floor(p12 * K) % 7.0) * K - Ko;
  let oz12 = floor(p12 * K2) * Kz - Kzo;

  let ox13 = fract(p13 * K) - Ko;
  let oy13 = (floor(p13 * K) % 7.0) * K - Ko;
  let oz13 = floor(p13 * K2) * Kz - Kzo;

  let ox21 = fract(p21 * K) - Ko;
  let oy21 = (floor(p21 * K) % 7.0) * K - Ko;
  let oz21 = floor(p21 * K2) * Kz - Kzo;

  let ox22 = fract(p22 * K) - Ko;
  let oy22 = (floor(p22 * K) % 7.0) * K - Ko;
  let oz22 = floor(p22 * K2) * Kz - Kzo;

  let ox23 = fract(p23 * K) - Ko;
  let oy23 = (floor(p23 * K) % 7.0) * K - Ko;
  let oz23 = floor(p23 * K2) * Kz - Kzo;

  let ox31 = fract(p31 * K) - Ko;
  let oy31 = (floor(p31 * K) % 7.0) * K - Ko;
  let oz31 = floor(p31 * K2) * Kz - Kzo;

  let ox32 = fract(p32 * K) - Ko;
  let oy32 = (floor(p32 * K) % 7.0) * K - Ko;
  let oz32 = floor(p32 * K2) * Kz - Kzo;

  let ox33 = fract(p33 * K) - Ko;
  let oy33 = (floor(p33 * K) % 7.0) * K - Ko;
  let oz33 = floor(p33 * K2) * Kz - Kzo;

  let dx11 = Pfx + jitter * ox11;
  let dy11 = Pfy.x + jitter * oy11;
  let dz11 = Pfz.x + jitter * oz11;

  let dx12 = Pfx + jitter * ox12;
  let dy12 = Pfy.x + jitter * oy12;
  let dz12 = Pfz.y + jitter * oz12;

  let dx13 = Pfx + jitter * ox13;
  let dy13 = Pfy.x + jitter * oy13;
  let dz13 = Pfz.z + jitter * oz13;

  let dx21 = Pfx + jitter * ox21;
  let dy21 = Pfy.y + jitter * oy21;
  let dz21 = Pfz.x + jitter * oz21;

  let dx22 = Pfx + jitter * ox22;
  let dy22 = Pfy.y + jitter * oy22;
  let dz22 = Pfz.y + jitter * oz22;

  let dx23 = Pfx + jitter * ox23;
  let dy23 = Pfy.y + jitter * oy23;
  let dz23 = Pfz.z + jitter * oz23;

  let dx31 = Pfx + jitter * ox31;
  let dy31 = Pfy.z + jitter * oy31;
  let dz31 = Pfz.x + jitter * oz31;

  let dx32 = Pfx + jitter * ox32;
  let dy32 = Pfy.z + jitter * oy32;
  let dz32 = Pfz.y + jitter * oz32;

  let dx33 = Pfx + jitter * ox33;
  let dy33 = Pfy.z + jitter * oy33;
  let dz33 = Pfz.z + jitter * oz33;

  var d11 = dx11 * dx11 + dy11 * dy11 + dz11 * dz11;
  var d12 = dx12 * dx12 + dy12 * dy12 + dz12 * dz12;
  var d13 = dx13 * dx13 + dy13 * dy13 + dz13 * dz13;
  var d21 = dx21 * dx21 + dy21 * dy21 + dz21 * dz21;
  var d22 = dx22 * dx22 + dy22 * dy22 + dz22 * dz22;
  var d23 = dx23 * dx23 + dy23 * dy23 + dz23 * dz23;
  var d31 = dx31 * dx31 + dy31 * dy31 + dz31 * dz31;
  var d32 = dx32 * dx32 + dy32 * dy32 + dz32 * dz32;
  var d33 = dx33 * dx33 + dy33 * dy33 + dz33 * dz33;

  // Sort out the two smallest distances (F1, F2)
  // Do it right and sort out both F1 and F2
  let d1a = min(d11, d12);
  d12 = max(d11, d12);
  d11 = min(d1a, d13); // Smallest now not in d12 or d13
  d13 = max(d1a, d13);
  d12 = min(d12, d13); // 2nd smallest now not in d13
  
  let d2a = min(d21, d22);
  d22 = max(d21, d22);
  d21 = min(d2a, d23); // Smallest now not in d22 or d23
  d23 = max(d2a, d23);
  d22 = min(d22, d23); // 2nd smallest now not in d23
  
  let d3a = min(d31, d32);
  d32 = max(d31, d32);
  d31 = min(d3a, d33); // Smallest now not in d32 or d33
  d33 = max(d3a, d33);
  d32 = min(d32, d33); // 2nd smallest now not in d33
  
  let da = min(d11, d21);
  d21 = max(d11, d21);
  d11 = min(da, d31); // Smallest now in d11
  d31 = max(da, d31); // 2nd smallest now not in d31
  
  if (d11.x < d11.y) {
    d11 = vec3<f32>(d11.x, d11.y, d11.z);
  } else {
    d11 = vec3<f32>(d11.y, d11.x, d11.z);
  }
  
  if (d11.x < d11.z) {
    d11 = vec3<f32>(d11.x, d11.y, d11.z);
  } else {
    d11 = vec3<f32>(d11.z, d11.y, d11.x);
  } // d11.x now smallest
  
  d12 = min(d12, d21); // 2nd smallest now not in d21
  d12 = min(d12, d22); // nor in d22
  d12 = min(d12, d31); // nor in d31
  d12 = min(d12, d32); // nor in d32
  
  let temp_yz = min(d11.yz, d12.xy);
  d11 = vec3<f32>(d11.x, temp_yz.x, temp_yz.y); // nor in d12.yz
  d11 = vec3<f32>(d11.x, min(d11.y, d12.z), d11.z); // Only two more to go
  d11 = vec3<f32>(d11.x, min(d11.y, d11.z), d11.z); // Done! (Phew!)
  
  return sqrt(d11.xy); // F1, F2
}

@fragment fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z / 5;
    
    var st = uv;
    st *= 10.0;

    let F = cellular(vec3<f32>(st, u_time));
    let dots = smoothstep(0.05, 0.1, F.x);
    var n = F.y - F.x;

    n *= dots;
    return vec4<f32>(n, n, n, 1.0);
}