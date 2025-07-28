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
fn random2 (x: f32, seed: f32) -> f32{
    return fract(sin(x)*43758.5453123 * seed);
}
fn random1 (x: f32) -> f32{
    return fract(sin(x)*43758.5453123);
}



fn noise(x: f32, time: f32) -> f32 {
    let i = floor(x);
    let f = fract(x);
    let a = random2(i, time);
    let b = random2(i + 1.0, time);
    let u = mix(a, b, f);
    let u2 = mix(a, b, smoothstep(0., 1., f));
    return u2;

}

fn noise1(x: f32) -> f32 {
    let i = floor(x);
    let f = fract(x);
    let u = f * f * (3.0 - 2.0 * f);
    // return mix(random1(i), random1(i + 1.0), u);
    return mix(random1(i), random1(i + 1.0), smoothstep(0., 1., u));
}

// @fragment
// fn fs_main(
//   @location(0) fragColor: vec4<f32>,
//   @location(1) uv: vec2<f32>,
// ) -> @location(0) vec4<f32> {
//   var time = transform.params[0][2] / 200000.0;

//     let scale = 5.0;
//     let x = uv.x * scale;
//     let n = noise(x, time);

//     // Invert y (perché UV va da 0 in basso a 1 in alto)
//     let y = 1.0 - uv.y;

//     // Disegna un punto bianco se uv.y è vicino a noise(x)
//     let line = step(abs(y - n), 0.01); // più piccolo = linea più sottile
//     return vec4<f32>(vec3<f32>(line), 1.0);
// }

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {

    // 1
    // var time = transform.params[0][2] / 2000000.0;
    // let x = uv.x * 10.0;
    // let y = noise(x, time); 
    // let curve = 1.0 - y;
    // let line = step(uv.y, curve);  
      
    // return vec4<f32>(vec3<f32>(line), 1.0);


    // 2
    // let t = transform.params[0][2] / 1; // tempo
    // let rnNr = random(uv);
    // let n = noise1(t * 0.5); // noise animato
    // let n2 = noise1(t * 0.5);// - noise1(t * 0.5) + noise1(t * 0.5); 
    // let center = vec2<f32>(n, n2); // centro del cerchio che si muove
    // let d = distance(uv, center);
    // let circle = step(d, 0.1);
    // return vec4<f32>(vec3<f32>(circle), 1.0);

    // 3
    let t = transform.params[0][2] / 10; // tempo
    let rnNr = random(uv);
    let n = noise1((sin(t) + 2.0) * uv.y); // noise animato
    let n2 = noise1((sin(t) + 2.0) * uv.x);// - noise1(t * 0.5) + noise1(t * 0.5); 
    let center = vec2<f32>(n, n2); // centro del cerchio che si muove
    let d = distance(uv, center);
    let circle = step(d, 0.1);
    return vec4<f32>(vec3<f32>(circle), 1.0);

        // 4
    // let t = transform.params[0][2] / 10; // tempo
    // let rnNr = random(uv);
    // let n = noise1(t + 2.0 * uv.y); // noise animato
    // let n2 = noise1(t + 2.0 * uv.x);// - noise1(t * 0.5) + noise1(t * 0.5); 
    // let center = vec2<f32>(n, n2); // centro del cerchio che si muove
    // let d = distance(uv, center);
    // let circle = step(d, 0.1);
    // return vec4<f32>(vec3<f32>(circle), 1.0);
}