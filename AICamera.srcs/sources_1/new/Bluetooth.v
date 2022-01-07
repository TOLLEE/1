`timescale 1ns / 1ps

// �������գ���0λ��ʾ�Ƿ���봫��״̬����ʾ��1λ��ʾ��ʾ��ɫ/�ڰף���2λ��ʾ������ɫ/�ڰף���3λ��ʾ�����Ƿ��Զ�
module Bluetooth(input clk_bluetooth,
                    input rst,
                    input data_bluetooth,
                    output reg[3:0] bluetooth_dealed);
    parameter bps      = 9600;
    parameter need_cnt = 100000000 / bps;
    reg [15:0] bps_cnt;     // ÿһλ�еļ�����
    reg [7:0] bluetooth_out; // ��������ź�
    reg [3:0] cnt;          // ÿһ�����ݵļ�����
    reg [1:0] first_two;    // ��ȥ�˲�
    reg begin_bps_cnt;      // �ӷ�ʹ���ź�

    always @ (posedge clk_bluetooth) begin
        if (rst)
            first_two <= 2'b11;
        else
            first_two <= {first_two[0], data_bluetooth}; // ���и�ֵ
    end

    always @ (posedge clk_bluetooth) begin
        if (rst)
            begin_bps_cnt <= 0;
        else if (first_two[1] & ~first_two[0])
            begin_bps_cnt <= 1;
        else if (cnt == 8 && bps_cnt == need_cnt - 1)
            begin_bps_cnt <= 0;
    end

    always @ (posedge clk_bluetooth) begin
        if (rst) begin
            bps_cnt <= 0;
            cnt     <= 0;
        end
        else if (begin_bps_cnt) begin
            if (bps_cnt == need_cnt - 1) begin
                bps_cnt <= 0;
                if (cnt == 8)
                    cnt <= 0;
                else
                    cnt <= cnt + 1;
            end
            else
                bps_cnt <= bps_cnt + 1;
        end
    end

    always @ (posedge clk_bluetooth) begin
        if (rst)
            bluetooth_out <= 0;
        else if (begin_bps_cnt && bps_cnt == need_cnt / 2 - 1 && cnt > 0)
            bluetooth_out[cnt - 1] <= data_bluetooth;
    end

    always @ (posedge clk_bluetooth) begin
        if (cnt == 8) begin
            bluetooth_dealed[3:0] <= bluetooth_out[3:0];
        end
    end
endmodule

