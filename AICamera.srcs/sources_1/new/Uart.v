`timescale 1ns / 1ps

module UartIn(input clk,
                input rst,
                input data_in,
                output reg [15:0] res_cnt,
                output reg [383:0] image_res);
    parameter bps      = 4000000;
    parameter need_cnt = 100000000 / bps;
    reg [15:0] bps_cnt; // ÿһλ�еļ�����
    reg [3:0] cnt; // ÿһ�����ݵļ�����
    reg [1:0] first_two; // ��ȥ�˲�
    reg [7:0] data_out;
    reg begin_bps_cnt;

    always @ (posedge clk) begin
        if (rst)
            first_two <= 2'b11;
        else
            first_two <= {first_two[0], data_in}; // ���и�ֵ
    end

    always @ (posedge clk) begin
        if (rst)
            begin_bps_cnt <= 0;
        else if (first_two[1] & ~first_two[0])
            begin_bps_cnt <= 1;
        else if (cnt == 8 && bps_cnt == need_cnt - 1)
            begin_bps_cnt <= 0;
    end

    always @ (posedge clk) begin
        if (rst) begin
            bps_cnt <= 0;
            cnt     <= 0;
            res_cnt <= 0;
        end
        else if (begin_bps_cnt) begin
            if (bps_cnt == need_cnt - 1) begin
                bps_cnt <= 0;
                if (cnt == 8) begin
                    cnt                     <= 0;
                    image_res[7 + res_cnt-:8] <= data_out[7:0];
                    res_cnt                 <= res_cnt + 8;
                end
                else
                    cnt <= cnt + 1;
            end
            else
                bps_cnt <= bps_cnt + 1;
        end
    end

    always @ (posedge clk) begin
        if (rst)
            data_out <= 0;
        else if (begin_bps_cnt && bps_cnt == need_cnt / 2 - 1 && cnt > 0)
            data_out[cnt-1] <= data_in;
    end
endmodule

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

module UartOut (
        input clk, rst,
        input [11:0] data_rgb, // ��RAM�ж�ȡ��������Ϣ
        input [4:0] image_state,
        input [3:0] bluetooth_dealed, //������Ϣ
        output reg uart_tx,
        output [18:0] ram_addr,
        output reg img_start,
        output reg img_end
    );

    parameter BAUDRATE = 4000000;
    parameter FREQ     = 100_000_000;

    reg trans_clk;
    reg [3:0] cnt_bit;
    reg [31:0] cnt_clk;
    reg rdy = 1; // æ��ָʾ�źţ�0Ϊ�У�1Ϊæ

    wire [7:0] uart_txd_data;

    UartGetData getdata(.trans_clk(trans_clk), .rst(rst), .data_rgb(data_rgb), .image_state(image_state),.bluetooth_dealed(bluetooth_dealed),
                       .ram_addr(ram_addr), .uart_txd_data(uart_txd_data));

    localparam T = FREQ / BAUDRATE;

    // ��������ṹ��cnt_clk����ÿһλ��ռ��ʱ������cnt_bit����1����ʼλ��8������λ��һ��ֹͣλ����10λ
    wire end_cnt_clk;
    wire end_cnt_bit;
    assign end_cnt_clk = cnt_clk == T - 1;
    assign end_cnt_bit = end_cnt_clk && cnt_bit == 9;

    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt_clk <= 0;
        else if (end_cnt_clk)
            cnt_clk <= 0;
        else
            cnt_clk <= cnt_clk + 1'b1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            img_start <= 0;
            img_end   <= 0;
        end
        else if (cnt_bit == 8) begin
            if (image_state == 1)
                img_start <= 1;
            else if (image_state == 3)
                img_end <= 1;
            else if (image_state == 4) begin
                img_start <= 0;
                img_end   <= 0;
            end
        end

    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            cnt_bit <= 0;
        else if (end_cnt_clk) begin
            if (end_cnt_bit) begin
                cnt_bit   <= 0;
                trans_clk <= 0; // �տ�ʼʱ����
            end
            else begin
                if (cnt_bit == 8) begin
                    trans_clk <= 1; // 8λ����ʱ����
                end
                cnt_bit <= cnt_bit + 1'b1;
            end
        end
    end

    reg [7:0] begin_data_color = 8'b11111111;
    reg [7:0] begin_data_black = 8'b11101110;

    // �ȷ���һ����ʼλ0��Ȼ��8λ����λ�������1λֹͣλ0
    always @(posedge clk or posedge rst) begin
        if (rst)
            uart_tx <= 1;
        else if (!cnt_clk) begin
            if (!cnt_bit)
                uart_tx <= 0;
            else if (cnt_bit == 9)
                uart_tx <= 1;
            else if (image_state == 1 || image_state == 3) begin
                if (bluetooth_dealed[2])
                    uart_tx <= begin_data_black[cnt_bit - 1];
                else
                    uart_tx <= begin_data_color[cnt_bit - 1];
            end
            else
                uart_tx <= uart_txd_data[cnt_bit - 1];
        end
    end
endmodule

module UartTop(
        input clk, rst,
        input [3:0] bluetooth_dealed, // ������Ϣ
        input [11:0] data_rgb, // ��RAM�ж�ȡ��������Ϣ
        input uart_rx,
        input image_pause,
        output [18:0] ram_addr, // ��һ��Ҫ��ȡ��RAM��ַ
        output reg [4:0] image_state,
        output [383:0] image_res,
        output uart_tx
    );

    localparam BAUDRATE = 4000000;
    localparam FREQ     = 100_000_000;
    parameter col_siz   = 11'd640;
    parameter row_siz   = 11'd480;

    wire [7:0] data;
    wire img_start;
    wire img_end;
    wire [15:0] res_cnt;

    reg uart_out_rst = 1;
    reg uart_in_rst = 1;

    always@ (posedge clk or posedge rst) begin
        if (rst) begin
            uart_out_rst <= 1;
        end
        else if (!image_state || image_state == 4) begin
            uart_out_rst <= 1;
        end
        else if (image_state >= 1 && image_state <= 3) begin
            uart_out_rst <= 0;
        end
    end


    always@ (posedge clk or posedge rst) begin
        if (rst) begin
            image_state <= 0;
            uart_in_rst <= 1;
        end
        else if (image_state == 0 && bluetooth_dealed[0] && image_pause) begin
            image_state <= 1; // ������ʼλ
        end
        else if (image_state == 1 && img_start == 1) begin
            image_state <= 2; // ����ͼƬ
        end
        else if (image_state == 2 && ram_addr == col_siz * row_siz - 1) begin
            image_state <= 3; // �������λ
        end
        else if (image_state == 3 && img_end == 1) begin
            image_state <= 4; // ������
            uart_in_rst <= 0;
        end
        else if (image_state == 4 && res_cnt >= 384) begin
            image_state <= 0; // �������
            uart_in_rst <= 1;
        end
    end

    UartOut #(BAUDRATE, FREQ) uartOut(.clk(clk),.rst(uart_out_rst),.data_rgb(data_rgb),.image_state(image_state),.img_start(img_start),.img_end(img_end),.bluetooth_dealed(bluetooth_dealed),
                                        .ram_addr(ram_addr),.uart_tx(uart_tx));

    UartIn uartIn(.clk(clk), .rst(uart_in_rst), .data_in(uart_rx), .res_cnt(res_cnt), .image_res(image_res));

endmodule
