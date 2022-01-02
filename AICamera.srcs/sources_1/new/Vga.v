`timescale 1ns / 1ps

module VgaPos(input vga_clk,
                input rst,
                output reg[11:0] col_pos,
                output reg[11:0] row_pos);
    parameter col_all = 11'd800;
    parameter row_all = 11'd525;

    always @ (posedge vga_clk) begin
        if (col_pos == col_all - 1) begin
            col_pos <= 0;
            if (row_pos == row_all - 1)
                row_pos <= 0;
            else
                row_pos <= row_pos + 1;
        end
        else
            col_pos <= col_pos + 1;
    end
endmodule

module VgaShow(input clk_vga,                // VGAʱ�ӣ�Ƶ��25.175MHz
                input rst,
                input [11:0] data_rgb,        // ��RAM�ж�ȡ��������Ϣ
                input [3:0] bluetooth_dealed,
                input [4:0] image_state,
                input [18:0] uart_addr,
                input [383:0] image_res,
                output reg[18:0] ram_addr,    // ��һ��Ҫ��ȡ��RAM��ַ
                output col_vga,
                output row_vga,
                output reg[3:0] red_vga,
                output reg[3:0] blue_vga,
                output reg[3:0] green_vga);
    //�в���
    parameter col_sync  = 11'd96;
    parameter col_left  = 11'd144;
    parameter col_right = 11'd784;
    parameter col_all   = 11'd800;
    parameter col_siz   = 11'd640;
    //�в���
    parameter row_sync  = 11'd2;
    parameter row_left  = 11'd35;
    parameter row_right = 11'd515;
    parameter row_all   = 11'd525;
    parameter row_siz   = 11'd480;

    wire [11:0] col_pos; //������
    wire [11:0] row_pos; //������

    assign col_vga = (col_pos < col_sync) ? 0 : 1; // ��ͬ���ź�����ʱ��
    assign row_vga = (row_pos < row_sync) ? 0 : 1; // ��ͬ���ź�����ʱ��

    VgaPos vgaPos(clk_vga,rst,col_pos,row_pos);

    integer i;
    reg res_num = 0;

    always@ (*) begin
        red_vga   = 0;
        blue_vga  = 0;
        green_vga = 0;
        if (image_state == 2)
            ram_addr = uart_addr; // ��VGA��ȡ�ĵ�ַ��ֵ������ģ��
        else if ((col_pos >= col_left) && (col_pos <= col_right) && (row_pos >= row_left) && (row_pos <= row_right)) begin // ����Ч��Χ��
            ram_addr = (row_pos - row_left) * col_siz + (col_pos - col_left);
            res_num  = 0;
            for (i = 0; i < 8; i = i + 1) begin // �������е�ʶ����
                if ((col_pos - col_left) >= image_res[47 + i * 48-:12] - 2 && (col_pos - col_left) <= image_res[23 + i * 48-:12] + 2 && (row_pos - row_left) >= image_res[35 + i * 48-:12] - 2 && (row_pos - row_left) <= image_res[11 + i * 48-:12] + 2 &&
                        ((col_pos - col_left) <= image_res[47 + i * 48-:12] + 2 || (col_pos - col_left) >= image_res[23 + i * 48-:12] - 2 || (row_pos - row_left) <= image_res[35 + i * 48-:12] + 2 || (row_pos - row_left) >= image_res[11 + i * 48-:12] - 2)) begin
                    res_num   = 1;
                    red_vga   = 4'b1111;
                    green_vga = 4'b0000;
                    blue_vga  = 4'b0000;
                end
            end
            if (!res_num) begin
                if (bluetooth_dealed[1]) begin // �ڰ�ģʽ
                    red_vga   = (data_rgb[11:8] + data_rgb[7:4] + data_rgb[3:0]) / 3;
                    green_vga = (data_rgb[11:8] + data_rgb[7:4] + data_rgb[3:0]) / 3;
                    blue_vga  = (data_rgb[11:8] + data_rgb[7:4] + data_rgb[3:0]) / 3;
                end
                else begin
                    red_vga   = data_rgb[11:8];
                    green_vga = data_rgb[7:4];
                    blue_vga  = data_rgb[3:0];
                end
            end
        end
    end
endmodule


