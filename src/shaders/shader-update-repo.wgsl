// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform Struct
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>, 
};

@group(0) @binding(0) var<uniform> transform: Transform;
@group(0) @binding(1) var texSampler: sampler;
@group(0) @binding(2) var tex: texture_2d<f32>;

// -----------------------------------------
// Vertex Output
// -----------------------------------------
struct VertexOutput {
  @builtin(position) Position: vec4<f32>,
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}

// -----------------------------------------
// Helper Functions
// -----------------------------------------
fn rotate(pt: vec2<f32>, theta: f32, aspect: f32) -> vec2<f32> {
  let c = cos(theta);
  let s = sin(theta);
  let mat = mat2x2<f32>(c, s, -s, c);
  var ptt = pt;
  ptt.y = pt.y / 10.0;
  ptt = mat * ptt;
  ptt.y *= aspect;
  return ptt;
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
  let u_mouse = transform.params[0].xy;
  let u_time = transform.params[0].z;
  let u_resolution = transform.params[1].xy;
  
  var color = fragColor.rgb;

  // Only sample texture if useTexture is enabled
  var alpha = 1.0;
  if (transform.useTexture.x > 0.5) {
    var st = uv;
    st = vec2(uv.x, 1.0 - uv.y);

    let imageAspect = 2.0; 
    let planeAspect = 1.5; 
     
    if (imageAspect > planeAspect) {
      let scale = planeAspect / imageAspect;
      st.y = (st.y - 0.5) * scale + 0.5;
    } else {
      let scale = imageAspect / planeAspect;
      st.x = (st.x - 0.5) * scale + 0.5;
    }

    st -= vec2(0.5);
    st = rotate(st, 1.4 + u_time / 20, 2.0 / 1.5);
    st += vec2(0.5);

    let texColor = textureSample(tex, texSampler, st);
    if (st.x<0.0||st.x>1.0||st.y<0.0||st.y>1.0){
      color = vec3(0.0);
    }else{
        color = texColor.rgb;
        alpha = texColor.a;
    }
  }


  
  return vec4<f32>(color, alpha);
}
