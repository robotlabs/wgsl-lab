// WGSL Shader for Reflective Torus with Environment Mapping (torus-shader.wgsl)
struct Transform {
  modelTorus: mat4x4<f32>,
  modelGrid: mat4x4<f32>,
  viewMatrix: mat4x4<f32>,
  projectionMatrix: mat4x4<f32>,
  torusColor: vec4<f32>,
  params: array<vec4<f32>, 2>,
  cameraPos: vec4<f32>, // <-- added: .xyz is camera world position
};

@group(0) @binding(0) var<uniform> transform: Transform;
@group(0) @binding(1) var envTexture: texture_cube<f32>;
@group(0) @binding(2) var envSampler: sampler;


struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vWorldPos: vec3<f32>,
  @location(4) vWorldNormal: vec3<f32>,
};

@vertex fn vs_main(@location(0) pos: vec3<f32>, @location(1) normal: vec3<f32>) -> VertexOutput {
  let u_time = transform.params[0].z;
  let u_mouse = transform.params[0].xy;
  
  // You can add torus-specific animations here
  let twist = 1.0;//sin(u_time * 0.5) * 0.3;
  let angle = atan2(pos.z, pos.x) + twist * pos.y;
  let radius = sqrt(pos.x * pos.x + pos.z * pos.z);
  
  let animatedPos = vec3<f32>(
    radius * cos(angle),
    pos.y + sin(u_time + pos.x) * 0.1, // Add some wave motion
    radius * sin(angle)
  );
  let posStatic = pos;
  
  var output: VertexOutput;
  //uncomment this if you want to animate the vertex of torus
  let world = transform.modelTorus * vec4<f32>(animatedPos, 1.0);
  //   let world = transform.modelTorus * vec4f(posStatic, 1.0);
  let worldNormal = normalize((transform.modelTorus * vec4f(normal, 0.0)).xyz);
  
  output.Position = transform.projectionMatrix * transform.viewMatrix * world;
  output.vPosition = world.xyz;
  output.vNormal = worldNormal;
  output.vColor = transform.torusColor.rgb;
  output.vWorldPos = world.xyz;
  output.vWorldNormal = worldNormal;
  return output;
}
fn fresnelSchlick(cosTheta: f32, F0: vec3<f32>) -> vec3<f32> {
  // Schlick's approximation
  return F0 + (vec3<f32>(1.0) - F0) * pow(1.0 - cosTheta, 5.0);
}

@fragment fn fs_debug(
  @location(3) vWorldPos: vec3<f32>,
  @location(4) vWorldNormal: vec3<f32>
) -> @location(0) vec4<f32> {
  // Hardcoded camera so you don't need extra uniform
  let cameraPosRaw = transform.cameraPos.xyz;
let cameraPos = select(vec3<f32>(0.0, 0.0, 17.0), cameraPosRaw, length(cameraPosRaw) > 0.001);

  let viewDir = normalize(cameraPos - vWorldPos);
  let normal = normalize(vWorldNormal);
  let reflectDir = reflect(-viewDir, normal);

  // Visualize reflectDir (mapped from [-1,1] to [0,1])
  let visReflect = normalize(reflectDir) * 0.5 + vec3<f32>(0.5);

  // Sample cubemap
  let envSample = textureSample(envTexture, envSampler, reflectDir).rgb;

  // Blend for comparison: left = reflectDir, right = cubemap
  let mixed = mix(visReflect, envSample, 0.5);
  return vec4<f32>(mixed, 1.0);
}
@fragment fn fs_main(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vWorldPos: vec3<f32>,
  @location(4) vWorldNormal: vec3<f32>
) -> @location(0) vec4<f32> {
  let u_time = transform.params[0].z;

  let cameraPos = transform.cameraPos.xyz;
  let viewDir = normalize(cameraPos - vWorldPos);
  let normal = normalize(vWorldNormal);
  let reflectDir = reflect(-viewDir, normal);

  // Sample the real cubemap
  var envColor = textureSample(envTexture, envSampler, reflectDir).rgb;

  // Optional animated tint like the pen does subtly
  envColor = envColor * 2.0;//(0.8 + 0.2 * sin(u_time * 2.0));

  // Fresnel (Schlick) for stronger edge reflection
  let F0 = vec3<f32>(0.04);
  let fresnelFactor = fresnelSchlick(max(dot(normal, viewDir), 0.0), F0); // vector

  // Lighting
  let lightDir = normalize(vec3<f32>(0.5, 1.0, 0.3));
  let ambient = 0.1;
  let diffuse = max(dot(normal, lightDir), 0.0);
  
  let specularTint = vec3<f32>(0.2, 0.4, 1.0);
let specular = pow(max(dot(viewDir, reflect(-lightDir, normal)), 0.0), 64.0) * specularTint;


  let baseColor = vColor * (ambient + 0.6 * diffuse);

  // Stronger reflection contribution like the CodePen
  let reflectivity = 1.0; // bump this up to be more visible
  let reflected = mix(baseColor, envColor * 2.2, fresnelFactor * 2.2);
  let finalColor = reflected + specular * 0.3;

  return vec4<f32>(finalColor, 1.0);
}


@fragment fn fs_wireframe(
  @location(0) vPosition: vec3<f32>,
  @location(1) vNormal: vec3<f32>,
  @location(2) vColor: vec3<f32>,
  @location(3) vWorldPos: vec3<f32>,
  @location(4) vWorldNormal: vec3<f32>
) -> @location(0) vec4<f32> {
  let wireframeColor = vec3(1.0, 1.0, 1.0);
  return vec4<f32>(wireframeColor, 1.0);
}