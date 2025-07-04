// -----------------------------------------
// Constants
// -----------------------------------------
const PI:  f32 = 3.141592653589793;
const PI2: f32 = PI * 2.0;

// -----------------------------------------
// Your existing Transform & VS (unchanged)
// -----------------------------------------
struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>,  // [0].z = u_time, [1].xy = u_resolution
};
@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv       : vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}


fn random (st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    var time = transform.params[0][2] / 2.0;
    // var mouseX = transform.params[1][2] / 1.0;


    // let tileCount = 10.0;
    // var grid = uv * tileCount;
    // let col  = i32(floor(grid.x));
    // let row  = i32(floor(grid.y));
    // var st = fract(grid);

    // let rnd = random( st * mouseX );
    // let color = vec3<f32>(rnd);

    var st = uv;
    st *= 10.0; // Scale the coordinate system by 10
    let y = uv.y / 10.0;
    let y_fract = fract(y);
    st.x += time*13.0 * y_fract;
    
    let ipos = floor(st);  // get the integer coords
    let fpos = fract(st);  // get the fractional coords

    // Assign a random value based on the integer coord
    let color = vec3(random( ipos ));
    // let color = vec3(fpos, 0.0);
    // let color = vec3(random( fpos ));

    return vec4<f32>(color, 1.0);
}
