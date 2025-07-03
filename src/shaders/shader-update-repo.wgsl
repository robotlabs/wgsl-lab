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

fn rect(st: vec2<f32>, sizeParam: vec2<f32>) -> f32 {
  // size = 0.25 - sizeParam*0.25
  let s = vec2<f32>(0.25) - sizeParam * vec2<f32>(0.25);
  // smooth edges
  let uv = smoothstep(
    s,
    s + s * vec2<f32>(0.002),
    st * (vec2<f32>(1.0) - st)
  );
  return uv.x * uv.y;
}

// ------------------------------------------------------------------
// Fragment shader
// ------------------------------------------------------------------
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @builtin(position) fragCoord: vec4<f32>
) -> @location(0) vec4<f32> {
  // --- get st = [0..1] coords (flipped Y) ---
  let res = transform.params[1].xy;
  var st  = fragCoord.xy / res;
  st.y = 1.0 - st.y;

  // --- your colors ---
  let influenced_color      = vec3<f32>(0.745, 0.696, 0.529);
  let influencing_color_A   = vec3<f32>(0.418, 0.735, 0.780);
  let influencing_color_a   = vec3<f32>(0.065, 0.066, 0.290);
  let influencing_color_b   = vec3<f32>(0.865, 0.842, 0.162);
  let influencing_color_B   = vec3<f32>(0.980, 0.603, 0.086);

  // --- build the vertical bands ---
  let mixA = mix(
    influencing_color_A,
    influencing_color_a,
    step(0.3, st.y)
  );
  let mixB = mix(
    influencing_color_b,
    influencing_color_B,
    step(0.7, st.y)
  );
  var color = mix(
    mixA,
    mixB,
    step(0.5, st.y)
  );

  // --- draw the center rectangle blend ---
  let shifted = (st - vec2<f32>(0.0, 0.5)) * vec2<f32>(1.0, 1.75);
  let r       = rect(abs(shifted), vec2<f32>(0.025, 0.09));
  color = mix(color, influenced_color, r);

  return vec4<f32>(color, 1.0);
}