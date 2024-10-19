$fn=100;

pcb_width = 76.4;
pcb_height = 56.9;
pcb_wall_gap = 1;
wall_thickness = 2;
enclosure_height = 17;
stand_inner_r = 1;
stand_outer_r = 2;
stand_height = 2;
hole_chamfer_r = 2.5;
connector_hole_height = 9.25;
connector_hole_width = 75;

// top left - [-3mm, -3.5mm]
// top right - [-2.5mm, -3.5mm]
// bottom left - [-3mm , -12.25mm]
// bottom right - [-2.5mm, -12.25mm]
holes = [
            // top left
            [-pcb_width / 2 + 3, pcb_height / 2 - 3.5],
            // top right
            [pcb_width / 2 - 2.5, pcb_height / 2 - 3.5],
            // bottom left
            [-pcb_width / 2 + 3, -pcb_height / 2 + 12.25],
            // bottom right
            [pcb_width / 2 - 2.5, -pcb_height / 2 + 12.25]
];

// ESP dimensions [25.5, 17]
// position [pcb_width / 2, pcb_height / 2 - 13.8]
esp_width = 25.5;
esp_height = 17;
esp_x = pcb_width / 2 - esp_width / 2;
esp_y = pcb_height / 2 - 13.8 - esp_height / 2;

// RAM 628128 (628512) dimensions [15.6, 21.7]
// position [pcb_width / 2 - 29,6, pcb_height / 2 - 23]
ram_width = 15.6;
ram_height = 21.7;
ram_x = pcb_width / 2 - 29.6 - ram_width / 2;
ram_y = pcb_height / 2 - 23 - ram_height / 2;

// ROM 28C24 dimensions [12.3, 18.7]
// position [-pcb_width / 2 + 5, pcb_height / 2 - 22.5
rom_width = 12.3;
rom_height = 18.7;
rom_x = -pcb_width / 2 + 5 + rom_width / 2;
rom_y = pcb_height / 2 - 22.5 - rom_height / 2;

// reset and nmi,
// height from stand to center = 5.5
// reset x = pcb_width / 2 - 10.1
// nmi x = pcb_width / 2 - 20.3
button_r = 3.4 / 2;
button_y = pcb_height / 2;
nmi_x = -pcb_width / 2 + 20.3;
reset_x = -pcb_width / 2 + 10.1;
button_z = -enclosure_height / 2 + wall_thickness + stand_height + 5.5;

// microSD
// height from stand to center = 2.8
// x = pcb_width / 2 - 5
microsd_height = 2.8;
microsd_width = 13.85;
microsd_x = pcb_width / 2 - 5 - microsd_width / 2;
microsd_y = pcb_height / 2;
microsd_z = -enclosure_height / 2 + wall_thickness + stand_height + 2.8;

module rounded_rect(x, y, z, r)
{
    linear_extrude(z, center = true) minkowski() {
        square([x, y], center = true);
        circle(r = r);
    }
}

module stand(outer_r, inner_r, h) {
    difference() {
        cylinder(h = h, r = outer_r, center = true);
        cylinder(h = h + 0.002, r = inner_r, center = true); 
    }
    difference() {
        rotate_extrude() translate([outer_r + h / 2 - 0.001, 0]) square([h, h], center = true);
        rotate_extrude() translate([outer_r + h, h / 2]) circle(r = h);
    }
}

difference() {

    union() {
        difference() {
            // base
            rounded_rect(pcb_width + pcb_wall_gap * 2, pcb_height + pcb_wall_gap * 2, enclosure_height, wall_thickness);
            // cut out
            translate([0, 0, wall_thickness])
                minkowski() {
                    cube([pcb_width + pcb_wall_gap * 2 - wall_thickness, pcb_height + pcb_wall_gap * 2 - wall_thickness, enclosure_height - wall_thickness], center = true);
                    sphere(r = wall_thickness / 2);
                }
            // holes
            for (idx = [ 0 : len(holes) - 1 ]) {
                translate(holes[idx]) {
                    cylinder(h = enclosure_height * 2, r = stand_inner_r, center = true);
                    // chamfer
                    translate([0, 0, (-enclosure_height / 2 - 0.001 + hole_chamfer_r / 2)]) cylinder(h = hole_chamfer_r, r1 = hole_chamfer_r, r2 = 0, center = true);
                }
            }
        }

        // PCB stands
        for (idx = [ 0 : len(holes) - 1 ])
            translate(holes[idx])
                translate([0, 0, -enclosure_height / 2 + stand_height / 2 + wall_thickness + 0.001])
                    stand(stand_outer_r, stand_inner_r, stand_height);
        
        // PCB locks
        translate([pcb_width / 2 + pcb_wall_gap, 0, -enclosure_height / 2 + wall_thickness + stand_height + 1.8 + 0.5]) rotate([90, 0, 0]) cylinder(h = 10, r = 1, center = true);
        translate([-pcb_width / 2 - pcb_wall_gap, 0, -enclosure_height / 2 + wall_thickness + stand_height + 1.8 + 0.5]) rotate([90, 0, 0]) cylinder(h = 10, r = 1, center = true);
    }
    // connector hole
    translate([0, -pcb_height / 2 - wall_thickness - pcb_wall_gap + 3 + connector_hole_height / 2]) 
        cube([connector_hole_width, connector_hole_height, enclosure_height * 2], center = true);
    
    // ESP
    translate([esp_x, esp_y, -enclosure_height / 2 + wall_thickness + 0.001]) cube([esp_width, esp_height, 2], center = true);
    
    // RAM
    translate([ram_x, ram_y, -enclosure_height / 2 + wall_thickness + 0.001]) cube([ram_width, ram_height, 2], center = true);
    
    // ROM
    translate([rom_x, rom_y, -enclosure_height / 2 + wall_thickness + 0.001]) cube([rom_width, rom_height, 2], center = true);
    
    // NMI
    translate([nmi_x, button_y, button_z]) rotate([90, 0, 0]) cylinder(h = 10, r = button_r, center = true);
    translate([nmi_x, button_y, button_z]) rotate([90, 0, 0]) cylinder(h=4, r = button_r + 1.6, center = true);
        
    // Reset
    translate([reset_x, button_y, button_z]) rotate([90, 0, 0]) cylinder(h = 10, r = button_r, center = true);
    translate([reset_x, button_y, button_z]) rotate([90, 0, 0]) cylinder(h=4, r = button_r + 1.6, center = true);
    
    // MicroSD
    translate([microsd_x, microsd_y, microsd_z]) cube([microsd_width, 10, microsd_height], center = true);
    translate([microsd_x, microsd_y + 4, microsd_z]) cube([microsd_width + 2, 4, microsd_height + 2], center = true);
    
    // LED
    translate([pcb_width / 2 - 19.6, pcb_height / 2 - 4.2]) cylinder(h = enclosure_height * 2, r = 1, center = true);

}