`timescale 1ns / 1ps

module GetImage (input rst,
                    input pclk,
                    input href,                     // ����ͷ���������ź�
                    input vsync,                    // ����ͷ��ʼ/��������
                    input [7:0] data_camera,        // ����ͷ����
                    input [3:0] bluetooth_dealed,   // ��������
                    input [18:0] uart_addr,
                    input [4:0] image_state,
                    output reg [11:0] data_out,     // �õ���RGB����
                    output reg write_ready,         // д��Ч
                    output reg [18:0] now_addr = 0, // ���ݴ����ַ
                    output reg image_pause);

    reg [15:0] rgb_565   = 0;
    reg [18:0] next_addr = 0;
    reg [1:0] now_state  = 0; // ��ǰ״̬
    parameter state_0    = 0; // ��ʼ״̬
    parameter state_1    = 1; // 8λ��Ч
    parameter state_2    = 2; // 16λ��Ч

    reg get_ready; // �Ƿ����ڴ���
    reg [35:0] wait_time = 0;

    // ��ǰһ��ͼ���Ƿ������
    always@ (negedge pclk) begin
        if (!bluetooth_dealed[0])
            get_ready <= 1;
        else if (!bluetooth_dealed[3] || (!image_state && vsync && !next_addr)) begin
            get_ready <= 0;
            image_pause <= 1;
        end
        else if (image_state == 3) begin
            get_ready   <= 1;
            image_pause <= 0;
        end
    end

    // ������ͷͼ�����RAM
    always@ (posedge pclk) begin
        if (rst || !vsync) begin
            write_ready <= 0;
            now_addr    <= 0;
            next_addr   <= 0;
            now_state   <= 0;
        end
        else if (get_ready) begin
            now_addr <= next_addr;
            rgb_565  <= {rgb_565[7:0], data_camera};
            data_out <= {rgb_565[15:12], rgb_565[10:7], rgb_565[4:1]};
            case(now_state)
                state_0: begin
                    if (href)
                        now_state <= state_1;
                    else
                        now_state <= state_0;
                    write_ready <= 0;
                end
                state_1: begin
                    now_state   <= state_2;
                    write_ready <= 0;
                end
                state_2: begin
                    if (href)
                        now_state = state_1;
                    else
                        now_state = state_0;
                    write_ready <= 1;
                    next_addr   <= next_addr + 1;
                end
            endcase
        end
        else
            write_ready <= 0;
    end
endmodule
