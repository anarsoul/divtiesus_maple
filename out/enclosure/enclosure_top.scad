$fn = 100;

pcb_width = 76.4;
pcb_height = 56.9;
pcb_wall_gap = 1;
wall_thickness = 2;
enclosure_height = 17;
stand_inner_r = 1;
stand_outer_r = 2;
stand_height = 2;
hole_chamfer_r = 2;
connector_hole_height = 9.25;
connector_hole_width = 75;
pcb_thickness = 1.6;
tolerance = 0.2;

top_stand_height = enclosure_height - wall_thickness * 2 - stand_height - 1.6 - tolerance;

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

jtag_width = 20.7;
jtag_height = 9.45;
jtag_x = pcb_width / 2 - 3.9 - jtag_width / 2;
jtag_y = pcb_height / 2 - 12 - jtag_height / 2;

switch_width = 5.95;
switch_height = 4.45;
switch_x = -pcb_width / 2 + 21 + switch_width / 2;
switch_y = -pcb_height / 2 + 12.55 + switch_height / 2;

module rounded_rect(x, y, z, r)
{
    linear_extrude(z, center = true) minkowski() {
        square([x, y], center = true);
        circle(r = r);
    }
}

module stand(outer_r, inner_r, h, fillet_h) {
    difference() {
        cylinder(h = h, r = outer_r, center = true);
        cylinder(h = h + 0.002, r = inner_r, center = true); 
    }
    translate([0, 0, -h / 2 + fillet_h / 2]) difference() {
        rotate_extrude() translate([outer_r + fillet_h / 2 - 0.001, 0]) square([fillet_h, fillet_h], center = true);
        rotate_extrude() translate([outer_r + fillet_h, fillet_h / 2]) circle(r = fillet_h);
    }
}

difference() {
    union() {
        rounded_rect(pcb_width - wall_thickness * 2 + 1, pcb_height - wall_thickness * 2 + 1, wall_thickness, wall_thickness);

        for (idx = [ 0 : len(holes) - 1 ])
                    translate(holes[idx])
                        translate([0, 0, wall_thickness / 2 + top_stand_height / 2 - 0.001])
                            stand(stand_outer_r, stand_inner_r, top_stand_height, 1);
    }
    
    translate([jtag_x, jtag_y]) cube([jtag_width, jtag_height, 10], center = true);
    translate([switch_x, switch_y]) cube([switch_width + 1.2, switch_height + 1.2, 10], center = true);
    
    joystick_r = 1.75;
    joystick_h = 8.65 + tolerance * 7;
    joystick_w1 = 17 + tolerance * 7;
    joystick_w2 = 15 + tolerance * 7;
    joystick_x = -(pcb_width / 2 - 27.2 + 1 - joystick_w1 / 2);
    joystick_y = pcb_height / 2 - 2.35 + 0.5 - joystick_h / 2;
    
    translate([joystick_x, joystick_y]) linear_extrude(10, center = true) hull() {
        translate([-joystick_w1 / 2 + joystick_r, joystick_h / 2 - joystick_r]) circle(r = joystick_r);
        translate([joystick_w1 /2 - joystick_r, joystick_h / 2 - joystick_r]) circle(r = joystick_r);
        translate([-joystick_w2 / 2 + joystick_r, -joystick_h / 2 + joystick_r]) circle(r = joystick_r);
        translate([joystick_w2 / 2 - joystick_r, -joystick_h / 2 + joystick_r]) circle(r = joystick_r);
    }
}