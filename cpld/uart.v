`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 19:56:26 2015-10-17 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module uart (
    // CPU interface
    input wire clk,  // 28 MHz
    input wire bit_clk,
    input wire bit_clk4x,
    input wire [7:0] txdata,
    input wire txbegin,
    output wire txbusy,
    output wire [7:0] rxdata,
    output wire rxrecv,
    input wire data_read,
    // RS232 interface
    input wire rx,
    output wire tx,
    output wire rts
    );

    uart_tx transmitter (
        .clk(clk),
        .bit_clk(bit_clk),
        .txdata(txdata),
        .txbegin(txbegin),
        .txbusy(txbusy),
        .tx(tx)
    );

    uart_rx receiver (
        .clk(clk),
        .bit_clk4x(bit_clk4x),
        .rxdata(rxdata),
        .rxrecv(rxrecv),
        .data_read(data_read),
        .rx(rx),
        .rts(rts)
    );
endmodule

module uart_tx (
    // CPU interface
    input wire clk,  // 24 MHz
    input wire bit_clk,
    input wire [7:0] txdata,
    input wire txbegin,
    output wire txbusy,
    // RS232 interface
    output reg tx
    );

    initial tx = 1'b1;

    parameter
        IDLE  = 2'd0,
        START = 2'd1,
        BIT   = 2'd2,
        STOP  = 2'd3;

    reg [7:0] txdata_reg;
    reg [1:0] state = IDLE;
    reg [2:0] bitcnt;
    reg prev_bit_clk =1'b0;
    reg txbusy_ff = 1'b0;
    assign txbusy = txbusy_ff;

    always @(negedge clk) begin
        if (txbegin == 1'b1 && txbusy_ff == 1'b0 && state == IDLE) begin
            txdata_reg <= txdata;
            txbusy_ff <= 1'b1;
            state <= START;
        end
        if (prev_bit_clk == 1'b1 && bit_clk == 1'b0 && txbegin == 1'b0 && txbusy_ff == 1'b1) begin
            case (state)
                START:
                    begin
                        tx <= 1'b0;
                        bitcnt <= 3'd7;
                        state <= BIT;
                    end
                BIT:
                    begin
                        tx <= txdata_reg[0];
                        txdata_reg <= {1'b0, txdata_reg[7:1]};
                        bitcnt <= bitcnt - 3'd1;
                        if (bitcnt == 3'd0) begin
                            state <= STOP;
                        end
                    end
                STOP:
                    begin
                        tx <= 1'b1;
                        txbusy_ff <= 1'b0;
                        state <= IDLE;
                    end
                default:
                    begin
                        state <= IDLE;
                        txbusy_ff <= 1'b0;
                    end
            endcase
        end
        prev_bit_clk <= bit_clk;
    end
endmodule

module uart_rx (
    // CPU interface
    input wire clk, // 24 MHz
    input wire bit_clk4x,
    output reg [7:0] rxdata,
    output reg rxrecv,
    input wire data_read,
    // RS232 interface
    input wire rx,
    output reg rts
    );

    initial rxrecv = 1'b0;
    initial rts = 1'b0;

    parameter
        IDLE  = 3'd0,
        START = 3'd1,
        BIT   = 3'd2,
        STOP  = 3'd3,
        WAIT  = 3'd4;

    // Sincronizacin de señales externas
    reg [1:0] rx_ff = 2'b00;
    reg [1:0] bit_clk4x_edge = 2'b00;
    always @(posedge clk) begin
        bit_clk4x_edge <= { bit_clk4x_edge[0], bit_clk4x };
        // Negedge
        if (bit_clk4x_edge == 2'b10) begin
            rx_ff <= {rx_ff[0], rx};
        end
    end

    wire rx_is_1    = (rx_ff == 2'b11);
    wire rx_is_0    = (rx_ff == 2'b00);
    wire rx_negedge = (rx_ff == 2'b10);
    wire clk4x_negedge = (bit_clk4x_edge == 2'b10);

    reg [1:0] clk_cnt;
    reg [2:0] state = IDLE;
    reg [2:0] bitcnt;

    reg [7:0] rxshiftreg;

    always @(posedge clk) begin
        case (state)
            IDLE:
                begin
                    rxrecv <= 1'b0;   // si estamos aqui, es porque no hay bytes pendientes de leer
                    if (clk4x_negedge) begin
                        rts <= 1'b0;      // permitimos la recepción
                        if (rx_negedge) begin
                            clk_cnt <= 2'd1; // We may have lost for up to 1 cycle waiting for negedge
                            state <= START;
                        end
                    end
                end
            START:
                begin
                    if (clk4x_negedge) begin
                        clk_cnt <= clk_cnt + 1'b1;
                        if (clk_cnt == 2'd2) begin   // sampleamos el bit a mitad de ciclo
                            if (!rx_is_0) begin  // si no era una señal de START de verdad
                                state <= IDLE;
                            end
                        end
                        else if (clk_cnt == 2'd0) begin
                            rxshiftreg <= 8'h00;    // aqui iremos guardando los bits recibidos
                            bitcnt <= 3'd7;
                            state <= BIT;
                        end
                    end
                end
            BIT:
                begin
                    if (clk4x_negedge) begin
                        clk_cnt <= clk_cnt + 1'b1;
                        if (clk_cnt == 2'd2) begin   // sampleamos el bit a mitad de ciclo
                            if (rx_is_1) begin
                                rxshiftreg <= {1'b1, rxshiftreg[7:1]};   // los bits entran por la izquierda, del LSb al MSb
                            end
                            else if (rx_is_0) begin
                                rxshiftreg <= {1'b0, rxshiftreg[7:1]};
                            end
                            else begin
                                state <= IDLE;
                            end
                        end
                        else if (clk_cnt == 2'd0) begin
                            bitcnt <= bitcnt - 3'd1;
                            if (bitcnt == 3'd0)
                                state <= STOP;
                        end
                    end
                end

//rts en stop: se come 1 de cada dos chars
//rts a mitad de stop o antes: en vez de ok recibo "-" pero hace eco bien
            STOP:
                begin
                    if (clk4x_negedge) begin
                        clk_cnt <= clk_cnt + 1'b1;
                        if (clk_cnt == 2'd2) begin   // sampleamos el bit a mitad de ciclo
                            if (!rx_is_1) begin  // si no era una señal de STOP de verdad
                                state <= IDLE;
                            end
                            else begin
                                rxrecv <= 1'b1;
                                rts <= 1'b1;
                                rxdata <= rxshiftreg;
                                state <= WAIT;
                            end
                        end
                    end
                end
            WAIT:
                begin
                    if (data_read == 1'b1) begin
                        state <= IDLE;
                    end
                end
            default: state <= IDLE;
        endcase
    end
endmodule
