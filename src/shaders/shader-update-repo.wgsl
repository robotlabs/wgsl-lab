struct Transform {
  modelMatrix: mat4x4<f32>,
  viewMatrix:  mat4x4<f32>,
  projMatrix:  mat4x4<f32>,
  color:       vec4<f32>,
  useTexture:  vec4<f32>,
  params:      array<vec4<f32>, 2>, // [0].xy = mouse, [0].z = time, [1].xy = resolution
};
@group(0) @binding(0) var<uniform> transform: Transform;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0)        fragColor: vec4<f32>,
  @location(1)        uv       : vec2<f32>,
};

@vertex
fn vs_main(
  @location(0) position: vec3<f32>,
) -> VertexOutput {
  // exactly your original vertex shader:
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}


// helper to draw an “X”
fn drawX(st: vec2<f32>) -> f32 {
  let w = 0.1; // line half-thickness
  // diagonal 1
  let d1 = smoothstep(w, 0.0, abs(st.x - st.y));
  // diagonal 2
  let d2 = smoothstep(w, 0.0, abs((1.0 - st.x) - st.y));
  return max(d1, d2);
}

// helper to draw an “O”
fn drawO(st: vec2<f32>) -> f32 {
  let w = 0.1; // ring half-thickness
  let size = 0.3;
  let dist = length(st - vec2<f32>(0.5));
  let inner = smoothstep(size - w, size - w * size, dist);
  let outer = smoothstep(size + w * size, size + w, dist);
  return inner - outer;
}

fn rotate2D_old(_st: vec2<f32>, _angle: f32) -> vec2<f32>{
    var _st2 =  mat2x2<f32>(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st2 += 0.5;
    return _st2;
}
fn rotate2D(st: vec2<f32>, angle: f32) -> vec2<f32> {
  // 1) move to center
  let p = st - vec2<f32>(0.5, 0.5);
  // 2) rotate
  let c = cos(angle);
  let s = sin(angle);
  let x = p.x * c - p.y * s;
  let y = p.x * s + p.y * c;
  // 3) move back
  return vec2<f32>(x, y) + vec2<f32>(0.5, 0.5);
}
@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let t = transform.params[0][2] / 4.0;
  // 1) grid setup
  let tileCount = 3.0;
  let grid     = uv * tileCount;
  let col      = i32(floor(grid.x));
  let row      = i32(floor(grid.y));
  var st       = fract(grid);      // local UV within [0,1] cell

  // 2) choose shape: 0=blank,1=X,2=O
  var shape: i32 = 0;
  // place X on main diagonal
  if ((col == 0 && row == 0) ||
      (col == 1 && row == 1) ||
      (col == 2 && row == 2)) {
    shape = 1;
  }
  // place O on the anti-diagonal corners
  if ((col == 2 && row == 0) ||
      (col == 0 && row == 2)) {
    shape = 2;
  }

  // 3) draw it
  var c = vec3<f32>(0.0);
  if (shape == 1) {
     st = rotate2D(st,3.14 * t *0.25);
    c = vec3<f32>(1.0, 0.0, 0.0) * drawX(st);
  } else if (shape == 2) {
    c = vec3<f32>(0.0, 0.0, 1.0) * drawO(st);
  }

  return vec4<f32>(c, 1.0);
}