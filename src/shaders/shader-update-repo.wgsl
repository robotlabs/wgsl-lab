struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>,
};

@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv:        vec2<f32>,
  @location(2)        worldPos: vec3<f32>,
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  o.worldPos  = world.xyz;
  return o;
}

// ----------------------------------------
// HSB → RGB conversion (fract variant)
// ----------------------------------------
fn hsb2rgb(c: vec3<f32>) -> vec3<f32> {
  let t = c.x * 6.0 + vec3<f32>(0.0, 4.0, 2.0);
  let m = fract(t * (1.0 / 6.0)) * 6.0;
  var rgb = abs(m - vec3<f32>(3.0)) - vec3<f32>(1.0);
  rgb = clamp(rgb, vec3<f32>(0.0), vec3<f32>(1.0));
  rgb = rgb * rgb * (vec3<f32>(3.0) - 2.0 * rgb);
  let whiteMix = vec3<f32>(1.0) * (1.0 - c.y) + rgb * c.y;
  return c.z * whiteMix;
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
  @location(2) worldPos:  vec3<f32>
) -> @location(0) vec4<f32> {
    let TWO_PI: f32 = 6.28318530718;
    // let col = hsb2rgb(vec3<f32>(uv.x, 1.0, uv.y));
    var color = vec3(0.0);
    let toCenter = vec2(0.5)-uv;
    let angle = atan2(toCenter.y,toCenter.x);
    let radius = length(toCenter)*2.0;

    // Map the angle (-PI to PI) to the Hue (from 0 to 1)
    // and the Saturation to the radius
    color = hsb2rgb(vec3((angle/TWO_PI)+0.5,radius,1.0));

    return vec4<f32>(color, fragColor.a);
}
