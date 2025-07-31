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

// Tree generation function
fn generate_tree(pos: vec2<f32>, terrain_x: f32, u_time: f32) -> vec3<f32> {
    let tree_spacing = 0.3;
    let tree_id = floor(terrain_x / tree_spacing);
    let tree_local_x = fract(terrain_x / tree_spacing);
    
    // Random tree placement
    let tree_random = random(vec2<f32>(tree_id, 0.0));
    if (tree_random < 0.3) { return vec3<f32>(0.0); } // No tree here
    
    let tree_center = 0.5;
    let tree_width = 0.15;
    let tree_height = 0.08 + tree_random * 0.06;
    
    let dist_from_center = abs(tree_local_x - tree_center);
    
    // Tree trunk
    if (dist_from_center < 0.02 && pos.y < tree_height * 0.4) {
        return vec3<f32>(0.4, 0.2, 0.1); // Brown trunk
    }
    
    // Tree canopy - stylized round shape
    let canopy_center_y = tree_height * 0.7;
    let canopy_radius = tree_width * (0.8 + 0.2 * sin(u_time * 2.0 + tree_id)); // Slight animation
    let canopy_dist = distance(vec2<f32>(tree_local_x, pos.y), vec2<f32>(tree_center, canopy_center_y));
    
    if (canopy_dist < canopy_radius) {
        // Add some leaf texture
        let leaf_noise = noise(vec2<f32>(terrain_x * 20.0, pos.y * 20.0 + u_time * 0.5));
        let green_variation = mix(
            vec3<f32>(0.2, 0.6, 0.1), // Dark green
            vec3<f32>(0.4, 0.8, 0.2), // Light green
            leaf_noise
        );
        return green_variation;
    }
    
    return vec3<f32>(0.0); // No tree element
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
    let terrain_height = fbm(vec2<f32>(terrain_x * 2.0, 0.0)) * 0.4 + 0.3;
    let hills = fbm(vec2<f32>(terrain_x * 0.5, 0.0)) * 0.3;
    let final_terrain_height = terrain_height + hills;
    
    var color = vec3<f32>(0.0);
    
    // Sky gradient
    if (st.y > final_terrain_height) {
        // Enhanced sky gradient
        let sky_gradient = smoothstep(0.0, 1.0, st.y);
        color = mix(
            vec3<f32>(0.7, 0.9, 1.0), // Light blue at horizon
            vec3<f32>(0.1, 0.3, 0.7), // Darker blue at top
            sky_gradient
        );
        
        // Improved multi-layer clouds
        let cloud_time = u_time * 0.03;
        
        // Large cloud formations
        let cloud_base = fbm(vec2<f32>(terrain_x * 0.2 + cloud_time, st.y * 1.5));
        let cloud_detail = fbm(vec2<f32>(terrain_x * 0.8 + cloud_time * 1.2, st.y * 3.0));
        let cloud_fine = noise(vec2<f32>(terrain_x * 2.0 + cloud_time * 0.8, st.y * 6.0));
        
        let cloud_density = cloud_base * 0.6 + cloud_detail * 0.3 + cloud_fine * 0.1;
        let cloud_threshold = 0.4 + 0.1 * sin(st.y * 2.0); // Varying threshold
        
        if (cloud_density > cloud_threshold && st.y > 0.5) {
            let cloud_strength = smoothstep(cloud_threshold, cloud_threshold + 0.2, cloud_density);
            let cloud_color = mix(
                vec3<f32>(0.9, 0.9, 0.95), // Light gray
                vec3<f32>(1.0, 1.0, 1.0),  // White
                cloud_strength
            );
            color = mix(color, cloud_color, cloud_strength * 0.8);
        }
        
        // Distant cloud shadows on terrain
        let shadow_clouds = fbm(vec2<f32>(terrain_x * 0.15, 0.8));
        if (shadow_clouds > 0.6) {
            color *= 0.85; // Slight dimming
        }
    }
    // Ground/Terrain
    else {
        let depth_below_surface = final_terrain_height - st.y;
        let relative_pos = vec2<f32>(terrain_x, st.y - final_terrain_height);
        
        // Check for trees first (above ground)
        if (depth_below_surface < 0.12 && depth_below_surface > -0.05) {
            let tree_color = generate_tree(relative_pos, terrain_x, u_time);
            if (length(tree_color) > 0.1) {
                color = tree_color;
            } else {
                // Enhanced grass surface with variation
                let grass_noise = noise(vec2<f32>(terrain_x * 12.0, st.y * 8.0));
                let grass_detail = noise(vec2<f32>(terrain_x * 25.0, st.y * 15.0 + u_time * 0.2));
                
                color = mix(
                    vec3<f32>(0.25, 0.6, 0.15), // Dark grass
                    vec3<f32>(0.4, 0.8, 0.25),  // Light grass
                    grass_noise
                );
                
                // Add grass blade details
                if (grass_detail > 0.7 && depth_below_surface < 0.02) {
                    color = mix(color, vec3<f32>(0.5, 0.9, 0.3), 0.4);
                }
            }
        }
        // Underground layers with smooth gradients
        else {
            let depth_factor = smoothstep(0.0, 0.8, depth_below_surface);
            
            // Smooth transition from dirt to stone
            let dirt_color = vec3<f32>(0.6, 0.4, 0.2);   // Brown dirt
            let stone_color = vec3<f32>(0.3, 0.3, 0.35);  // Gray stone
            
            color = mix(dirt_color, stone_color, depth_factor);
            
            // Add underground texture and mineral veins
            let underground_noise = fbm(vec2<f32>(terrain_x * 4.0, st.y * 6.0));
            let vein_noise = noise(vec2<f32>(terrain_x * 8.0 + u_time * 0.1, st.y * 12.0));
            
            // Rock texture variation
            color = mix(color, color * 0.7, underground_noise * 0.3);
            
            // Mineral veins (subtle gold/copper streaks)
            if (vein_noise > 0.8 && depth_below_surface > 0.3) {
                let vein_color = vec3<f32>(0.7, 0.5, 0.2); // Copper color
                color = mix(color, vein_color, (vein_noise - 0.8) * 2.0 * 0.3);
            }
        }
        
        // Enhanced lighting with ambient occlusion
        let slope = fbm(vec2<f32>(terrain_x * 2.0 + 0.01, 0.0)) - fbm(vec2<f32>(terrain_x * 2.0 - 0.01, 0.0));
        let lighting = 0.8 + 0.3 * (1.0 - abs(slope * 8.0));
        
        // Ambient occlusion for underground areas
        let ao = 1.0 - smoothstep(0.0, 0.4, depth_below_surface) * 0.4;
        
        color *= lighting * ao;
    }
    
    return vec4<f32>(color, 1.0);
}