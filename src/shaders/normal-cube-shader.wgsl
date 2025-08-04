struct Transform {
  modelCube: mat4x4<f32>,
  modelGrid: mat4x4<f32>,
  viewMatrix: mat4x4<f32>,
  projectionMatrix: mat4x4<f32>,
  cubeColor: vec4<f32>,
  params: array<vec4<f32>, 2>,
};

@group(0) @binding(0) var<uniform> transform: Transform;
@group(0) @binding(1) var u_diffuse_sampler: sampler;
@group(0) @binding(2) var u_diffuse_texture: texture_2d<f32>;
@group(0) @binding(3) var u_normal_sampler: sampler;
@group(0) @binding(4) var u_normal_texture: texture_2d<f32>;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vUv: vec2<f32>,
  @location(3) vModelMatrix0: vec4<f32>,
  @location(4) vModelMatrix1: vec4<f32>,
  @location(5) vModelMatrix2: vec4<f32>,
  @location(6) vModelMatrix3: vec4<f32>,
}

@vertex fn vs_main(
  @location(0) pos: vec3<f32>, 
  @location(1) normal: vec3<f32>
) -> VertexOutput {
  var output: VertexOutput;
  
  // Calculate UV coordinates from position (for a cube)
  // This is a simple box mapping - you might want to improve this
  var uv: vec2<f32>;
  let absNormal = abs(normal);
  if (absNormal.x > absNormal.y && absNormal.x > absNormal.z) {
    // X face
    uv = vec2<f32>(pos.z, pos.y) * 0.5 + 0.5;
  } else if (absNormal.y > absNormal.z) {
    // Y face  
    uv = vec2<f32>(pos.x, pos.z) * 0.5 + 0.5;
  } else {
    // Z face
    uv = vec2<f32>(pos.x, pos.y) * 0.5 + 0.5;
  }
  
  let world = transform.modelCube * vec4f(pos, 1.0);
  let worldNormal = normalize((transform.modelCube * vec4f(normal, 0.0)).xyz);
  
  output.Position = transform.projectionMatrix * transform.viewMatrix * world;
  output.vPosition = world.xyz;
  output.vNormal = worldNormal;
  output.vUv = uv;
  
  // Pass model matrix as varying (split into 4 vec4s since matrices can't be interpolated directly)
  output.vModelMatrix0 = transform.modelCube[0];
  output.vModelMatrix1 = transform.modelCube[1];
  output.vModelMatrix2 = transform.modelCube[2];
  output.vModelMatrix3 = transform.modelCube[3];
  
  return output;
}

@fragment fn fs_main(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vUv: vec2<f32>,
  @location(3) vModelMatrix0: vec4<f32>,
  @location(4) vModelMatrix1: vec4<f32>,
  @location(5) vModelMatrix2: vec4<f32>,
  @location(6) vModelMatrix3: vec4<f32>
) -> @location(0) vec4<f32> {
  
  // Reconstruct model matrix
  let vModelMatrix = mat4x4<f32>(
    vModelMatrix0,
    vModelMatrix1, 
    vModelMatrix2,
    vModelMatrix3
  );
  
  // Light direction (matching your Three.js example)
  let u_light = vec3<f32>(0.5, 0.8, 0.1);
  let lightVector = normalize(u_light);
  
  // Sample normal map
  let normalSample = textureSample(u_normal_texture, u_normal_sampler, vUv);
  
  // Transform normal from texture space to world space
  // In Three.js: normalize((vModelMatrix * (normal + vec4(vNormal, 1.0))).xyz)
  let normalVector = normalize((vModelMatrix * (normalSample + vec4<f32>(vNormal, 1.0))).xyz);
  
  // Calculate lighting intensity with ambient
  let lightIntensity = clamp(dot(lightVector, normalVector), 0.0, 1.0) + 0.2;
  
  // Sample diffuse texture
  let texel = textureSample(u_diffuse_texture, u_diffuse_sampler, vUv).rgb;
  
  // Final color calculation
  let color = lightIntensity * texel;
  
  return vec4<f32>(color, 1.0);
}

@fragment fn fs_wireframe(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vUv: vec2<f32>,
  @location(3) vModelMatrix0: vec4<f32>,
  @location(4) vModelMatrix1: vec4<f32>,
  @location(5) vModelMatrix2: vec4<f32>,
  @location(6) vModelMatrix3: vec4<f32>
) -> @location(0) vec4<f32> {
  let wireframeColor = vec3<f32>(1.0, 1.0, 1.0);
  return vec4<f32>(wireframeColor, 1.0);
}