struct Transform {
  modelSphere: mat4x4<f32>,
  modelGrid: mat4x4<f32>,
  viewMatrix: mat4x4<f32>,
  projectionMatrix: mat4x4<f32>,
  sphereColor: vec4<f32>,
  params: array<vec4<f32>, 2>,
};

@group(0) @binding(0) var<uniform> transform: Transform;
@group(0) @binding(1) var fireSampler: sampler;
@group(0) @binding(2) var fireTex: texture_2d<f32>;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vUv: vec2<f32>,
  @location(4) vNoise: f32,
};

// [Same noise functions as before]
fn mod289_3(x: vec3<f32>) -> vec3<f32> {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn mod289_4(x: vec4<f32>) -> vec4<f32> {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn permute4(x: vec4<f32>) -> vec4<f32> {
  return mod289_4(((x * 34.0) + 10.0) * x);
}

fn taylorInvSqrt4(r: vec4<f32>) -> vec4<f32> {
  return 1.79284291400159 - 0.85373472095314 * r;
}

fn fade3(t: vec3<f32>) -> vec3<f32> {
  return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

fn cnoise(P: vec3<f32>) -> f32 {
  var Pi0 = floor(P);
  var Pi1 = Pi0 + vec3<f32>(1.0);
  Pi0 = mod289_3(Pi0);
  Pi1 = mod289_3(Pi1);
  let Pf0 = fract(P);
  let Pf1 = Pf0 - vec3<f32>(1.0);
  let ix = vec4<f32>(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  let iy = vec4<f32>(Pi0.yy, Pi1.yy);
  let iz0 = Pi0.zzzz;
  let iz1 = Pi1.zzzz;

  let ixy = permute4(permute4(ix) + iy);
  let ixy0 = permute4(ixy + iz0);
  let ixy1 = permute4(ixy + iz1);

  var gx0 = ixy0 * (1.0 / 7.0);
  var gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  let gz0 = vec4<f32>(0.5) - abs(gx0) - abs(gy0);
  let sz0 = step(gz0, vec4<f32>(0.0));
  gx0 -= sz0 * (step(vec4<f32>(0.0), gx0) - 0.5);
  gy0 -= sz0 * (step(vec4<f32>(0.0), gy0) - 0.5);

  var gx1 = ixy1 * (1.0 / 7.0);
  var gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  let gz1 = vec4<f32>(0.5) - abs(gx1) - abs(gy1);
  let sz1 = step(gz1, vec4<f32>(0.0));
  gx1 -= sz1 * (step(vec4<f32>(0.0), gx1) - 0.5);
  gy1 -= sz1 * (step(vec4<f32>(0.0), gy1) - 0.5);

  var g000 = vec3<f32>(gx0.x, gy0.x, gz0.x);
  var g100 = vec3<f32>(gx0.y, gy0.y, gz0.y);
  var g010 = vec3<f32>(gx0.z, gy0.z, gz0.z);
  var g110 = vec3<f32>(gx0.w, gy0.w, gz0.w);
  var g001 = vec3<f32>(gx1.x, gy1.x, gz1.x);
  var g101 = vec3<f32>(gx1.y, gy1.y, gz1.y);
  var g011 = vec3<f32>(gx1.z, gy1.z, gz1.z);
  var g111 = vec3<f32>(gx1.w, gy1.w, gz1.w);

  let norm0 = taylorInvSqrt4(vec4<f32>(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  let norm1 = taylorInvSqrt4(vec4<f32>(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  let n000 = dot(g000, Pf0);
  let n100 = dot(g100, vec3<f32>(Pf1.x, Pf0.y, Pf0.z));
  let n010 = dot(g010, vec3<f32>(Pf0.x, Pf1.y, Pf0.z));
  let n110 = dot(g110, vec3<f32>(Pf1.x, Pf1.y, Pf0.z));
  let n001 = dot(g001, vec3<f32>(Pf0.x, Pf0.y, Pf1.z));
  let n101 = dot(g101, vec3<f32>(Pf1.x, Pf0.y, Pf1.z));
  let n011 = dot(g011, vec3<f32>(Pf0.x, Pf1.y, Pf1.z));
  let n111 = dot(g111, Pf1);

  let fade_xyz = fade3(Pf0);
  let n_z = mix(vec4<f32>(n000, n100, n010, n110), vec4<f32>(n001, n101, n011, n111), fade_xyz.z);
  let n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  let n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}

fn pnoise(P: vec3<f32>, rep: vec3<f32>) -> f32 {
  var Pi0 = floor(P) % rep;
  var Pi1 = (Pi0 + vec3<f32>(1.0)) % rep;
  Pi0 = mod289_3(Pi0);
  Pi1 = mod289_3(Pi1);
  let Pf0 = fract(P);
  let Pf1 = Pf0 - vec3<f32>(1.0);
  let ix = vec4<f32>(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  let iy = vec4<f32>(Pi0.yy, Pi1.yy);
  let iz0 = Pi0.zzzz;
  let iz1 = Pi1.zzzz;

  let ixy = permute4(permute4(ix) + iy);
  let ixy0 = permute4(ixy + iz0);
  let ixy1 = permute4(ixy + iz1);

  var gx0 = ixy0 * (1.0 / 7.0);
  var gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  let gz0 = vec4<f32>(0.5) - abs(gx0) - abs(gy0);
  let sz0 = step(gz0, vec4<f32>(0.0));
  gx0 -= sz0 * (step(vec4<f32>(0.0), gx0) - 0.5);
  gy0 -= sz0 * (step(vec4<f32>(0.0), gy0) - 0.5);

  var gx1 = ixy1 * (1.0 / 7.0);
  var gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  let gz1 = vec4<f32>(0.5) - abs(gx1) - abs(gy1);
  let sz1 = step(gz1, vec4<f32>(0.0));
  gx1 -= sz1 * (step(vec4<f32>(0.0), gx1) - 0.5);
  gy1 -= sz1 * (step(vec4<f32>(0.0), gy1) - 0.5);

  var g000 = vec3<f32>(gx0.x, gy0.x, gz0.x);
  var g100 = vec3<f32>(gx0.y, gy0.y, gz0.y);
  var g010 = vec3<f32>(gx0.z, gy0.z, gz0.z);
  var g110 = vec3<f32>(gx0.w, gy0.w, gz0.w);
  var g001 = vec3<f32>(gx1.x, gy1.x, gz1.x);
  var g101 = vec3<f32>(gx1.y, gy1.y, gz1.y);
  var g011 = vec3<f32>(gx1.z, gy1.z, gz1.z);
  var g111 = vec3<f32>(gx1.w, gy1.w, gz1.w);

  let norm0 = taylorInvSqrt4(vec4<f32>(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  let norm1 = taylorInvSqrt4(vec4<f32>(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  let n000 = dot(g000, Pf0);
  let n100 = dot(g100, vec3<f32>(Pf1.x, Pf0.y, Pf0.z));
  let n010 = dot(g010, vec3<f32>(Pf0.x, Pf1.y, Pf0.z));
  let n110 = dot(g110, vec3<f32>(Pf1.x, Pf1.y, Pf0.z));
  let n001 = dot(g001, vec3<f32>(Pf0.x, Pf0.y, Pf1.z));
  let n101 = dot(g101, vec3<f32>(Pf1.x, Pf0.y, Pf1.z));
  let n011 = dot(g011, vec3<f32>(Pf0.x, Pf1.y, Pf1.z));
  let n111 = dot(g111, Pf1);

  let fade_xyz = fade3(Pf0);
  let n_z = mix(vec4<f32>(n000, n100, n010, n110), vec4<f32>(n001, n101, n011, n111), fade_xyz.z);
  let n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  let n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}

fn turbulence(p: vec3<f32>) -> f32 {
  var t = 0.0;
  var f = 1.0;
  for (var i = 0; i < 4; i++) {
    t += abs(cnoise(p * f)) / f;
    f *= 2.0;
  }
  return t;
}

// Random function (matching Three.js version)
fn random(pt: vec3<f32>, seed: f32) -> f32 {
  let scale = vec3<f32>(12.9898, 78.233, 151.7182);
  return fract(sin(dot(pt + vec3<f32>(seed), scale)) * 43758.5453 + seed);
}

@vertex fn vs_main(@location(0) pos: vec3<f32>, @location(1) normal: vec3<f32>) -> VertexOutput {
  let u_time = transform.params[0].z;
  
  var output: VertexOutput;
  
  let vUv = vec2<f32>(
    atan2(pos.z, pos.x) / (2.0 * 3.14159265359) + 0.5,
    acos(pos.y / length(pos)) / 3.14159265359
  );
  
  // FIRE EFFECT VERTEX (matching Three.js fire example)
  let time = u_time * .2; // Faster animation
  
  // Add time to the noise parameters so it's animated
  let vNoise = 10.0 * -0.10 * turbulence(0.5 * normal + vec3<f32>(time));
  let b = 1.0 * pnoise(0.05 * pos + vec3<f32>(2.0 * time), vec3<f32>(100.0)); // Double time speed
  
  // Original Three.js displacement
  let displacement = -2.0 * vNoise + b + 2;
  
  let newPosition = pos + normal * displacement;
  
  let world = transform.modelSphere * vec4f(newPosition, 1.0);
  let worldNormal = normalize((transform.modelSphere * vec4f(normal, 0.0)).xyz);

  output.Position = transform.projectionMatrix * transform.viewMatrix * world;
  output.vPosition = world.xyz;
  output.vNormal = worldNormal;
  output.vColor = transform.sphereColor.rgb;
  output.vUv = vUv;
  output.vNoise = vNoise;
  
  return output;
}

@fragment fn fs_main(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vUv: vec2<f32>,
  @location(4) vNoise: f32
) -> @location(0) vec4<f32> {
  // LAVA EFFECT FRAGMENT - DEBUG VERSION
  
  // Get a random offset
  let r = 0.01 * random(vPosition, 0.0);
  
  // Map noise properly - keep it in a good range
  let normalizedNoise = (vNoise + 1.0) * 0.5;
  let noiseValue = clamp(normalizedNoise + r, 0.0, 1.0);
  
  // Sample texture for additional variation
  let lavaUv = vec2<f32>(vUv.x, noiseValue);
  let texColor = textureSample(fireTex, fireSampler, lavaUv).rgb;
  
  // Use the noise value directly but boost contrast
  let intensity = noiseValue;
  
  // DEBUG: Let's see what intensity values we're actually getting
  // Uncomment this line to see intensity as grayscale:
  // return vec4<f32>(intensity, intensity, intensity, 1.0);
  
  // MUCH LOWER thresholds so we actually reach the bright areas
  var lavaColor: vec3<f32>;
  

  if (intensity < 0.1) {
    // Very dark areas - pure black
    lavaColor = vec3<f32>(0.2, 0.0, 0.0);
  } else if (intensity < 0.25) {
    // Dark red areas
    let t = (intensity - 0.1) / 0.15;
    lavaColor = mix(vec3<f32>(0.2, 0.0, 0.0), vec3<f32>(0.5, 0.1, 0.0), t);
  } else if (intensity < 0.4) {
    // Orange areas
    let t = (intensity - 0.25) / 0.15;
    lavaColor = mix(vec3<f32>(0.5, 0.1, 0.0), vec3<f32>(1.0, 0.5, 0.0), t);
  } else {
    // HOT BRIGHT VEINS - NOW this should trigger!
    let t = (intensity - 0.4) / 0.6; // Much wider range
    lavaColor = mix(vec3<f32>(1.0, 0.5, 0.0), vec3<f32>(2.0, 2.0, 1.0), t);
    // BOOST these bright areas significantly
    lavaColor *= 5.0;
  }
  
  // Use texture to add variation
  lavaColor *= (0.8 + 0.4 * texColor.r);
  
  return vec4<f32>(lavaColor, 1.0);
}

@fragment fn fs_wireframe(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vUv: vec2<f32>,
  @location(4) vNoise: f32
) -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 1.0, 1.0, 1.0);
}