/*
    Project: Modular Amphitheater Cruise Duck Riser
    Status: Ready for OpenSCAD Generation
    
    Description: 
    A 3-tier laterally modular wedge riser forming a semicircle. 
    Features a solid back wall, 1.5mm chamfered edges, and lateral dovetail joints. 
    Internally sloped (45 degrees) to allow 100% support-free printing 
    in a right-side-up orientation.
*/

// --- PARAMETERS ---

// Amphitheater Geometry
num_modules_180 = 5;
wedge_angle = 36.0;         // 180 / 5
inner_radius = 105.0;

// Capacity and Layout / Step Geometry
num_tiers = 3;
tread_depth = 62.0;
step_rise = 28.0;
chamfer_size = 1.5;

// Structural Design
wall_thickness = 2.4;

// Interlocking Joints (Lateral Dovetail)
dt_tolerance = 0.25;        // Clearance
dt_width = 12.0;            // Base width of the dovetail
dt_neck = 7.0;              // Narrow neck of the dovetail
dt_depth = 6.0;             // Depth of the dovetail protrusion

// Resolution
$fn = 180;                  // High resolution for smooth arc

// --- CALCULATED VALUES ---
total_depth = num_tiers * tread_depth;
outer_radius = inner_radius + total_depth;
total_height = num_tiers * step_rise;

// Points for the outer solid polygon (with chamfered convex corners)
p_out_0  = [inner_radius, 0];
p_out_1  = [inner_radius, step_rise - chamfer_size];
p_out_2  = [inner_radius + chamfer_size, step_rise];
p_out_3  = [inner_radius + tread_depth, step_rise];
p_out_4  = [inner_radius + tread_depth, 2*step_rise - chamfer_size];
p_out_5  = [inner_radius + tread_depth + chamfer_size, 2*step_rise];
p_out_6  = [inner_radius + 2*tread_depth, 2*step_rise];
p_out_7  = [inner_radius + 2*tread_depth, 3*step_rise - chamfer_size];
p_out_8  = [inner_radius + 2*tread_depth + chamfer_size, 3*step_rise];
p_out_9  = [outer_radius - chamfer_size, 3*step_rise];
p_out_10 = [outer_radius, 3*step_rise - chamfer_size];
p_out_11 = [outer_radius, 0];

outer_poly = [
    p_out_0, p_out_1, p_out_2, p_out_3,
    p_out_4, p_out_5, p_out_6,
    p_out_7, p_out_8, p_out_9, p_out_10, p_out_11
];

// Calculation of the self-supporting 45-degree hollow cavity profile
r0 = inner_radius;
r1 = inner_radius + tread_depth;
r2 = inner_radius + 2*tread_depth;
r3 = outer_radius;

h1 = step_rise;
h2 = 2*step_rise;
h3 = 3*step_rise;

wt = wall_thickness;

// Tent 1 (Under Step 1)
t1_r_start = r0 + wt;
t1_r_end = r1 - wt;
t1_peak_r = (t1_r_start + t1_r_end) / 2;
t1_peak_z = h1 - wt;
t1_left_zero = t1_peak_r - t1_peak_z;
t1_right_zero = t1_peak_r + t1_peak_z;

// Tent 2 (Under Step 2)
t2_r_start = r1 + wt;
t2_r_end = r2 - wt;
t2_peak_r = (t2_r_start + t2_r_end) / 2;
t2_peak_z = h2 - wt;
t2_left_z_at_start = t2_peak_z - (t2_peak_r - t2_r_start);
t2_right_z_at_end = t2_peak_z - (t2_r_end - t2_peak_r);

// Tent 3 (Under Step 3)
t3_r_start = r2 + wt;
t3_r_end = r3 - wt;
t3_peak_r = (t3_r_start + t3_r_end) / 2;
t3_peak_z = h3 - wt;
t3_left_z_at_start = t3_peak_z - (t3_peak_r - t3_r_start);
t3_right_z_at_end = t3_peak_z - (t3_r_end - t3_peak_r);

inner_poly = [
    [t1_r_start, 0],
    [t1_left_zero, 0],
    [t1_peak_r, t1_peak_z],
    [t1_right_zero, 0],
    [t1_r_end, 0],
    
    [t2_r_start, 0],
    [t2_r_start, t2_left_z_at_start],
    [t2_peak_r, t2_peak_z],
    [t2_r_end, t2_right_z_at_end],
    [t2_r_end, 0],
    
    [t3_r_start, 0],
    [t3_r_start, t3_left_z_at_start],
    [t3_peak_r, t3_peak_z],
    [t3_r_end, t3_right_z_at_end],
    [t3_r_end, 0]
];

// --- MODULES ---

// Male dovetail pointing outwards (-Y direction relative to face)
module male_dovetail_3d(r, z_height) {
    tw = dt_width - dt_tolerance;
    tn = dt_neck - dt_tolerance;
    td = dt_depth - dt_tolerance/2;
    translate([r, 0, 0])
    linear_extrude(height=z_height)
    polygon([
        [-tn/2, 0.1],     // Overlap slightly to ensure manifold merge
        [-tw/2, -td],
        [tw/2, -td],
        [tn/2, 0.1]
    ]);
}

// Female dovetail cutout pointing inwards (+Y direction relative to face)
module female_dovetail_3d(r, z_height) {
    tw = dt_width + dt_tolerance;
    tn = dt_neck + dt_tolerance;
    td = dt_depth + dt_tolerance/2;
    translate([r, 0, 0])
    translate([0, 0, -1]) // Extend below 0 to ensure clean cut
    linear_extrude(height=z_height + 2) // Extend above step for top-down sliding
    polygon([
        [-tn/2, -0.1],    // Start slightly outside the face to ensure clean cut
        [-tw/2, td],
        [tw/2, td],
        [tn/2, -0.1]
    ]);
}

module duck_riser_wedge() {
    difference() {
        union() {
            // Main Body: Subtract hollow inner from solid outer
            difference() {
                // 1. Solid Outer Shape
                rotate_extrude(angle=wedge_angle)
                    polygon(outer_poly);
                
                // 2. Hollow Inner Cavity
                // Offset the angle slightly to maintain side wall thickness
                angle_offset = (wall_thickness / inner_radius) * (180 / PI);
                
                difference() {
                    rotate([0, 0, angle_offset])
                        rotate_extrude(angle=wedge_angle - 2*angle_offset)
                            polygon(inner_poly);
                    
                    // 3. INTERNAL REINFORCEMENTS
                    // Subtract solid cylinders from the cavity to ensure the 
                    // dovetails have solid plastic behind them instead of air.
                    
                    // Reinforce male side (angle = 0)
                    translate([t1_peak_r, 0, 0]) cylinder(h=h1, r=12);
                    translate([t2_peak_r, 0, 0]) cylinder(h=h2, r=12);
                    translate([t3_peak_r, 0, 0]) cylinder(h=h3, r=12);
                    
                    // Reinforce female side (angle = wedge_angle)
                    rotate([0, 0, wedge_angle]) {
                        translate([t1_peak_r, 0, 0]) cylinder(h=h1, r=12);
                        translate([t2_peak_r, 0, 0]) cylinder(h=h2, r=12);
                        translate([t3_peak_r, 0, 0]) cylinder(h=h3, r=12);
                    }
                }
            }
            
            // 4. Add Male Dovetails (Right Side / Angle 0)
            male_dovetail_3d(t1_peak_r, h1);
            male_dovetail_3d(t2_peak_r, h2);
            male_dovetail_3d(t3_peak_r, h3);
        }
        
        // 5. Subtract Female Dovetails (Left Side / Angle wedge_angle)
        rotate([0, 0, wedge_angle]) {
            female_dovetail_3d(t1_peak_r, h1);
            female_dovetail_3d(t2_peak_r, h2);
            female_dovetail_3d(t3_peak_r, h3);
        }
    }
}

// Generate the final part
duck_riser_wedge();