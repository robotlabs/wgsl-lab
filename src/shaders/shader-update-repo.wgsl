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

fn plot(st: vec2<f32>) -> f32 {    
    return smoothstep(0.01, 0.0, abs(st.y - st.x));
}
fn plot2(st: vec2<f32>, pct:f32)  -> f32 {
  return  smoothstep( pct-0.02, pct, st.y) -
          smoothstep( pct, pct+0.02, st.y);
}

fn slopeFromT(t: f32, A: f32, B: f32, C: f32) -> f32 {
  return 1.0 / (3.0 * A * t * t + 2.0 * B * t + C);
}

fn xFromT(t: f32, A: f32, B: f32, C: f32, D: f32) -> f32 {
  return A * t * t * t + B * t * t + C * t + D;
}

fn yFromT(t: f32, E: f32, F: f32, G: f32, H: f32) -> f32 {
  return E * t * t * t + F * t * t + G * t + H;
}

fn constrain(x: f32, minVal: f32, maxVal: f32) -> f32 {
  return clamp(x, minVal, maxVal);
}

fn cubicBezier(x: f32, a: f32, b: f32, c: f32, d: f32) -> f32 {
  let y0a = 0.0;
  let x0a = 0.0;
  let y1a = b;
  let x1a = a;
  let y2a = d;
  let x2a = c;
  let y3a = 1.0;
  let x3a = 1.0;

  let A = x3a - 3.0 * x2a + 3.0 * x1a - x0a;
  let B = 3.0 * x2a - 6.0 * x1a + 3.0 * x0a;
  let C = 3.0 * x1a - 3.0 * x0a;
  let D = x0a;

  let E = y3a - 3.0 * y2a + 3.0 * y1a - y0a;
  let F = 3.0 * y2a - 6.0 * y1a + 3.0 * y0a;
  let G = 3.0 * y1a - 3.0 * y0a;
  let H = y0a;

  var currentt = x;
  for (var i = 0; i < 5; i = i + 1) {
    let currentx = xFromT(currentt, A, B, C, D);
    let slope = slopeFromT(currentt, A, B, C);
    currentt = constrain(currentt - (currentx - x) * slope, 0.0, 1.0);
  }

  return yFromT(currentt, E, F, G, H);
}

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
  // 1) Grid setup
  let time = transform.params[0][2] / 10.0;

  let tileCount = 20.0;
  var grid = uv * tileCount;
  let col  = i32(floor(grid.x));
  let row  = i32(floor(grid.y));


//     let sinTime = sin(time);
//     if (sinTime > 0){
//  if (col % 2 == 0){
//         // grid.x += step(1., modf(grid.y,2.0)) * 0.5 + time;
//         grid.y += sinTime;
//     } else{
//         // grid.x += step(1., modf(grid.y,2.0)) * 0.5 - time;
//         grid.y -= sinTime;
//     }
//     } else {
//          if (row % 2 == 0){
//         // grid.x += step(1., modf(grid.y,2.0)) * 0.5 + time;
//         grid.x += sinTime;
//     } else{
//         // grid.x += step(1., modf(grid.y,2.0)) * 0.5 - time;
//         grid.x -= sinTime;
//     }
//     }
   
  
  var st = fract(grid);

    var y = 0.0;
    var edge = 0.0;
    var base = vec3<f32>(0.0);
    if (row % 2 != 0){
         if (col % 2 == 0){
            let ap0x = 0.6; 
            let ap0y = 0.0; 
            let ap1x = 0.2; 
            let ap1y = 1.0; 
            y = cubicBezier(st.x, ap0x, ap0y, ap1x, ap1y);
            edge = smoothstep(y - 0.01, y, st.y) - smoothstep(y, y + 0.01, st.y);
            base = select(vec3<f32>(0.0), vec3<f32>(1.0), st.y < y);
        } else {
            let ap0x = 0.2; 
            let ap0y = 1.0; 
            let ap1x = 0.6; 
            let ap1y = 0.0; 
            let y = cubicBezier(st.x, ap0x, ap0y, ap1x, ap1y);
            edge = smoothstep(y - 0.01, y, st.y) - smoothstep(y, y + 0.01, st.y);
            base = select(vec3<f32>(0.0), vec3<f32>(1.0), st.y > y);
        }
    } else {
        if (col % 2 == 0){
            let ap0x = 0.2; 
            let ap0y = 1.0; 
            let ap1x = 0.6; 
            let ap1y = 0.0; 
            let y = cubicBezier(st.x, ap0x, ap0y, ap1x, ap1y);
            edge = smoothstep(y - 0.01, y, st.y) - smoothstep(y, y + 0.01, st.y);
            base = select(vec3<f32>(0.0), vec3<f32>(1.0), st.y > y);
        } else {
            let ap0x = 0.6; 
            let ap0y = 0.0; 
            let ap1x = 0.2; 
            let ap1y = 1.0; 
            y = cubicBezier(st.x, ap0x, ap0y, ap1x, ap1y);
            edge = smoothstep(y - 0.01, y, st.y) - smoothstep(y, y + 0.01, st.y);
            base = select(vec3<f32>(0.0), vec3<f32>(1.0), st.y < y);
        }
    }
   
    let color = mix(base, vec3<f32>(0.0, 1.0, 0.0), edge);

    return vec4<f32>(color, 1.0);
}
