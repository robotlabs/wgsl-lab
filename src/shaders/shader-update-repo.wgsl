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
fn random2 (x: f32) -> f32{
    return fract(sin(x)*10000.0);
}

fn pattern(st: vec2<f32>, v: vec2<f32>, t: f32) -> f32 {
    let p = floor(st+v);
    return step(t, random(100. + p * .000001)+random2(p.x)*0.1 );
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    // var time = 0.0;//transform.params[0][2] / 2.0;
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
    let grid = vec2(200.0, 50.0);
    st *= grid;
    // let y = uv.y / 10.0;
    // let y_fract = fract(y);
    // st.x += time*13.0 * y_fract;
    
    let ipos = floor(st);  // get the integer coords
    let fpos = fract(st);  // get the fractional coords

    var vel = vec2(time*0.5*max(grid.x,grid.y)); // time
    vel *= vec2(-1.,0.0) * random2(1.0+ipos.y); // direction

    // Assign a random value base on the integer coord
    let offset = vec2(0.1,0.);

    var color = vec3(0.);
    var density = 0.2;
    color.r = pattern(st + offset,vel, 0.5 + density);
    color.g = pattern(st, vel, 0.5 + density);
    color.b = pattern(st - offset,vel, 0.5 + density);

    // Margins
    // color *= step(0.9,fpos.y);

    let mask   = step(0.2, fpos.y);               // 0 below, 1 above
    let bgColor = vec3<f32>(0.1, 1.0, 1.0);     
    let barColor   = vec3<f32>(1.0, 1.0, 0.0);
    color = mix(bgColor, color, mask);
    let finalColor = mix(bgColor, barColor, color);   

    return vec4<f32>(finalColor, 1.0);
}
