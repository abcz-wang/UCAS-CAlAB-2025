module ex_stage(
    input        wire                   clk           ,
    input         wire                  reset         ,
    input          wire                 MEM_allow    ,
    output        wire                  EX_allow    ,
    input         wire                  ID_to_EX_valid,
    input  wire [147:0] ID_to_EX_bus  ,
    output          wire                EX_to_MEM_valid,
    output wire [70:0] EX_to_MEM_bus  ,
	output  wire      EX_to_ID_load_up,  
    // data sram interface(write)
    output  wire       data_sram_en   ,
    output wire [ 3:0] data_sram_we   ,
    output wire [31:0] data_sram_addr ,
    output wire [31:0] data_sram_wdata,
    output wire [37:0] EX_to_ID_forward
);

reg         EX_valid      ;
wire        EX_ready_go   ;

reg  [147:0] ID_to_EX_bus_reg;

wire [11:0] EX_alu_op      ;
wire        EX_load_op;
wire        EX_res_from_mem;
wire        EX_gr_we;
wire        EX_mem_we;
wire [4: 0] EX_dest;
wire [31:0] EX_rkd_value;
wire [31:0] EX_pc;
wire [31:0] EX_alu_src1   ;
wire [31:0] EX_alu_src2   ;
wire [31:0] alu_result ;
wire [4:0] EX_to_ID_dest;
assign {EX_alu_op,
        EX_alu_src1,
        EX_alu_src2,
        EX_gr_we,
        EX_mem_we,
        EX_dest,
        EX_rkd_value,
        EX_pc,
        EX_res_from_mem
} = ID_to_EX_bus_reg;


assign EX_to_MEM_bus = {EX_res_from_mem,  
                       EX_gr_we       ,  
                       EX_dest        ,  
                       alu_result  ,  
                       EX_pc          
                      };
assign EX_to_ID_forward = {EX_gr_we,
                         EX_to_ID_dest,
                         alu_result
                        };
assign EX_ready_go    = 1'b1;
assign EX_allow     = !EX_valid || EX_ready_go && MEM_allow;
assign EX_to_MEM_valid =  EX_valid && EX_ready_go;
always @(posedge clk) begin
    if (reset) begin
        EX_valid <= 1'b0;
    end
    else if (EX_allow) begin
        EX_valid <= ID_to_EX_valid;
    end

    if (ID_to_EX_valid && EX_allow) begin
        ID_to_EX_bus_reg <= ID_to_EX_bus;
    end
end
assign  EX_to_ID_load_up = EX_valid & EX_res_from_mem;
alu u_alu(
    .alu_op     (EX_alu_op    ),
    .alu_src1   (EX_alu_src1  ),
    .alu_src2   (EX_alu_src2  ),
    .alu_result (alu_result)
    );
assign EX_to_ID_dest = EX_dest & {5{EX_valid}};
assign data_sram_en    = (EX_mem_we | EX_res_from_mem) & EX_valid;
assign data_sram_we    = {4{EX_mem_we && EX_valid}};
assign data_sram_addr  = alu_result;
assign data_sram_wdata = EX_rkd_value;

endmodule
