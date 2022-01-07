module RamTest_tb;
    reg clk, rst, wren;
    reg [11:0] wrdata;
    wire [11:0] rddata;
    reg [18:0] addr = 0;
    reg [12:0] time_cnt = 0;
    
    initial begin
        clk = 0;
        rst = 0;
        #2 rst = 1;
    end
    
    always begin
        #1 clk = !clk;

    end

    always @ (posedge clk or negedge rst)
        begin
            if(!rst)
                time_cnt <= 0;
            else if(time_cnt == 10'd10)
                time_cnt <= 1'd0;
            else 
                time_cnt <= time_cnt + 1;
        end


    // дʹ���ź�
    always @ (posedge clk or negedge rst)
        begin
            if(!rst)
                wren <= 0;
            else if (time_cnt >= 10'd6)
                wren <= 1'b1;
            else
                wren <= 0;
        end
    // ��ַ�ź�
    always @ (posedge clk or negedge rst)
        begin
            if(!rst)
                addr <= 0;
            else if (time_cnt >= 10'd6)
                addr <= time_cnt;
            else
                addr <= time_cnt - 10'd5;
        end

    // д�����ź�
    always @ (posedge clk or negedge rst)
        begin
            if(!rst)
                wrdata <= 0;
            else if (time_cnt >= 10'd6)
                wrdata <= time_cnt;
            else
                wrdata <= wrdata;
        end

    // ���� RAM ģ��
    blk_mem_gen_0 uut(
        .clka(clk),
        .ena(1'b1),
        .wea(wren),	   // дʹ���ź�
        .addra(addr),  // ��ַ�ź�
        .dina(wrdata), // д�����ź�
        .clkb(clk),
        .enb(1'b1),
        .addrb(addr),
        .doutb(rddata) // �������ź�
    );
endmodule