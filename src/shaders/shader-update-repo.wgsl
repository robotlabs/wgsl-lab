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
    
    // Side-scrolling coordinates
    var st = uv;
    st.x *= u_resolution.x / u_resolution.y;
    
    // Create scrolling terrain - X axis is horizontal distance, Y axis is height
    let scroll_speed = u_time * 0.2;
    let terrain_x = st.x + scroll_speed;
    
    // Generate terrain height profile using FBM
    // Scale X more for rolling hills, less Y scale for smoother transitions
    let terrain_height = fbm(vec2<f32>(terrain_x * 2.0, 0.0)) * 0.4 + 0.3;
    
    // Add some larger hill features
    let hills = fbm(vec2<f32>(terrain_x * 0.5, 0.0)) * 0.3;
    let final_terrain_height = terrain_height + hills;
    
    var color = vec3<f32>(0.0);
    
    // Sky gradient
    if (st.y > final_terrain_height) {
        // Sky with gradient from light blue to darker blue
        let sky_gradient = smoothstep(0.0, 1.0, st.y);
        color = mix(
            vec3<f32>(0.6, 0.8, 1.0), // Light blue at horizon
            vec3<f32>(0.2, 0.4, 0.8), // Darker blue at top
            sky_gradient
        );
        
        // Add some clouds
        let cloud_noise = fbm(vec2<f32>(terrain_x * 0.3, st.y * 2.0 + u_time * 0.05));
        if (cloud_noise > 0.6 && st.y > 0.6) {
            color = mix(color, vec3<f32>(1.0, 1.0, 1.0), (cloud_noise - 0.6) * 2.0);
        }
    }
    // Ground/Terrain
    else {
        let depth_below_surface = final_terrain_height - st.y;
        
        // Surface grass
        if (depth_below_surface < 0.05) {
            color = vec3<f32>(0.3, 0.7, 0.2); // Grass green
        }
        // Dirt layer
        else if (depth_below_surface < 0.2) {
            color = vec3<f32>(0.6, 0.4, 0.2); // Brown dirt
        }
        // Stone/Rock deep underground
        else {
            color = vec3<f32>(0.4, 0.4, 0.4); // Gray stone
        }
        
        // Add some surface detail with noise
        let surface_detail = noise(vec2<f32>(terrain_x * 8.0, st.y * 8.0));
        color = mix(color, color * 0.8, surface_detail * 0.3);
        
        // Simple lighting - surfaces facing up are brighter
        let slope = fbm(vec2<f32>(terrain_x * 2.0 + 0.01, 0.0)) - fbm(vec2<f32>(terrain_x * 2.0 - 0.01, 0.0));
        let lighting = 0.7 + 0.3 * (1.0 - abs(slope * 10.0));
        color *= lighting;
    }
    
    return vec4<f32>(color, 1.0);
}