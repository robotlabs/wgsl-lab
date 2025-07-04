// -----------------------------------------
// Constants (if you need them later)
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
  params:      array<vec4<f32>, 2>,  // [0].z = u_time
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

// -----------------------------------------
// Portable random()  
// -----------------------------------------
fn random2 (x: f32) -> f32{
    return fract(sin(x)*10000.0);
}
fn random(st: vec2<f32>) -> f32 {
  return fract(sin(dot(st, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

fn randomBand(x: f32, freq: f32) -> f32{
    return step(0.6, random2(floor(x * freq) - floor(x)));
}

@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    // time (in seconds)
     let time   = transform.params[0][2];
    
        let basePeriod         = 4.0;
    let rndIdx             = floor(time / basePeriod);
    let period             = 10.0;//mix(1.0, 4.0, random2(rndIdx));
    let period_speed             = mix(1.0, 4.0, random2(rndIdx));


    let period_direction = 20.0;
    
    let cycle = floor(time / period_speed);
    let rnd   = random2(cycle);

    let cycle_i = i32(floor(time / period_direction));

    let toggle  = cycle_i & 1;  // int 0 or 1

    let dir = 1.0 - f32(toggle) * 2.0;
    let phase = fract(time / period);
    

    let numRows:   f32 = 14.0;                              // ← your dynamic row count
    let rowIdx:    i32 = i32(floor(uv.y * numRows));       // which row [0..numRows-1]
    let parity:    i32 = 1;//rowIdx & 1;                       // even/odd
    let rowDir:    f32 = 1.0 - f32(parity) * 2.0;           // +1 for even rows, –1 for odd
    // ─────────────────────

    // 5) build your band frequency (unchanged)
    let freqA              = mix(20.0, 100.0, rnd);
    let freqB              = mix(10.0,  80.0, rnd);
    let isTop              = step(0.5, uv.y);               // still used for color
    let freq               = mix(freqA, freqB, isTop);

    // 6) ONE‐LINE shift for *every* row using rowDir
    let shiftAmt          = 0.25;

    let numRowsF = numRows; 
    let idxF     = f32(rowIdx) + 1.0;
    let half     = numRowsF * 0.5; 
    let denom = select(
        // else‐case: rowIdx > half
        numRowsF + 1.0 - idxF, 
        // then‐case: rowIdx <= half
        idxF, 
        idxF <= half
    );
    let x                 = uv.x + rowDir * dir * shiftAmt * phase * 4.0 / denom;
    
    let band = randomBand(x, freq);

    // 8) paint it
    let colorA = vec3<f32>(0.9686, 0.6235, 0.4745);
    let colorB = vec3<f32>(0.9686, 0.8157, 0.5412);
    let base   = mix(colorA, colorB, isTop);
    let bgColor = vec3<f32>(0.8902, 0.9412, 0.6078);
    let c = mix(bgColor, base, band);

    return vec4<f32>(c, 1.0);
}
