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

`define CUR_IDLE 2'b00
`define CUR_CACHE 2'b01
`define CUR_PERIPHERALS 2'b10
`define CUR_TIMER 2'b11
`define S_IDLE 2'b00
`define S_WAIT_PERIO 2'b01
`define S_READ_CACHE_LOAD_DATA 2'b10
`define S_PERIO_BUSY 2'b11
module sys_bus(
    input         clk,
    input         rst,

    input         inst_read_en,       
    input  [`MAX_BIT_POS:0] inst_read_addr,
    output wire [`MAX_BIT_POS:0] inst_rdata,
    output wire    inst_read_ready,

    input         read_en,       
    input  [`MAX_BIT_POS:0] mem_addr,
    output [`MAX_BIT_POS:0] rdata,
    input         write_en,
    input  [`MAX_BIT_POS:0] wdata,     
    input  [1:0]  byte_size,
    output wire    mem_busy,
    output wire    mem_ready,

    input [`MAX_BIT_POS:0] pc,
    input [`MAX_BIT_POS:0] pc_next,
    input [`MAX_BIT_POS:0] inst_cur,
    input [`MAX_BIT_POS:0] exception_code,
    input exception_en,
    input cur_branch_hazard,

    output wire jmp_en,
    output wire [`MAX_BIT_POS:0] jmp_pc,

    input wire clk_timer,

    input wire [11:0] csr_read_addr,
    input wire [11:0] csrw_addr,
    input wire [`MAX_BIT_POS:0] w_data,
    input wire csr_write_en,
    output wire [`MAX_BIT_POS:0] csr_out,

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

    wire offchip_mem_read_busy;
    wire offchip_mem_write_busy;

    // 指令cache读取部分
    reg  inst_read_en_icache;      
    reg  [`MAX_BIT_POS:0] inst_read_addr_icache;
    wire [`MAX_BIT_POS:0] inst_rdata_icache;
    wire inst_read_ready_icache;
    reg  inst_addr_exception;

    reg [1:0] inst_cur_from; // 指令来源，0表示来自指令cache，1表示来自flash

    assign inst_read_ready = (inst_cur_from == `CUR_CACHE && !inst_addr_exception) ? inst_read_ready_icache : 1'b0;
    assign inst_rdata = (inst_cur_from == `CUR_CACHE) ? inst_rdata_icache : 32'd0;

    always @(posedge inst_read_en or inst_read_addr) begin
        // 低两位不为0，指令地址非对齐异常
        inst_addr_exception = |(inst_read_addr[1:0]);
        if (!inst_addr_exception) begin
            inst_read_en_icache = inst_read_en;
            inst_read_addr_icache = inst_read_addr;
            inst_cur_from = `CUR_CACHE;
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
    reg offchip_mem_ready;
    wire  [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata;
    wire offchip_mem_write_en;
    wire offchip_mem_read_en;
    wire [`MAX_BIT_POS:0] offchip_mem_addr;
    reg [$clog2(`CACHE_LINE_SIZE/(`XLEN/8))-1:0] offchip_mem_byte_counter;

    reg [1:0] d_cur_from; // 指令来源，1表示来自cache，2表示来自外设
    reg [1:0] d_status;
    reg d_time_write_status;
    reg [`MAX_BIT_POS:0] mtime_rdata;
    reg mtime_ready;
    reg pending_mem_op;

    assign mem_ready = (d_cur_from == `CUR_CACHE) ? d_mem_ready_dcache : (d_cur_from == `CUR_PERIPHERALS) ? io_ready : (d_cur_from == `CUR_TIMER) ? mtime_ready : 1'b0;
    assign rdata = (d_cur_from == `CUR_CACHE) ? d_rdata_dcache : (d_cur_from == `CUR_PERIPHERALS) ? io_rdata : (d_cur_from == `CUR_TIMER) ? mtime_rdata : 32'd0;
    assign d_byte_size_dcache = byte_size;

    always @(offchip_mem_read_en or offchip_mem_write_en or offchip_mem_addr) begin
        offchip_mem_byte_counter = 0;
        offchip_mem_ready = 1'b0;
        if ((offchip_mem_write_en || offchip_mem_read_en) && d_status == `S_IDLE) begin
            io_read = offchip_mem_read_en;
            io_write = offchip_mem_write_en;
            io_addr = offchip_mem_addr;
            io_wdata = offchip_mem_wdata;
            io_byte_size = 2'd0;
            d_status = `S_READ_CACHE_LOAD_DATA;
        end
    end

    always @(posedge read_en or mem_addr or posedge write_en) begin
        if (rst) begin
            if (mem_addr >= `SDRAM_ADDR_BASE && mem_addr <= `SDRAM_ADDR_END) begin
                // RAM从cache读取
                d_read_en_dcache = read_en;
                d_mem_addr_dcache = mem_addr;
                d_cur_from = `CUR_CACHE;
                d_write_en_dcache = write_en;
                d_wdata_dcache = wdata;
                io_byte_size = 2'd0;
            end
            else if (mem_addr >= `TIMER_ADDR_BASE && mem_addr <= `TIMER_ADDR_END) begin
                // 时间相关寄存器读写
                d_cur_from = `CUR_TIMER;
                time_operation();
            end
            else if (!offchip_mem_read_busy && !offchip_mem_write_busy) begin
                d_cur_from = `CUR_PERIPHERALS;
                io_read = read_en;
                io_write = write_en;
                io_addr = mem_addr;
                io_wdata = wdata;
                io_byte_size = byte_size;
                d_status = `S_PERIO_BUSY;
            end
            else begin
                pending_mem_op = 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            inst_read_en_icache <= 1'd0;
            d_read_en_dcache <= 1'd0;
            d_write_en_dcache <= 1'd0;
            d_cur_from <= `CUR_IDLE;
            d_status <= `S_IDLE;
            d_time_write_status <= 1'd0;
            offchip_mem_data <= 0;
            pending_mem_op <= 1'b0;
        end
        else if ((offchip_mem_write_en || offchip_mem_read_en) && d_status == `S_IDLE && !offchip_mem_ready) begin
            io_read <= offchip_mem_read_en;
            io_write <= offchip_mem_write_en;
            io_addr <= offchip_mem_addr;
            io_wdata <= offchip_mem_wdata;
            io_byte_size <= 2'd0;
            d_status <= `S_READ_CACHE_LOAD_DATA;
            offchip_mem_byte_counter <= 0;
            offchip_mem_ready <= 1'b0;
        end
        else if (d_status == `S_READ_CACHE_LOAD_DATA) begin
            if (io_ready) begin
                offchip_mem_data[offchip_mem_byte_counter*32+:32] = io_rdata;
                if (offchip_mem_byte_counter == `CACHE_LINE_SIZE/(`XLEN/8)-1) begin
                    d_status <= `S_IDLE;
                    offchip_mem_ready <= 1'b1;
                    offchip_mem_byte_counter <= 0;
                end
                else begin
                    io_addr <= io_addr + 4;
                    offchip_mem_byte_counter <= offchip_mem_byte_counter + 1;
                end
            end
        end
        else if (pending_mem_op && d_status == `S_IDLE && !offchip_mem_read_busy && !offchip_mem_write_busy) begin
            io_read <= read_en;
            io_write <= write_en;
            io_addr <= mem_addr;
            io_wdata <= wdata;
            io_byte_size <= byte_size;
            d_cur_from = `CUR_PERIPHERALS;
            d_status <= `S_PERIO_BUSY;
            pending_mem_op <= 1'b0;
        end
        else if (d_cur_from == `CUR_PERIPHERALS && io_ready) begin
            d_cur_from <= `CUR_IDLE;
            d_status <= `S_IDLE;
            io_read <= 1'b0;
            io_write <= 1'b0;
        end
        else if (d_time_write_status) begin
            mtime_ready <= 1'b1;
            if (mtime_ready) begin
                d_time_write_status <= 1'b0;
                mtime_ready <= 1'b0;
                d_cur_from <= `CUR_IDLE;
            end
        end
    end


    mem_controller d_cache(
        .clk(clk),
        .rst(rst),
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
        .offchip_mem_addr(offchip_mem_addr),
        .offchip_mem_read_busy(offchip_mem_read_busy),
        .offchip_mem_write_busy(offchip_mem_write_busy)
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
                    mtime_rdata = mtime_low;
                    mtime_ready = 1'b1;
                end
            end
            4'd4: begin
                if (read_en) begin
                    mtime_rdata = mtime_high;
                    mtime_ready = 1'b1;
                end
            end
            4'd8: begin
                // mtimecmp 低位，只支持写
                if (write_en) begin
                    mtimecmp_low = wdata;
                    set_mtimecmp_low = 1'b1;
                    d_time_write_status = 1'b1;
                end
            end
            4'd12: begin
                if (write_en) begin
                    mtimecmp_high = wdata;
                    set_mtimecmp_high = 1'b1;
                    d_time_write_status = 1'b1;
                end
            end
            default: begin
                // do nothing
            end
        endcase
    endtask


    reg [`MAX_BIT_POS:0] exp_val;
    reg sys_exception_en;
    reg [`MAX_BIT_POS:0] sys_exception_code;

    always @(negedge rst) begin
        if (!rst) begin
            sys_exception_en <= 1'b0;
            sys_exception_code <= 0;
        end
    end

    always @(exception_en or inst_addr_exception) begin
        if (rst) begin
            if (exception_en) begin
                sys_exception_en <= 1'b1;
                sys_exception_code <= exception_code;
                exp_val <= pc;
            end
            else if (inst_addr_exception) begin
                sys_exception_en <= 1'b1;
                sys_exception_code <= `EXCEPT_NONALIGNED_INST_ADDR;
                exp_val <= inst_read_addr;
            end
            else begin
                sys_exception_en <= 1'b0;
                sys_exception_code <= 0;
            end
        end
    end

    registers_csr registers_csr(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .pc_next(pc_next),
        .exp_val(exp_val),
        .exception_code(sys_exception_code),
        .exception_en(sys_exception_en),
        .cur_branch_hazard(cur_branch_hazard),
        .peripheral_int_code(peripheral_int_code),
        .soft_int_code(soft_int_code),
        .cur_int_code(cur_int_code),
        .jmp_en(jmp_en),
        .jmp_pc(jmp_pc),
        .clk_timer(clk_timer),
        .mtimecmp_low(mtimecmp_low),
        .mtimecmp_high(mtimecmp_high),
        .mtime_low(mtime_low),
        .mtime_high(mtime_high),
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(w_data),
        .write_en(write_en),
        .csr_out(csr_out)
    );

endmodule