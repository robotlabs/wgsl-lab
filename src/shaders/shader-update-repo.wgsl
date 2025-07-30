
// -----------------------------------------
// Constants
// -----------------------------------------
const PI: f32 = 3.141592653589793;

// -----------------------------------------
// Transform struct
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

@vertex fn vs_main(@location(0) position: vec3<f32>) -> VertexOutput {
  let world = transform.modelMatrix * vec4<f32>(position, 1.0);
  var o: VertexOutput;
  o.Position  = transform.projMatrix * transform.viewMatrix * world;
  o.fragColor = transform.color;
  o.uv        = (position.xy + vec2<f32>(1.0)) * 0.5;
  return o;
}


fn random2(p: vec2<f32>) -> vec2<f32> {
    return fract(sin(vec2<f32>(
        dot(p, vec2<f32>(127.1, 311.7)),
        dot(p, vec2<f32>(269.5, 183.3))
    )) * 43758.5453);
}

fn voronoi(x: vec2<f32>, u_time: f32) -> vec3<f32> {
    let n = floor(x);
    let f = fract(x);
    
    // first pass: regular voronoi
    var mg: vec2<f32>;
    var mr: vec2<f32>;
    var md: f32 = 8.0;
    
    for (var j: i32 = -1; j <= 1; j++) {
        for (var i: i32 = -1; i <= 1; i++) {
            let g = vec2<f32>(f32(i), f32(j));
            var o = random2(n + g);
            o = 0.5 + 0.5 * sin(u_time + 6.2831 * o);
            let r = g + o - f;
            let d = dot(r, r);
            if (d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }
    
    // second pass: distance to borders
    md = 8.0;
    for (var j: i32 = -2; j <= 2; j++) {
        for (var i: i32 = -2; i <= 2; i++) {
            let g = mg + vec2<f32>(f32(i), f32(j));
            var o = random2(n + g);
            o = 0.5 + 0.5 * sin(u_time + 6.2831 * o);
            let r = g + o - f;
            if (dot(mr - r, mr - r) > 0.00001) {
                md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
            }
        }
    }
    
    return vec3<f32>(md, mr);
}

// -----------------------------------------
// Randomness Function
// -----------------------------------------
fn hash(n: f32) -> f32 {
    return fract(sin(n) * 43758.5453123);
}

@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z / 10; // Using raw time for proper animation speed
    
    // Center and rotate coordinates
    let center = vec2<f32>(0.5);
    let angle = u_time * 0.1;
    let rot = mat2x2<f32>(
        cos(angle), -sin(angle),
        sin(angle),  cos(angle)
    );
    var st = rot * (uv - center) + center;
    
    // Create rotating light position
    let light_pos = vec3<f32>(
        sin(u_time * 0.5),
        1.0,
        cos(u_time * 0.3)
    );
    
    // Initialize variables
    var closest_point = vec3<f32>(0.0);
    var min_dist: f32 = 4.0;
    let cell_count: f32 = 100.0;
    
    // Generate cellular pattern
    for (var i: f32 = 0.0; i < cell_count; i += 1.0) {
        // Create random cell position
        let angle = sin(u_time * PI * 0.00001) - hash(i) * PI * 2.0;
        let radius = sqrt(hash(angle)) * 0.5;
        let point = vec2<f32>(
            light_pos.x + cos(angle) * radius,
            light_pos.z + sin(angle) * radius
        );
        
        // Calculate distance to this cell
        let dist = distance(st, point);
        
        // Track closest cell
        if (dist < min_dist) {
            min_dist = dist;
            closest_point = vec3<f32>(
                point.x,
                point.y,
                i / cell_count * st.x * st.y // Unique z-value per cell
            );
        }
    }
    
    // Create lighting effect
    let light_intensity = 1.0 - max(0.0, dot(closest_point, light_pos));
    let shade = vec3<f32>(light_intensity);
    
    // Create vibrant unicorn colors
    let base_color = mix(
        vec3<f32>(0.8, 0.2, 0.6), // Pink
        vec3<f32>(0.3, 0.8, 0.9), // Cyan
        closest_point.z
    );
    
    // Add pulsing effect
    let pulse = sin(u_time * 2.0) * 0.1 + 0.9;
    let final_color = (base_color + shade) * pulse;
    
    return vec4<f32>(final_color, 1.0);
}