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
// Utility Functions
// -----------------------------------------
fn random(st: vec2<f32>) -> f32 {
    return fract(sin(dot(st.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453123);
}

fn noise(st: vec2<f32>) -> f32 {
    let i = floor(st);
    let f = fract(st);
    let a = random(i);
    let b = random(i + vec2<f32>(1.0, 0.0));
    let c = random(i + vec2<f32>(0.0, 1.0));
    let d = random(i + vec2<f32>(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

fn fbm(st_input: vec2<f32>) -> f32 {
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var st = st_input;
    
    for (var i: i32 = 0; i < 6; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// SDF functions for shapes
fn sdf_circle(p: vec2<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdf_box(p: vec2<f32>, b: vec2<f32>) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

fn sdf_triangle(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>, c: vec2<f32>) -> f32 {
    let e0 = b - a;
    let e1 = c - b; 
    let e2 = a - c;
    
    let v0 = p - a;
    let v1 = p - b;
    let v2 = p - c;
    
    let pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    let pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    let pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    
    let s = sign(e0.x * e2.y - e0.y * e2.x);
    let d = min(min(vec2<f32>(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                    vec2<f32>(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                    vec2<f32>(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    
    return -sqrt(d.x) * sign(d.y);
}

// Continuous terrain generation
fn get_terrain_height(x: f32, layer: i32) -> f32 {
    var height: f32 = 0.0;
    
    if (layer == 0) { // Background mountains
        height = 0.4 + fbm(vec2<f32>(x * 0.8, 0.0)) * 0.5;
        height += fbm(vec2<f32>(x * 2.0, 10.0)) * 0.1;
    } else if (layer == 1) { // Mid mountains  
        height = 0.25 + fbm(vec2<f32>(x * 1.2, 20.0)) * 0.4;
        height += fbm(vec2<f32>(x * 3.0, 30.0)) * 0.08;
    } else { // Foreground hills
        height = 0.15 + fbm(vec2<f32>(x * 1.8, 40.0)) * 0.25;
        height += fbm(vec2<f32>(x * 4.0, 50.0)) * 0.05;
    }
    
    return height;
}

// Generate celestial objects
fn generate_sky_objects(st: vec2<f32>, u_time: f32) -> vec3<f32> {
    var color = vec3<f32>(0.0);
    
    // Main celestial body (moves slowly)
    let main_pos = vec2<f32>(
        0.2 + 0.6 * sin(u_time * 0.02),
        0.75 + 0.15 * cos(u_time * 0.015)
    );
    let main_size = 0.08;
    
    // Main body
    if (sdf_circle(st - main_pos, main_size) < 0.0) {
        color = vec3<f32>(0.0);
        
        // Add surface details
        let crater1 = main_pos + vec2<f32>(0.025, 0.02);
        if (sdf_circle(st - crater1, main_size * 0.25) < 0.0) {
            color = vec3<f32>(0.88);
        }
        
        let crater2 = main_pos + vec2<f32>(-0.02, 0.03);
        if (sdf_circle(st - crater2, main_size * 0.15) < 0.0) {
            color = vec3<f32>(0.88);
        }
    }
    
    // Rings (if it's a planet)
    if (sin(u_time * 0.01) > 0.0) {
        let ring_dist = length(st - main_pos);
        let ring_angle = atan2(st.y - main_pos.y, st.x - main_pos.x);
        let ring_thickness = 0.005 * (1.0 + 0.3 * sin(ring_angle * 8.0));
        
        if (ring_dist > main_size * 1.4 && ring_dist < main_size * 2.2) {
            if (abs(ring_dist - main_size * 1.8) < ring_thickness) {
                color = vec3<f32>(0.0);
            }
        }
    }
    
    // Smaller moon
    let moon_pos = vec2<f32>(
        0.7 + 0.2 * cos(u_time * 0.03),
        0.6 + 0.1 * sin(u_time * 0.025)
    );
    
    if (sdf_circle(st - moon_pos, 0.025) < 0.0) {
        color = vec3<f32>(0.0);
    }
    
    // Stars
    let star_cell = floor(st * 25.0);
    let star_noise = random(star_cell);
    if (star_noise > 0.95 && st.y > 0.5) {
        let star_pos = fract(st * 25.0);
        if (length(star_pos - vec2<f32>(0.5)) < 0.1) {
            color = vec3<f32>(0.0);
        }
    }
    
    return color;
}

// Generate complex structures within terrain
fn generate_terrain_details(st: vec2<f32>, terrain_height: f32, world_x: f32) -> vec3<f32> {
    var color = vec3<f32>(0.0);
    let depth_below = terrain_height - st.y;
    
    if (depth_below > 0.0) {
        // Cave systems
        let cave_noise = fbm(vec2<f32>(world_x * 3.0, st.y * 8.0));
        let cave_mask = fbm(vec2<f32>(world_x * 1.5, st.y * 4.0 + 100.0));
        
        if (cave_noise > 0.6 && cave_mask > 0.4 && depth_below > 0.05 && depth_below < 0.4) {
            color = vec3<f32>(0.88); // Light cave interior
            
            // Stalactites and stalagmites
            let spike_noise = noise(vec2<f32>(world_x * 12.0, st.y * 12.0));
            if (spike_noise > 0.8) {
                color = vec3<f32>(0.0); // Black spikes
            }
        }
        
        // Underground structures/ruins
        let structure_spacing = 0.6;
        let structure_id = floor(world_x / structure_spacing);
        let structure_x = fract(world_x / structure_spacing);
        let structure_seed = random(vec2<f32>(structure_id, 0.0));
        
        if (structure_seed > 0.75 && depth_below > 0.1 && depth_below < 0.35) {
            // Ancient pillars
            let pillar_x = 0.5;
            let pillar_width = 0.04;
            let pillar_height = 0.25;
            
            if (abs(structure_x - pillar_x) < pillar_width) {
                let pillar_y = terrain_height - pillar_height;
                if (st.y > pillar_y && st.y < terrain_height - 0.05) {
                    color = vec3<f32>(0.88);
                    
                    // Pillar segments
                    let segment = floor((terrain_height - st.y) * 8.0);
                    if (fract(segment * 0.5) < 0.1) {
                        color = vec3<f32>(0.0);
                    }
                }
            }
            
            // Arches
            let arch_center = vec2<f32>(pillar_x, terrain_height - 0.12);
            let arch_outer = sdf_circle(st - arch_center, 0.08);
            let arch_inner = sdf_circle(st - arch_center, 0.05);
            
            if (arch_outer < 0.0 && arch_inner > 0.0 && st.y < terrain_height - 0.05) {
                color = vec3<f32>(0.88);
            }
        }
        
        // Geometric patterns in rock
        let pattern_scale = 15.0;
        let pattern_noise = noise(vec2<f32>(world_x * pattern_scale, st.y * pattern_scale));
        let pattern_grid = floor(vec2<f32>(world_x * pattern_scale, st.y * pattern_scale));
        let pattern_seed = random(pattern_grid);
        
        if (pattern_seed > 0.9 && pattern_noise > 0.7) {
            let cell_pos = fract(vec2<f32>(world_x * pattern_scale, st.y * pattern_scale));
            
            // Hexagonal cells
            let hex_center = vec2<f32>(0.5);
            let hex_dist = length(cell_pos - hex_center);
            if (hex_dist > 0.3 && hex_dist < 0.4) {
                color = vec3<f32>(0.88);
            }
        }
        
        // Mineral veins
        let vein_noise = fbm(vec2<f32>(world_x * 8.0 + st.y * 2.0, st.y * 6.0));
        let vein_flow = fbm(vec2<f32>(world_x * 4.0, st.y * 10.0 + world_x * 2.0));
        
        if (vein_noise > 0.7 && vein_flow > 0.6) {
            color = vec3<f32>(0.88);
        }
        
        // Surface structures
        if (depth_below < 0.08) {
            let surface_structure = random(vec2<f32>(floor(world_x * 2.0), 0.0));
            let local_x = fract(world_x * 2.0);
            
            if (surface_structure > 0.8) {
                // Pyramids
                let pyramid_center = 0.5;
                let pyramid_width = 0.3;
                let pyramid_height = 0.15;
                
                let pyramid_dist = abs(local_x - pyramid_center);
                let pyramid_y = terrain_height - pyramid_height * (1.0 - pyramid_dist / pyramid_width);
                
                if (st.y > pyramid_y && st.y < terrain_height && pyramid_dist < pyramid_width) {
                    color = vec3<f32>(0.88);
                    
                    // Pyramid steps
                    let step_height = 0.02;
                    let step_level = floor((terrain_height - st.y) / step_height);
                    let step_width = pyramid_width * (1.0 - step_level * step_height / pyramid_height);
                    
                    if (pyramid_dist > step_width) {
                        color = vec3<f32>(0.0);
                    }
                }
            } else if (surface_structure > 0.7) {
                // Obelisks
                let obelisk_center = 0.5;
                let obelisk_width = 0.03;
                let obelisk_height = 0.12;
                
                if (abs(local_x - obelisk_center) < obelisk_width) {
                    if (st.y > terrain_height - obelisk_height && st.y < terrain_height) {
                        color = vec3<f32>(0.88);
                        
                        // Obelisk tip
                        let tip_factor = (terrain_height - st.y) / obelisk_height;
                        let tip_width = obelisk_width * (1.0 - tip_factor * 0.7);
                        if (abs(local_x - obelisk_center) > tip_width) {
                            color = vec3<f32>(0.0);
                        }
                    }
                }
            }
        }
    }
    
    return color;
}

@fragment
fn fs_main(
    @location(0) fragColor: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z;
    
    var st = uv;
    st.x *= u_resolution.x / u_resolution.y;
    
    let scroll_speed = u_time * 0.1;
    let world_x = st.x + scroll_speed;
    
    // Sky gradient
    var color = mix(
        vec3<f32>(0.85, 0.85, 0.87),
        vec3<f32>(0.78, 0.78, 0.82),
        smoothstep(0.0, 1.0, st.y)
    );
    
    // Add sky objects
    let sky_objects = generate_sky_objects(st, u_time);
    if (length(sky_objects) > 0.1) {
        color = sky_objects;
    }
    
    // Generate continuous terrain layers
    let back_terrain = get_terrain_height(world_x, 0);
    let mid_terrain = get_terrain_height(world_x, 1);
    let front_terrain = get_terrain_height(world_x, 2);
    
    // Render terrain from back to front
    if (st.y < back_terrain) {
        color = vec3<f32>(0.0);
    }
    
    if (st.y < mid_terrain) {
        color = vec3<f32>(0.0);
    }
    
    if (st.y < front_terrain) {
        color = vec3<f32>(0.0);
        
        // Add detailed structures within the terrain
        let terrain_details = generate_terrain_details(st, front_terrain, world_x);
        if (length(terrain_details) > 0.1) {
            color = terrain_details;
        }
    }
    
    return vec4<f32>(color, 1.0);
}