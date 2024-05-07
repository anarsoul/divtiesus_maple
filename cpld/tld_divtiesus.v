/*
 * This file is part of the DIVtiesus project
 * Copyright (c) 2021 Miguel Angel Rodriguez Jodar.
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

`timescale 1ns / 1ps
`default_nettype none

module tld_divtiesus (
  input wire clk25mhz,
  // Bus de expansion ZX Spectrum
  input wire rst_n,
  input wire [15:0] a,
  input wire mreq_n,
  input wire iorq_n,
  input wire rd_n,
  input wire wr_n,
  input wire m1_n,
  inout tri [7:0] d,
  input wire notplus3,
  output tri romcs,
  output tri romoe1,
  output tri romoe2,
  output tri nmi_n,
  // Interfaz de usuario
  input wire nmi_button_n,
  input wire jumper_e,  // 1 = closed
  // Interfaz SPI
  output wire sclk,
  output wire mosi,
  input wire miso,
  output wire sd_cs0,
  output wire sd_cs1,
  // Bus de control EEPROM y SRAM
  output wire eeprom_oe_n,
  output wire eeprom_we_n,
  output wire sram_oe_n,
  output wire sram_we_n,
  output wire [5:0] sram_hiaddr,
  input wire uart_rx,
  output wire uart_tx,
  output wire uart_rts,
  input wire shift_q,
  output wire shift_pl,
  output wire shift_cp,
  output wire joy_sel
  );

  wire divmmc_zxromcs, divmmc_eeprom_cs, divmmc_sram_cs, divmmc_sram_write_n;
  wire [5:0] divmmc_sram_hiaddr;
  //wire trese_sram_cs;
  //wire [5:0] trese_sram_hiaddr;
  wire nmi_to_cpu_n;
  wire allramplus3;
  
  wire zxuno_regrd, zxuno_regwr;
  wire [7:0] zxuno_addr;
  
  wire [1:0] banco_rom;
  wire inrom48k = (banco_rom[1] | notplus3) & banco_rom[0];
 
  wire oe_uart;
  wire oe_modo;
  wire oe_divmmc;
  wire oe_joy;
  wire [7:0] uart_dout;
  wire [7:0] divmmc_dout;
  wire [7:0] joy_dout;
//  wire [7:0] modo_dout;
  reg [7:0] dout;

  localparam CLK = 24000000;
  localparam BPS = 115200;
  // We are counting only positive edges, so multiply period needs to be
  // 2 times shorter
  localparam PERIOD_1_4 = CLK / (BPS * 8);
  reg [5:0] clk_cnt = 6'b0;
  reg [2:0] bit_clk = 3'b0;
  
  always @* begin
    dout = oe_divmmc ? divmmc_dout :
//           oe_modo   ? modo_dout :
           oe_uart   ? uart_dout :
           oe_joy    ? joy_dout :
                      8'bZZ;
  end
  assign d = dout;

  always @(posedge clk25mhz) begin
    clk_cnt = clk_cnt + 6'd1;
    if (clk_cnt == PERIOD_1_4) begin
      bit_clk = bit_clk + 3'd1;
      clk_cnt = 6'b0;
    end
  end
  
  // NMI es colector abierto
  assign nmi_n = (nmi_to_cpu_n == 1'b0)? 1'b0 : 1'bz;  

  // RESET y MASTER RESET
  wire mrst_n = rst_n | nmi_button_n;
  
  // Gestion ROMCS para todos los modelos  
  wire zxromcs;
  assign romcs = (zxromcs == 1'b1 && notplus3 == 1'b1)? 1'b1 : 1'bz;
  assign romoe1 = (zxromcs == 1'b1 && notplus3 == 1'b0)? 1'b1 : 1'bz;
  assign romoe2 = (zxromcs == 1'b1 && notplus3 == 1'b0)? 1'b1 : 1'bz;
 
  segajoy joy(
    // Scan frequency is 115200Hz, it takes 16 ticks to scan whole gamepad,
    // so poll frequency will be 7200 Hz or once in 0.14ms
    .clk115200(bit_clk[2]),
    .rst_n(rst_n),
    .q(shift_q),
    .a(a[7:0]),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .cp(shift_cp),
    .pl(shift_pl),
    .dout(joy_dout),
    .oe(oe_joy),
    .sel(joy_sel),
  );

  divmmc_mcleod el_divmmc (
    // Interface with CPU
    .clk(clk25mhz),
    .rst_n(rst_n),
    .enable_autopage(jumper_e),
    .a(a),
    .din(d),
    .dout(divmmc_dout),
    .oe(oe_divmmc),
    .mreq_n(mreq_n),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .m1_n(m1_n),
    .nmi_button_n(nmi_button_n),  // Button push connects to GND
    .nmi_to_cpu_n(nmi_to_cpu_n),  // Actual NMI signal to CPU
    .inrom48k(inrom48k),
    // Spectrum ROM shadowing
    .zxromcs(divmmc_zxromcs),      // 1 to disable ZX ROM. Use with emitter follower transistor
    // DivMMC onboard memory control
    .eeprom_cs(divmmc_eeprom_cs),
    .eeprom_we_n(eeprom_we_n),
    .sram_cs(divmmc_sram_cs),
    .sram_write_n(divmmc_sram_write_n),
    .sram_hiaddr(divmmc_sram_hiaddr),  // up to 512KB of SRAM can be addressed
    // SPI interface
    .sd_cs0_n(sd_cs0),
    .sd_cs1_n(sd_cs1),
    .sd_sclk(sclk),
    .sd_mosi(mosi),
    .sd_miso(miso)
    );

  tres_e el_3e (
    .clk(clk25mhz),
    .rst_n(rst_n),
    .a(a),
    .mreq_n(mreq_n),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .din(d),
    .allramplus3(allramplus3),
    .banco_rom(banco_rom),
    // DivMMC onboard memory control
    // .sram_cs(trese_sram_cs),
    // .sram_hiaddr(trese_sram_hiaddr)  // up to 512KB of SRAM can be addressed
  );

  modo modo_operacion (
    .clk(clk25mhz),
    .mrst_n(mrst_n),
  //  .zxuno_addr(zxuno_addr),
  //  .zxuno_regrd(zxuno_regrd),
  //  .zxuno_regwr(zxuno_regwr),
  //  .din(d),
  //  .dout(modo_dout),
  //  .oe(oe_modo),
    .allramplus3(allramplus3),
    
    .divmmc_zxromcs(divmmc_zxromcs),
    .divmmc_eeprom_cs(divmmc_eeprom_cs),
    .divmmc_sram_cs(divmmc_sram_cs),
    .divmmc_sram_write_n(divmmc_sram_write_n),
    .divmmc_sram_hiaddr(divmmc_sram_hiaddr),
    
    // .trese_sram_cs(trese_sram_cs),
    // .trese_sram_hiaddr(trese_sram_hiaddr),

    .zxromcs(zxromcs),
    .eeprom_oe_n(eeprom_oe_n),
    .sram_oe_n(sram_oe_n),
    .sram_write_n(sram_we_n),
    .sram_hiaddr(sram_hiaddr)  
  );
  
  zxunoregs el_zxuno_esta_por_aqui (
    .clk(clk25mhz),
    .rst_n(rst_n),    
    .a(a),
    .iorq_n(iorq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    //.m1_n(m1_n),
    .din(d),
    .addr(zxuno_addr),
    .read_from_reg(zxuno_regrd),
    .write_to_reg(zxuno_regwr)
  );

  zxunouart (
    .clk(clk25mhz),
    .bit_clk(bit_clk[2]),
    .bit_clk4x(bit_clk[0]),
    .zxuno_addr(zxuno_addr),
    .zxuno_regrd(zxuno_regrd),
    .zxuno_regwr(zxuno_regwr),
    .din(d),
    .dout(uart_dout),
    .oe (oe_uart),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .uart_rts(uart_rts),
  );

endmodule
