`timescale 1ns / 1ps

module UartGetData(
        input trans_clk, // �����ʱ�ӣ�Ƶ���ɴ��䴮�ڿ���
        input rst,
        input [11:0] data_rgb, // ��RAM�ж�ȡ��������Ϣ
        input [4:0] image_state,
        input [3:0] bluetooth_dealed, //������Ϣ
        output reg[18:0] ram_addr, // ��һ��Ҫ��ȡ��RAM��ַ
        output reg[7:0] uart_txd_data
    );

    parameter col_siz = 11'd640;
    parameter row_siz = 11'd480;

    reg [11:0] col_pos; // ������
    reg [11:0] row_pos; // ������

    always@ (*) begin
        ram_addr = row_pos * col_siz + col_pos;
        if (bluetooth_dealed[0])
            uart_txd_data = (data_rgb[11:8] / 2 * 32 + data_rgb[7:4] / 2 * 4 + data_rgb[3:0] / 4);
        else
            uart_txd_data = (data_rgb[11:8] + data_rgb[7:4] + data_rgb[3:0]) * 16 / 3;
    end

    always @ (posedge trans_clk or posedge rst) begin
        if (rst) begin
            col_pos <= 0;
            row_pos <= 0;
        end
        else if (image_state && image_state != 2) begin // ����������ʱ�����ⶼ����Ҫ���ڴ�
            col_pos <= 0;
            row_pos <= 0;
        end
        else if (col_pos == col_siz - 1) begin
            col_pos <= 0;
            if (row_pos == row_siz - 1) begin
                row_pos <= 0;
            end
            else
                row_pos <= row_pos + 1;
        end
        else
            col_pos <= col_pos + 1;
    end
endmodule