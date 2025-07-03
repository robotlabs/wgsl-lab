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
  
  return output;
}

fn plot(st: vec2<f32>) -> f32 {    
    return smoothstep(0.01, 0.0, abs(st.y - st.x));
}
fn plot2(st: vec2<f32>, pct:f32)  -> f32 {
  return  smoothstep( pct-0.02, pct, st.y) -
          smoothstep( pct, pct+0.02, st.y);
}


@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
    @builtin(position) fragCoord: vec4<f32>,
     @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    
    let timeMild =  1pl0 - transform.params[0][2] / 5.0;
    let y = sin((uv.x * 6.28)) / (2.2* timeMild) + 0.5;
    let curve = plot2(uv, y);
    let base = select(vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(1.0), uv.y < y);
    let color = mix(base, vec3<f32>(0.0, 1.0, 0.0), curve);

    return vec4<f32>(color, 1.0);
}