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
  @location(2) worldPos: vec3<f32>,
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
  output.worldPos = world.xyz;
  
  return output;
}

// Simple hash noise function
fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

// Perlin-style noise with smooth interpolation
fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    
    // Smooth interpolation curve
    let u = f * f * (3.0 - 2.0 * f);
    
    // Four corner values
    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));
    
    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal noise (multiple octaves of Perlin noise)
fn fbm(p: vec2<f32>) -> f32 {
    var value = 0.0;
    var amplitude = 0.5;
    var frequency = 1.0;
    
    for (var i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

@fragment fn fs_main(
  @builtin(position) fragCoord: vec4<f32>,
  @location(1) uv: vec2<f32>
) -> @location(0) vec4<f32> {
  var st = uv * 2.0 - vec2<f32>(1.0);
  var time = transform.params[0][2];
  let normalizedTime = -0.5 + (sin(time / 1.0) + 1.0) * 0.35;
  
  var finalColor = vec3<f32>(0.0);
  
  // Layer 1: Large outer leaves
  let d1 = createLeafPattern(st, 8.0, time, normalizedTime, 1.0);
  let leaf1 = smoothstep(0.4, 0.5, d1) * smoothstep(0.8, 0.7, d1);
  
  // Layer 2: Medium inner leaves (rotated)
  let rotatedSt1 = rotate2D(st, time * 0.3);
  let d2 = createLeafPattern(rotatedSt1 * 0.7, 6.0, time * 1.2, normalizedTime, 0.8);
  let leaf2 = smoothstep(0.3, 0.4, d2) * smoothstep(0.6, 0.5, d2);
  
  // Layer 3: Small center pattern
  let rotatedSt2 = rotate2D(st, -time * 0.5);
  let d3 = createLeafPattern(rotatedSt2 * 0.4, 4.0, time * 1.8, normalizedTime, 0.6);
  let leaf3 = smoothstep(0.2, 0.3, d3) * smoothstep(0.5, 0.4, d3);

    let rotatedSt3 = rotate2D(st, time * 0.7);
  let d4 = createLeafPattern(rotatedSt3 * 0.6, 5.0, time * 2.8, normalizedTime, 0.67);
  let leaf4 = smoothstep(0.2, 0.3, d4) * smoothstep(0.5, 0.4, d4);

     let rotatedSt4 = rotate2D(st, -time * 0.3);
    let d5 = createLeafPattern(rotatedSt4 * 0.5, 3.0, time * 1.0, normalizedTime, 0.5);
    // let leaf5 = smoothstep(0.2, 0.3, d5) * smoothstep(0.5, 0.4, d5);
    let leaf5 = step(0.2,  d5) * smoothstep(0.5, 0.4, d5);

    let rotatedSt5 = rotate2D(st, time * 0.3);
    let d6 = createLeafPattern(rotatedSt5 * 0.3, 4.0, time * 1.5, normalizedTime, 0.7);
    let leaf6 = step(0.1, d6) * step(0.5, d6);//smoothstep(0.1, 0.4, d6) * smoothstep(0.5, 0.4, d6);

        let rotatedSt6 = rotate2D(st, -time * 0.3);
    let d7 = createLeafPattern(rotatedSt6 * 0.3, 4.0, time * 1.2, normalizedTime, 0.9);
    let leaf7 = step(0.1, d7) * step(0.5, d7);//smoothstep(0.1, 0.4, d6) * smoothstep(0.5, 0.4, d6);
    

  let goldenYellow = vec3(1.000, 0.867, 0.000);
  // Cadmium Yellow (#FFF600)
  let cadmiumYellow =  vec3(1.000, 0.965, 0.000);
  // Metallic Yellow (#FDCC0D)
  let metallicYellow = vec3(0.992, 0.800, 0.051);
  // Interdimensional Blue (#5E00CF)
  let interdimensionalBlue =  vec3(0.369, 0.000, 0.812);
  // Crayola’s Lemon Yellow (#FFFF9F)
  let lemonYellow = vec3(1.000, 1.000, 0.624);
  let black = vec3(0.000, 0.000, 0.0);


  // Combine layers with different colors
  finalColor += leaf1 * goldenYellow;  // Green outer
  finalColor += leaf2 * cadmiumYellow;  // Orange middle  
  finalColor += leaf3 * metallicYellow;  // Red center
  finalColor += leaf4 * interdimensionalBlue;  // Red center
  finalColor += leaf5 * lemonYellow;  // Red center
  finalColor += leaf6 * goldenYellow;  // Red center
  finalColor += leaf7 * interdimensionalBlue;  // Red center
  
  return vec4<f32>(finalColor, 1.0);
}

// Helper function for rotation
fn rotate2D(st: vec2<f32>, angle: f32) -> vec2<f32> {
  let c = cos(angle);
  let s = sin(angle);
  return vec2<f32>(
    st.x * c - st.y * s,
    st.x * s + st.y * c
  );
}

// Refactored leaf pattern creation
fn createLeafPattern(st: vec2<f32>, numLeaves: f32, time: f32, normalizedTime: f32, scale: f32) -> f32 {
  var angle = atan2(st.y, st.x) + time / 3.5;
  let radius = length(st);
  let foldedAngle = abs(fract(angle * numLeaves / (2.0 * 3.14159)) - 0.5) * 2.0;
  let polarSt = vec2<f32>(
    cos(foldedAngle * 2.0 * 3.14159 / numLeaves),
    sin(foldedAngle * 2.0 * 3.14159 / numLeaves)
  ) * radius;
  let noisedSt = abs(polarSt) * scale + (fbm(abs(polarSt) * 6.0 + time * 0.2) * 0.2 - 0.1);
  return length(noisedSt - normalizedTime);
}