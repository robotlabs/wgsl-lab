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
fn createLeafPattern(st: vec2<f32>, numLeaves: f32, time: f32, expansion: f32, scale: f32) -> f32 {
  var angle = atan2(st.y, st.x) + time / 3.5;
  let radius = length(st);
  let foldedAngle = abs(fract(angle * numLeaves / (2.0 * 3.14159)) - 0.5) * 2.0;
  let polarSt = vec2<f32>(
    cos(foldedAngle * 2.0 * 3.14159 / numLeaves),
    sin(foldedAngle * 2.0 * 3.14159 / numLeaves)
  ) * radius;
  let noisedSt = abs(polarSt) * scale + (fbm(abs(polarSt) * 6.0 + time * 0.2) * 0.2 - 0.1);
  return length(noisedSt - expansion);
}

// Get continuous expansion with fade out
fn getContinuousExpansion(t: f32, offset: f32) -> f32 {
  let cycleTime = fract(t * 0.5 + offset); // Slow down the cycle
  return -0.7 + cycleTime * 1.5; // Expand from -0.7 to 0.8
}

// Get opacity that fades out as pattern expands
fn getFadeOpacity(t: f32, offset: f32) -> f32 {
  let cycleTime = fract(t * 0.5 + offset);
  // Strong at birth, fade out as it expands
  return smoothstep(1.0, 0.2, cycleTime);
}

// Corner-specific noise distortion
fn getCornerDistortion(st: vec2<f32>, time: f32) -> vec2<f32> {
  // Determine which corner we're closest to with stronger gradients
  let cornerTopRight = smoothstep(0.0, 1.0, st.x) * smoothstep(0.0, 1.0, st.y);
  let cornerTopLeft = smoothstep(0.0, -1.0, st.x) * smoothstep(0.0, 1.0, st.y);
  let cornerBottomRight = smoothstep(0.0, 1.0, st.x) * smoothstep(0.0, -1.0, st.y);
  let cornerBottomLeft = smoothstep(0.0, -1.0, st.x) * smoothstep(0.0, -1.0, st.y);
  
  var distortion = vec2<f32>(0.0);
  
  // Top-right corner: Swirling noise (more intense)
  let swirl = fbm(st * 2.0 + time * 0.5) * 0.8;
  let angle = swirl * 6.28;
  distortion += vec2<f32>(cos(angle), sin(angle)) * cornerTopRight * 0.6;
  
  // Top-left corner: Turbulent stretching (more intense)
  let turbulence = fbm(st * 3.0 + vec2<f32>(time * 0.4, -time * 0.2));
  distortion += vec2<f32>(-turbulence * 0.8, turbulence * 0.6) * cornerTopLeft;
  
  // Bottom-right corner: Ripple effect (more intense)
  let ripple = sin(length(st - vec2<f32>(0.5, -0.5)) * 6.0 - time * 3.0) * 0.3;
  let rippleNoise = fbm(st * 4.0 + time * 0.6) * 0.4;
  distortion += vec2<f32>(ripple + rippleNoise, -ripple * 0.8) * cornerBottomRight;
  
  // Bottom-left corner: Chaotic fbm (more intense)
  let chaos1 = fbm(st * 5.0 + vec2<f32>(time * 0.7, time * 1.0)) * 0.6;
  let chaos2 = fbm(st * 7.0 - vec2<f32>(time * 0.5, time * 0.8)) * 0.4;
  distortion += vec2<f32>(chaos1 - chaos2, chaos1 + chaos2 * 0.7) * cornerBottomLeft;
  
  return distortion;
}

@fragment fn fs_main(
  @builtin(position) fragCoord: vec4<f32>,
  @location(1) uv: vec2<f32>
) -> @location(0) vec4<f32> {
  var st = uv * 2.0 - vec2<f32>(1.0);
  var time = transform.params[0][2] / 5;
  st += getCornerDistortion(st, time);
  st.y = st.y - sin(time);
  
  var finalColor = vec3<f32>(0.0);
  
  // Colors
  let goldenYellow = vec3(1.000, 0.867, 0.000);
  let cadmiumYellow = vec3(1.000, 0.965, 0.000);
  let metallicYellow = vec3(0.992, 0.800, 0.051);
  let interdimensionalBlue = vec3(0.369, 0.000, 0.812);
  let lemonYellow = vec3(1.000, 1.000, 0.624);
  let fucsia = vec3(1.000, 0.600, 0.000);

  // Create multiple continuous generations with different offsets
  let numGenerations = 8;
  
  for (var gen = 0; gen < numGenerations; gen++) {
    let genOffset = f32(gen) * 0.25; // Stagger generations
    
    // Layer 1: Large outer leaves
    let expansion1 = getContinuousExpansion(time, genOffset);
    let opacity1 = getFadeOpacity(time, genOffset);
    let d1 = createLeafPattern(st, 8.0, time, expansion1, 1.0);
    let leaf1 = step(0.4, d1) * step(d1, 0.79) * opacity1;
    
    // Layer 2: Medium inner leaves (rotated)
    let rotatedSt1 = rotate2D(st, time * 0.3 + genOffset);
    let expansion2 = getContinuousExpansion(time * 1.2, genOffset + 0.1);
    let opacity2 = getFadeOpacity(time * 1.2, genOffset + 0.1);
    let d2 = createLeafPattern(rotatedSt1 * 0.6, 6.0, time * 1.2, expansion2, 0.8);
    let leaf2 = step(0.3, d2) * step(d2, 0.5) * opacity2;
    
    // Layer 3: Small center pattern
    let rotatedSt2 = rotate2D(st, -time * 0.4 + genOffset);
    let expansion3 = getContinuousExpansion(time * 0.8, genOffset + 0.15);
    let opacity3 = getFadeOpacity(time * 0.8, genOffset + 0.15);
    let d3 = createLeafPattern(rotatedSt2 * 0.7, 8.0, time * 0.2, expansion3, 0.8);
    let leaf3 = step(0.2, d3) * step(d3, 0.7) * opacity3;

    // Layer 4
    let rotatedSt3 = rotate2D(st, time * 0.7 + genOffset);
    let expansion4 = getContinuousExpansion(time * 1.4, genOffset + 0.2);
    let opacity4 = getFadeOpacity(time * 1.4, genOffset + 0.2);
    let d4 = createLeafPattern(rotatedSt3 * 0.6, 5.0, time * 2.8, expansion4, 0.67);
    let leaf4 = step(0.3, d4) * step(d4, 0.5) * opacity4;

    // Layer 5
    let rotatedSt4 = rotate2D(st, -time * 0.3 + genOffset);
    let expansion5 = getContinuousExpansion(time * 1.0, genOffset + 0.25);
    let opacity5 = getFadeOpacity(time * 1.0, genOffset + 0.25);
    let d5 = createLeafPattern(rotatedSt4 * 0.5, 3.0, time * 1.0, expansion5, 0.5);
    let leaf5 = step(0.2, d5) * step(d5, 0.5) * opacity5;

    // Layer 6
    let rotatedSt5 = rotate2D(st, time * 0.3 + genOffset);
    let expansion6 = getContinuousExpansion(time * 1.8, genOffset + 0.3);
    let opacity6 = getFadeOpacity(time * 1.8, genOffset + 0.3);
    let d6 = createLeafPattern(rotatedSt5 * 0.3, 4.0, time * 1.5, expansion6, 0.0);
    let leaf6 = step(0.1, d6) * step(d6, 0.5) * opacity6;

    // Combine layers with different colors (dimmed by generation)
    let generationDimming = 1.0 - f32(gen) * 0.2;
    finalColor += leaf1 * goldenYellow * generationDimming;
    finalColor += leaf2 * cadmiumYellow * generationDimming;
    finalColor += leaf3 * metallicYellow * generationDimming;
    finalColor += leaf4 * interdimensionalBlue * generationDimming;
    finalColor += leaf5 * lemonYellow * generationDimming;
    finalColor += leaf6 * goldenYellow * generationDimming;
  }
  
  return vec4<f32>(finalColor, 1.0);
}