 /*                                                                      
 Designer   : Renyangang               
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.    

 Description: system bus module
 系统总线，负责CPU与外设、片外内存等之间的通信
 */

 `include "config.v"

module sys_bus(
    input         clk,
    input         rst_n,

    input         inst_read_en,       
    input  [`MAX_BIT_POS:0] inst_read_addr,
    output wire [`MAX_BIT_POS:0] inst_rdata,
    output wire    inst_read_ready,

    input         read_en,       
    input  [`MAX_BIT_POS:0] mem_addr,
    output wire [`MAX_BIT_POS:0] rdata,
    input         write_en,
    input  [`MAX_BIT_POS:0] wdata,     
    input  [1:0]  byte_size,
    output reg    mem_busy,
    output wire    mem_ready,

    input [`MAX_BIT_POS:0] exp_pc,
    input [`MAX_BIT_POS:0] exp_pc_next,
    input [`MAX_BIT_POS:0] exception_code,
    input exception_en,
    input int_jmp_ready,
    input mret_en,

    output wire int_en,
    output wire jmp_en,
    output wire [`MAX_BIT_POS:0] jmp_pc,

    input wire clk_timer,


    input wire [11:0] csr_read_addr,
    input wire [11:0] csrw_addr,
    input wire [`MAX_BIT_POS:0] w_data,
    input wire csr_write_en,
    output wire [`MAX_BIT_POS:0] csr_out,


    /* verilator lint_off UNOPTFLAT */
    output reg [`MAX_BIT_POS:0] io_addr,
    output reg io_read,
    output reg io_write,
    output reg burst,
    output reg [2:0] burst_size,
    output reg read_ready,
    output reg [`MAX_BIT_POS:0] io_wdata,
    output reg [1:0] io_byte_size,
    input wire  [`MAX_BIT_POS:0] io_rdata,
    input wire  io_ready,
    input wire [`INT_CODE_WIDTH-1:0]peripheral_int_code
);

    reg bus_busy;

    // 指令cache读取部分
    reg  inst_read_en_icache;      
    reg  [`MAX_BIT_POS:0] inst_read_addr_icache;
    wire [`MAX_BIT_POS:0] inst_rdata_icache;
    wire inst_read_ready_icache;
    reg  inst_addr_exception;

    assign inst_read_ready = (!inst_addr_exception) ? inst_read_ready_icache : 1'b0;
    assign inst_rdata = inst_rdata_icache;

    always @(posedge inst_read_en or inst_read_addr) begin
        if (!rst_n) begin
            inst_read_en_icache = 1'b0;
            inst_read_addr_icache = 0;
            inst_addr_exception = 1'b0;
        end
        else begin
            // 低两位不为0，指令地址非对齐异常
            inst_addr_exception = |(inst_read_addr[1:0]);
            if (!inst_addr_exception) begin
                inst_read_en_icache = inst_read_en;
                inst_read_addr_icache = inst_read_addr;
            end
        end
    end

    // 数据cache读取部分
    reg         d_read_en_dcache;       
    reg  [`MAX_BIT_POS:0] d_mem_addr_dcache;
    wire [`MAX_BIT_POS:0] d_rdata_dcache;
    wire        d_mem_ready_dcache;
    reg         d_write_en_dcache;
    reg  [`MAX_BIT_POS:0] d_wdata_dcache;   
    wire [1:0]   d_byte_size_dcache;

    reg [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data;
    /* verilator lint_off UNOPTFLAT */
    reg offchip_mem_ready;
    wire  [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata;
    wire offchip_mem_write_en;
    wire offchip_mem_read_en;
    wire [`MAX_BIT_POS:0] offchip_mem_addr;
    /* verilator lint_off UNOPTFLAT */
    reg [$clog2(`CACHE_LINE_SIZE/(`XLEN/8))-1:0] offchip_mem_byte_counter;
    reg [$clog2(`CACHE_LINE_SIZE/(`XLEN/8))-1:0] offchip_mem_byte_size;
    reg offchip_counter_ready;

    reg [2:0] d_cur_from; // 数据来源
    reg [2:0] d_state;
    reg [2:0] d_state_next;
    reg [1:0] mem_state;
    reg [1:0] mem_state_next;
    reg d_time_op_status;
    reg [`MAX_BIT_POS:0] mtime_rdata;
    reg mtime_ready;
    reg peripheral_op;
    reg io_ready_copy; // io_ready的副本，防止地址切换时读取到上一次的io结果

    localparam CUR_IDLE = 3'b000, CUR_CACHE = 3'b001, CUR_PERIPHERALS = 3'b010, CUR_TIMER = 3'b011, CUR_INT = 3'b100;
    localparam S_IDLE = 0, S_WAIT_PERIO = 1, S_READ_CACHE_LOAD_DATA = 2, S_READY = 3, S_WAIT_CACHE = 4;
    localparam MEM_IDLE = 0, MEM_WAIT_IO = 1, MEM_READY = 2;

    assign mem_ready = (d_cur_from == CUR_CACHE) ? d_mem_ready_dcache : (d_cur_from == CUR_PERIPHERALS && (d_state == S_WAIT_PERIO || d_state == S_READY)) ? io_ready : (d_cur_from == CUR_TIMER) ? mtime_ready : (d_cur_from == CUR_INT) ? int_data_ready : 1'b0;
    assign rdata = (d_cur_from == CUR_CACHE) ? d_rdata_dcache : (d_cur_from == CUR_PERIPHERALS) ? io_rdata : (d_cur_from == CUR_TIMER) ? mtime_rdata : (d_cur_from == CUR_INT) ? int_code_rdata : 32'd0;
    assign d_byte_size_dcache = byte_size;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_state <= MEM_IDLE;
        end
        else begin
            mem_state <= mem_state_next;
        end
    end

    /* verilator lint_off LATCH */
    always @(*) begin
        if (!rst_n) begin
            mem_state_next = S_IDLE;
        end
        else begin
            mem_state_next = mem_state;
            if (d_cur_from != CUR_IDLE) begin
                if (mem_ready) begin
                    mem_state_next = MEM_READY;
                end
                else begin
                    mem_state_next = MEM_WAIT_IO;
                end
            end
            if(mem_state == MEM_READY) begin
                mem_state_next = S_IDLE;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peripheral_op <= 0;
            read_ready <= 1'b0;
            d_cur_from <= CUR_IDLE;
            mem_busy <= 1'b0;
            mtime_ready <= 1'b0;
            int_data_ready <= 1'b0;
            d_write_en_dcache <= 1'b0;
            d_read_en_dcache <= 1'b0;
        end
        else begin
            case(mem_state)
                MEM_IDLE: begin
                    mtime_ready <= 1'b0;
                    int_data_ready <= 1'b0;
                    if (read_en || write_en) begin
                        if (mem_addr >= `SDRAM_ADDR_BASE && mem_addr <= `SDRAM_ADDR_END) begin
                            // RAM从cache读取
                            d_read_en_dcache <= read_en;
                            d_mem_addr_dcache <= mem_addr;
                            d_cur_from <= CUR_CACHE;
                            d_write_en_dcache <= write_en;
                            d_wdata_dcache <= wdata;
                        end
                        else if (mem_addr >= `TIMER_ADDR_BASE && mem_addr <= `TIMER_ADDR_END) begin
                            // 时间相关寄存器读写
                            d_cur_from <= CUR_TIMER;
                            time_operation();
                        end
                        else if (mem_addr >= `INT_ADDR_BASE && mem_addr <= `INT_ADDR_END) begin
                            d_cur_from <= CUR_INT;
                            int_operation();
                        end
                        else begin
                            peripheral_op <= 1;
                            d_cur_from <= CUR_PERIPHERALS;
                        end
                    end
                end
                MEM_WAIT_IO: begin
                    if (d_cur_from == CUR_PERIPHERALS && (d_state == S_WAIT_PERIO || d_state == S_READY)) begin
                        peripheral_op <= 0;
                    end
                end
                MEM_READY: begin
                    d_cur_from <= CUR_IDLE;
                    d_write_en_dcache <= 1'b0;
                    d_read_en_dcache <= 1'b0;
                end
                default: begin
                    d_cur_from <= CUR_IDLE;
                    d_write_en_dcache <= 1'b0;
                    d_read_en_dcache <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_state <= S_IDLE;
        end
        else begin
            d_state <= d_state_next;
        end
    end

    /* verilator lint_off LATCH */
    always @(*) begin
        if (!rst_n) begin
            d_state_next = S_IDLE;
            offchip_mem_byte_size = 0;
            offchip_mem_byte_size = ~offchip_mem_byte_size;
        end
        else begin
            case (d_state)
                S_IDLE: begin
                    if (offchip_mem_write_en || offchip_mem_read_en) begin
                        d_state_next = S_READ_CACHE_LOAD_DATA;
                    end
                    else if (peripheral_op) begin
                        d_state_next = S_WAIT_PERIO;
                    end
                    else begin
                        d_state_next = S_IDLE;
                    end
                end
                S_WAIT_PERIO: begin
                    if (io_ready) begin
                        d_state_next = S_READY;
                    end
                    else begin
                        d_state_next = S_WAIT_PERIO;
                    end
                end
                S_READ_CACHE_LOAD_DATA: begin
                    d_state_next = offchip_counter_ready ? S_WAIT_CACHE : S_READ_CACHE_LOAD_DATA;
                end
                S_WAIT_CACHE: begin
                    if (!(offchip_mem_write_en | offchip_mem_read_en)) begin
                        d_state_next = S_IDLE;
                    end
                    else begin
                        d_state_next = S_WAIT_CACHE;
                    end
                end
                S_READY: begin
                    d_state_next = S_IDLE;
                end
                default: begin
                    d_state_next = S_IDLE;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            io_ready_copy <= 1'b0;
            offchip_mem_byte_counter <= 0;
            io_byte_size <= 2'd0;
            offchip_mem_data <= 0;
            offchip_counter_ready <= 1'b0;
        end
        else begin
            case (d_state)
                S_IDLE: begin
                    io_write <= 1'b0;
                    io_read <= 1'b0;
                    offchip_mem_ready <= 1'b0;
                    offchip_counter_ready <= 1'b0;
                    io_addr <= 0;
                end
                S_WAIT_PERIO: begin
                    io_addr <= mem_addr;
                    io_wdata <= wdata;
                    io_read <= read_en;
                    io_write <= write_en;
                    io_byte_size <= byte_size;
                end
                S_READ_CACHE_LOAD_DATA: begin
                    if (!(|io_addr)) begin
                        io_addr <= offchip_mem_addr;
                    end
                    io_byte_size <= 2'd0;
                    io_write <= offchip_mem_write_en;
                    io_read <= offchip_mem_read_en;
                    if (offchip_mem_write_en) begin
                        io_wdata <= offchip_mem_wdata[offchip_mem_byte_counter*32+:32];
                    end
                    io_ready_copy <= io_ready;
                    if (io_ready & !io_ready_copy) begin
                        if (offchip_mem_write_en) begin
                            io_wdata <= offchip_mem_wdata[offchip_mem_byte_counter*32+:32];
                        end
                        else begin
                            offchip_mem_data[offchip_mem_byte_counter*32+:32] <= io_rdata;
                        end
                        
                        if (offchip_mem_byte_counter == offchip_mem_byte_size) begin
                            offchip_mem_ready <= 1'b1;
                            offchip_mem_byte_counter <= 0;
                            offchip_counter_ready <= 1'b1;
                        end
                        else begin
                            io_addr <= io_addr + 4;
                            offchip_mem_byte_counter <= offchip_mem_byte_counter + 1;
                        end
                    end
                end
                S_WAIT_CACHE: begin
                    io_write <= 1'b0;
                    io_read <= 1'b0;
                    io_addr <= 0;
                    offchip_counter_ready <= 1'b0;
                end
                S_READY: begin
                    io_write <= 1'b0;
                    io_read <= 1'b0;
                    io_addr <= 0;
                end
                default: begin
                end
            endcase
            
        end
    end


    mem_controller d_cache(
        .clk(clk),
        .rst_n(rst_n),
        .inst_mem_addr(inst_read_addr_icache),
        .inst_read_en(inst_read_en_icache),
        .inst_mem_rdata(inst_rdata_icache),
        .inst_mem_ready(inst_read_ready_icache),

        .mem_addr(d_mem_addr_dcache),
        .read_en(d_read_en_dcache),
        .write_en(d_write_en_dcache),
        .byte_size(d_byte_size_dcache),
        .mem_wdata(d_wdata_dcache),
        .mem_rdata(d_rdata_dcache),
        .mem_ready(d_mem_ready_dcache),

        // 片外内存获取通道
        .offchip_mem_data(offchip_mem_data),
        .offchip_mem_ready(offchip_mem_ready),
        .offchip_mem_wdata(offchip_mem_wdata),
        .offchip_mem_write_en(offchip_mem_write_en),
        .offchip_mem_read_en(offchip_mem_read_en),
        .offchip_mem_addr(offchip_mem_addr)
    );

    reg [`INT_CODE_WIDTH-1:0]soft_int_code;
    // reg [`INT_CODE_WIDTH-1:0]peripheral_int_code;

    reg [`MAX_BIT_POS:0] mtimecmp_low;
    reg [`MAX_BIT_POS:0] mtimecmp_high;
    wire [`MAX_BIT_POS:0] mtime_low;
    wire [`MAX_BIT_POS:0] mtime_high;
    reg set_mtimecmp_low;
    reg set_mtimecmp_high;
    wire [3:0]time_addr_offset;
    wire [`INT_CODE_WIDTH-1:0] cur_int_code;

    assign time_addr_offset = mem_addr[3:0];


    task time_operation();
        case (time_addr_offset)
            4'd0: begin
                // 实时时钟低位，只支持读取
                if (read_en) begin
                    mtime_rdata <= mtime_low;
                    mtime_ready <= 1'b1;
                end
            end
            4'd4: begin
                if (read_en) begin
                    mtime_rdata <= mtime_high;
                    mtime_ready <= 1'b1;
                end
            end
            4'd8: begin
                // mtimecmp 低位，只支持写
                if (write_en) begin
                    mtimecmp_low <= wdata;
                    set_mtimecmp_low <= 1'b1;
                    mtime_ready <= 1'b1;
                end
            end
            4'd12: begin
                if (write_en) begin
                    mtimecmp_high <= wdata;
                    set_mtimecmp_high <= 1'b1;
                    mtime_ready <= 1'b1;
                end
            end
            default: begin
                mtime_ready <= 1'b0;
            end
        endcase
    endtask

    // 中断信息访存操作
    reg [`MAX_BIT_POS:0] int_code_rdata;
    reg int_data_ready;
    wire [3:0]int_addr_offset;
    assign int_addr_offset = mem_addr[3:0]; 
    task int_operation();
        case (int_addr_offset)
            4'd0: begin
                // 当前的中断编号，只支持读取
                if (read_en) begin
                    int_code_rdata <= {24'd0,cur_int_code};
                    int_data_ready <= 1'b1;
                end
            end
            default: begin
                int_data_ready <= 1'b0;
            end
        endcase
    endtask


    reg [`MAX_BIT_POS:0] exp_val;
    reg sys_exception_en;
    reg [`MAX_BIT_POS:0] sys_exception_code;

    always @(exception_en or inst_addr_exception) begin
        if (!rst_n) begin
            sys_exception_en = 1'b0;
            sys_exception_code = 0;
        end
        else begin
            if (exception_en) begin
                sys_exception_en = 1'b1;
                sys_exception_code = exception_code;
                exp_val = exp_pc;
            end
            else if (inst_addr_exception) begin
                sys_exception_en = 1'b1;
                sys_exception_code = `EXCEPT_NONALIGNED_INST_ADDR;
                exp_val = inst_read_addr;
            end
            else begin
                sys_exception_en = 1'b0;
                sys_exception_code = 0;
            end
        end
    end

    registers_csr registers_csr(
        .clk(clk),
        .rst_n(rst_n),
        .exp_pc(exp_pc),
        .exp_pc_next(exp_pc_next),
        .exp_val(exp_val),
        .exception_code(sys_exception_code),
        .exception_en(sys_exception_en),
        .int_jmp_ready(int_jmp_ready),
        .int_en(int_en),
        .peripheral_int_code(peripheral_int_code),
        .soft_int_code(soft_int_code),
        .cur_int_code(cur_int_code),
        .mret_en(mret_en),
        .jmp_en(jmp_en),
        .jmp_pc(jmp_pc),
        .clk_timer(clk_timer),
        .set_mtimecmp_low(set_mtimecmp_low),
        .set_mtimecmp_high(set_mtimecmp_high),
        .mtimecmp_low(mtimecmp_low),
        .mtimecmp_high(mtimecmp_high),
        .mtime_low(mtime_low),
        .mtime_high(mtime_high),
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(w_data),
        .write_en(csr_write_en),
        .csr_out(csr_out)
    );

endmodule