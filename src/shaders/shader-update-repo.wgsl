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

// -----------------------------------------
// Noise Functions
// -----------------------------------------
fn random(st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);

    // Four corners in 2D of a tile
    let a = random(i);
    let b = random(i + vec2<f32>(1.0, 0.0));
    let c = random(i + vec2<f32>(0.0, 1.0));
    let d = random(i + vec2<f32>(1.0, 1.0));

    let u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

const OCTAVES: i32 = 8;
fn fbm(st_input: vec2<f32>) -> f32 {
    // Initial values
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var st = st_input;
    
    // Loop of octaves
    for (var i: i32 = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z;
    
    // Adjust coordinates for aspect ratio
    var st = uv;
    st.x *= u_resolution.x / u_resolution.y;
    
    // Create landscape height using FBM
    let height = fbm(st * 3.0 + vec2<f32>(u_time * 0.1, 0.0));
    
    // Create different terrain zones based on height
    var color = vec3<f32>(0.0);
    
    // Water (low areas)
    if (height < 0.3) {
        color = mix(
            vec3<f32>(0.1, 0.3, 0.8), // Deep water
            vec3<f32>(0.3, 0.6, 1.0), // Shallow water
            height / 0.3
        );
    }
    // Beach/Sand (medium-low areas)
    else if (height < 0.4) {
        color = vec3<f32>(0.9, 0.8, 0.6); // Sand color
    }
    // Grass/Plains (medium areas)
    else if (height < 0.6) {
        color = mix(
            vec3<f32>(0.4, 0.7, 0.3), // Light green
            vec3<f32>(0.2, 0.5, 0.1), // Dark green
            (height - 0.4) / 0.2
        );
    }
    // Mountains (high areas)
    else if (height < 0.8) {
        color = mix(
            vec3<f32>(0.5, 0.4, 0.3), // Brown
            vec3<f32>(0.3, 0.3, 0.3), // Dark rock
            (height - 0.6) / 0.2
        );
    }
    // Snow peaks (highest areas)
    else {
        color = mix(
            vec3<f32>(0.3, 0.3, 0.3), // Rock
            vec3<f32>(0.9, 0.9, 1.0), // Snow
            (height - 0.8) / 0.2
        );
    }
    
    // Add some atmospheric perspective (distance fog)
    let fog_factor = smoothstep(0.0, 1.0, st.y);
    color = mix(color, vec3<f32>(0.7, 0.8, 0.9), fog_factor * 0.3);
    
    // Add subtle lighting based on height gradients
    let light_dir = vec2<f32>(1.0, 1.0);
    let gradient_x = fbm((st + vec2<f32>(0.01, 0.0)) * 3.0) - height;
    let gradient_y = fbm((st + vec2<f32>(0.0, 0.01)) * 3.0) - height;
    let normal = normalize(vec3<f32>(-gradient_x, -gradient_y, 0.1));
    let lighting = dot(normal.xy, normalize(light_dir)) * 0.5 + 0.5;
    
    color *= 0.7 + 0.3 * lighting;
    
    return vec4<f32>(color, 1.0);
}