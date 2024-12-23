$fn = 100;
enclosure_hole_r = 3.4 / 2;
outer_button_r = enclosure_hole_r - 0.2;
inner_button_r = enclosure_hole_r + 1.2;
inner_h = 0.6;
hole_h = inner_h - 0.6;
outer_h = 2; // 3-4 for NMI, 2 for reset
wall_thickness = 2;

cylinder(h = inner_h, r = inner_button_r);
translate([0, 0, inner_h - 0.001]) cylinder(h = outer_h + wall_thickness, r = outer_button_r);