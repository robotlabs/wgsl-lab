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

fn random2( p: vec2<f32> ) -> vec2<f32> {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// DIFFERENT POINTS ANIMATIONS!!!!
// 1. CIRCULAR ORBITS - Points rotate in circles
fn circular_orbit(point: vec2<f32>, time: f32) -> vec2<f32> {
    let speed = 0.5 + point.x * 0.3; // Different speeds per point
    let radius = 0.2 + point.y * 0.1; // Different radii
    let angle = time * speed + point.x * 6.28; // Phase offset
    return 0.5 + vec2<f32>(cos(angle), sin(angle)) * radius;
}

// 2. FIGURE-8 LISSAJOUS CURVES
fn figure_eight(point: vec2<f32>, time: f32) -> vec2<f32> {
    let freq_x = 1.0 + point.x * 0.5;
    let freq_y = 2.0 + point.y * 0.5; // Different frequency = figure-8
    return 0.5 + 0.3 * vec2<f32>(
        sin(time * freq_x + point.x * 6.28),
        sin(time * freq_y + point.y * 6.28)
    );
}

// 3. BROWNIAN MOTION - Random walk
fn brownian_motion(point: vec2<f32>, time: f32) -> vec2<f32> {
    // Use multiple octaves of noise for smoother random walk
    var pos = 0.5 + 0.2 * vec2<f32>(
        sin(time * 0.7 + point.x * 12.34) + 0.5 * sin(time * 1.3 + point.y * 23.45),
        cos(time * 0.8 + point.y * 34.56) + 0.5 * cos(time * 1.1 + point.x * 45.67)
    );
    return pos;
}

// 4. SPIRAL MOTION - Points spiral outward/inward
fn spiral_motion(point: vec2<f32>, time: f32) -> vec2<f32> {
    let speed = 0.5 + point.x * 0.3;
    let angle = time * speed + point.x * 6.28;
    let radius = 0.1 + 0.2 * abs(sin(time * 0.2 + point.y * 3.14)); // Pulsing radius
    return 0.5 + vec2<f32>(cos(angle), sin(angle)) * radius;
}

// 5. ELASTIC BOUNCING - Points bounce off invisible walls
fn elastic_bounce(point: vec2<f32>, time: f32) -> vec2<f32> {
    let speed = 1.0 + point.x * 0.5;
    var pos = 0.5 + 0.4 * sin(time * speed + point * 6.28);
    // Add some bounce physics
    pos = abs(fract(pos + 0.5) - 0.5) * 2.0;
    return pos * 0.8 + 0.1; // Keep in bounds
}

// 6. WAVE PROPAGATION - Points follow traveling waves
fn wave_propagation(point: vec2<f32>, time: f32, grid_pos: vec2<f32>) -> vec2<f32> {
    let wave_center = vec2<f32>(0.5); // Wave origin
    let dist_from_center = distance(grid_pos, wave_center);
    let wave = sin(time * 2.0 - dist_from_center * 10.0) * 0.1;
    return 0.5 + point * 0.3 + vec2<f32>(wave, wave * 0.7);
}

// 7. FLOCKING BEHAVIOR - Points try to follow their neighbors
fn flocking_behavior(point: vec2<f32>, time: f32, grid_pos: vec2<f32>) -> vec2<f32> {
    // Simplified flocking - points move toward grid center with noise
    let center_pull = (vec2<f32>(0.5) - grid_pos) * 0.1;
    let noise_offset = 0.2 * vec2<f32>(
        sin(time + point.x * 8.0),
        cos(time * 1.3 + point.y * 6.0)
    );
    return 0.5 + center_pull + noise_offset;
}

// 8. PENDULUM MOTION - Points swing like pendulums
fn pendulum_motion(point: vec2<f32>, time: f32) -> vec2<f32> {
    let period = 2.0 + point.x * 1.0; // Different periods
    let amplitude = 0.2 + point.y * 0.1;
    let swing_x = sin(time * 6.28 / period) * amplitude;
    let swing_y = cos(time * 6.28 / period * 0.5) * amplitude * 0.3; // Slight Y motion
    return vec2<f32>(0.5 + swing_x, 0.5 + swing_y);
}

// 9. MAGNETIC FIELD - Points follow field lines
fn magnetic_field(point: vec2<f32>, time: f32, grid_pos: vec2<f32>) -> vec2<f32> {
    let magnet1 = vec2<f32>(0.3, 0.3);
    let magnet2 = vec2<f32>(0.7, 0.7);
    let field1 = normalize(grid_pos - magnet1) * 0.1;
    let field2 = normalize(magnet2 - grid_pos) * 0.1;
    let combined_field = field1 + field2;
    return 0.5 + combined_field * sin(time) + point * 0.1;
}

// 10. HEARTBEAT PULSE - Points pulse from center
fn heartbeat_pulse(point: vec2<f32>, time: f32, grid_pos: vec2<f32>) -> vec2<f32> {
    let beat = abs(sin(time * 4.0)) * 0.5 + 0.5; // Heartbeat rhythm
    let center = vec2<f32>(0.5);
    let direction = normalize(grid_pos - center + vec2<f32>(0.001)); // Avoid division by zero
    let pulse_offset = direction * beat * 0.2;
    return center + pulse_offset + point * 0.1;
}

// Usage in your main loop:
// Replace this line:
// point = 0.5 + 0.5 * sin(u_time + 6.2831 * point);
//
// With one of these:
// point = circular_orbit(point, u_time);
// point = figure_eight(point, u_time);
// point = brownian_motion(point, u_time);
// point = spiral_motion(point, u_time);
// point = elastic_bounce(point, u_time);
// point = wave_propagation(point, u_time, i_st + neighbor);
// point = flocking_behavior(point, u_time, i_st + neighbor);
// point = pendulum_motion(point, u_time);
// point = magnetic_field(point, u_time, i_st + neighbor);
// point = heartbeat_pulse(point, u_time, i_st + neighbor);

// BONUS: Combine multiple animations!
fn combined_animation(point: vec2<f32>, time: f32, grid_pos: vec2<f32>) -> vec2<f32> {
    let base = circular_orbit(point, time * 0.5);
    let pulse = heartbeat_pulse(point, time * 2.0, grid_pos);
    let noise = brownian_motion(point, time * 0.3);
    
    // Mix them based on time or position
    let mix_factor = (sin(time * 0.1) + 1.0) * 0.5;
    return mix(mix(base, pulse, 0.3), noise, mix_factor * 0.2);
}

     // Hash function to get a pseudo-random value for each cell
    fn hash(p: vec2<f32>) -> f32 {
        return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
    }

@fragment
fn fs_main(
  @location(0) fragColor: vec4<f32>,
  @location(1) uv:        vec2<f32>,
) -> @location(0) vec4<f32> {
    let u_resolution = transform.params[1].xy;
    let u_time = transform.params[0].z / 5;
    let mouse_px    = transform.params[0].xy;
    let resolution = transform.params[1].xy;
    let u_mouse    = mouse_px / resolution;
    let u_center_mouse = vec2<f32>(u_mouse.x, 1.0 - u_mouse.y);
    
    var st = uv;

    st *= 10.;
  // Tile the space
    let i_st = floor(st);
    let f_st = fract(st);

  

    var color = vec3(0.);
    // In your fragment shader:
    var m_dist = 1.0;  // minimum distance


        // --- 1. Add mouse-controlled point ---
    let mouse_point = vec2<f32>(
        u_mouse.x * 10.0, // Scale to grid space (0..10)
        (1.0 - u_mouse.y) * 10.0 // Flip Y-axis to match WGSL's coordinate system
    );

    // --- 2. Compute distance to mouse point ---
    let mouse_diff = mouse_point - st;
    m_dist = min(m_dist, length(mouse_diff));
    
    for (var y: i32 = -1; y <= 1; y++) {
        for (var x: i32 = -1; x <= 1; x++) {
            // Neighbor place in the grid
            let neighbor = vec2<f32>(f32(x), f32(y));
            
            // Random position from current + neighbor place in the grid
            var point = random2(i_st + neighbor);
            
            switch (i32(i_st.y * 10.0 + i_st.x)) { // Unique index for each cell
                // Row 0
                // case  0: { point = circular_orbit(point, u_time); }   
                // case  1: { point = figure_eight(point, u_time); }     
                // case  2: { point = brownian_motion(point, u_time); }  
                // case  3: { point = spiral_motion(point, u_time); }    
                // case  4: { point = elastic_bounce(point, u_time); }   
                // case  5: { point = wave_propagation(point, u_time, i_st + neighbor); }    
                // case  6: { point = flocking_behavior(point, u_time, i_st + neighbor); }   
                // case  7: { point = pendulum_motion(point, u_time); }    
                // case  8: { point = magnetic_field(point, u_time, i_st + neighbor); }    
                // case  9: { point = brownian_motion(point, u_time); }   
                // case  10: { point = heartbeat_pulse(point, u_time, i_st + neighbor); }    
                // ... add more cases as needed

                // // Row 1
                // case 10: { point = spiral_motion(point, u_time); }      // (0,1)
                // case 11: { point = elastic_bounce(point, u_time); }     // (1,1)
                // case 12: { point = wave_propagation(point, u_time, i_st + neighbor); } // (2,1)
                // // ... continue pattern

                // // Special cells
                // case 55: { point = flocking_behavior(point, u_time, i_st + neighbor); } // (5,5) center
                // case 99: { point = heartbeat_pulse(point, u_time, i_st + neighbor); }   // (9,9) bottom-right

                default: { 
                  // point = pendulum_motion(point, u_time); 
                  point = flocking_behavior(point, u_time, i_st + neighbor);
                  point = wave_propagation(point, u_time, i_st + neighbor);
                } // Fallback
            }
            
            // point = figure_eight(point, u_time);
            
            // Vector between the pixel and the point
            let diff = neighbor + point - f_st;
            
            // Distance to the point
            let dist = length(diff);
            
            // Keep the closer distance
            m_dist = min(m_dist, dist);
        }
    }

    // Draw the min distance (distance field)
    color += m_dist;

    // Draw cell center
    color += 1.0 - step(0.02, m_dist);

    // Draw grid
    // color.r += step(0.98, f_st.x) + step(0.98, f_st.y);

    // Show isolines (commented)
    // color -= step(0.7, abs(sin(27.0 * m_dist))) * 0.5;

    return vec4<f32>(color, 1.0);
}