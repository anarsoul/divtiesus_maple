`timescale 1ns / 1ps
`default_nettype none

module segajoy
(
    input wire clk115200, // shift clk
    input rst_n,
    input q,
    input wire [7:0] a,
    input wire iorq_n,
    input wire rd_n,
    output reg cp,
    output reg pl,
    output reg [7:0] dout,
    output reg oe,
    output reg sel
);

reg [9:0] cnt;
reg [6:0] d_shift;

reg joy_right;
reg joy_left;
reg joy_down;
reg joy_up;
reg joy_a;
reg joy_b;
reg joy_c;
reg joy_start;
reg after_reset = 0;
reg joy_a_as_up = 0;

always @(posedge clk115200 or negedge rst_n) begin
    if (!rst_n) begin
        joy_right <= 0;
        joy_left <= 0;
        joy_down <= 0;
        joy_up <= 0;
        joy_a <= 0;
        joy_b <= 0;
        joy_c <= 0;
        joy_start <= 0;
        d_shift <= 8'b0;
        cp <= 0;
        pl <= 0;
        cnt <= 0;
        sel <= 1;
        after_reset <= 1;
    end
    else begin
        if (cp == 0) begin
            // load when cp == 0 and cnt == 0
            pl <= (cnt[2:0] == 0) ? 1'b0 : 1'b1;
        end
        else begin
            pl <= 1'b1;
            if (cnt[9:4] == 6'b1) begin
                d_shift <= { d_shift[5:0], q };
                if (cnt[2:0] == 3'd7) begin
                    // Our shiftreg is connected as below:
                    // 7 - Right
                    // 6 - Left 
                    // 5 - Down
                    // 4 - B1
                    // 3 - +5
                    // 2 - Up
                    // 1 - +5
                    // 0 - B2
                    if (sel) begin
                        /*
                            * 0 - Q
                            * 1 - d_shift[0]
                            * 2 - d_shift[1]
                            * ....
                            * 7 - d_shift[6]
                            */
                        joy_c <= q;
                        joy_b <= d_shift[3];
                        joy_right <= d_shift[6];
                        joy_left <= d_shift[5];
                        joy_up <= d_shift[1];
                        joy_down <= d_shift[4];
                    end
                    else begin
                        // LEFT and RIGHT are pressed, it's SEGA gamepad
                        if (d_shift[5] && d_shift[6] == 1) begin
                            // Sega gamepad. Update buttons status
                            joy_a <= d_shift[3];
                            joy_start <= q;
                            if (after_reset) begin
                                joy_a_as_up <= q;
                                after_reset <= 0;
                            end
                        end
                        else begin
                            // This is not a Sega gamepad, assume there is
                            // only two buttons
                            joy_a = joy_b;
                            joy_b = joy_c;
                        end
                    end
                    sel <= cnt[3];
                end
            end
            cnt <= cnt + 1'b1;
        end
        cp <= !cp; 
    end
end

wire port_rd = iorq_n == 1'b0 && rd_n == 1'b0;
always @* begin
    if (!rst_n) begin
        dout <= 8'b0;
        oe <= 0;
    end
    else begin
            if (a == 8'h1F && port_rd) begin
                    // Kempston:
                    // 5 - F2
                    // 4 - F1
                    // 3 - Up
                    // 2 - Down
                    // 1 - Left
                    // 0 - Right
                    oe <= 1;
                    if (joy_a_as_up) begin
                        dout <= { 1'b0, 1'b0, joy_c, joy_b | joy_start, joy_a, joy_down, joy_left, joy_right };
                    end
                    else begin
                        dout <= { 1'b0, joy_c, joy_b, joy_a | joy_start, joy_up, joy_down, joy_left, joy_right };
                    end
                end
            else
                oe <= 0;
    end
end

endmodule
