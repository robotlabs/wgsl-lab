struct Transform {
  modelSphere: mat4x4<f32>,
  modelGrid: mat4x4<f32>,
  viewMatrix: mat4x4<f32>,
  projectionMatrix: mat4x4<f32>,
  sphereColor: vec4<f32>,
  params: array<vec4<f32>, 2>,
};

@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
};

// Simple noise function
fn noise(p: vec3<f32>) -> f32 {
  return sin(p.x * 10.0) * sin(p.y * 10.0) * sin(p.z * 10.0) * 0.1;
}

@vertex fn vs_main(@location(0) pos: vec3<f32>, @location(1) normal: vec3<f32>) -> VertexOutput {
  let u_time = transform.params[0].z;
  
  var output: VertexOutput;
  
  // Simple displacement: just add some noise along the normal
  let displacement = noise(pos + u_time * 0.1) * 0.5;
  let newPosition = pos + normal * displacement;
  
  let world = transform.modelSphere * vec4f(newPosition, 1.0);
  let worldNormal = normalize((transform.modelSphere * vec4f(normal, 0.0)).xyz);

  output.Position = transform.projectionMatrix * transform.viewMatrix * world;
  output.vPosition = world.xyz;
  output.vNormal = worldNormal;
  output.vColor = transform.sphereColor.rgb;
  
  return output;
}

@fragment fn fs_main(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>
) -> @location(0) vec4<f32> {
  // Simple lighting
  let lightDir = normalize(vec3<f32>(0.5, 1.0, 0.3));
  let normal = normalize(vNormal);
  let lighting = max(dot(normal, lightDir), 0.3);
  
  return vec4<f32>(vColor * lighting, 1.0);
}

@fragment fn fs_wireframe(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>
) -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 1.0, 1.0, 1.0);
}