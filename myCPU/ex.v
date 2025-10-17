module ex_stage(
    input        wire                   clk           ,
    input         wire                  reset         ,
    input          wire                 MEM_allow    ,
    output        wire                  EX_allow    ,
    input         wire                  ID_to_EX_valid,
    input  wire [153:0] ID_to_EX_bus  ,
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

reg  [153:0] ID_to_EX_bus_reg;

wire [14:0] EX_alu_op;
wire        EX_res_from_mem;
wire        EX_gr_we;
wire        EX_mem_we;
wire [4: 0] EX_dest;
wire [31:0] EX_rkd_value;
wire [31:0] EX_pc;
wire [31:0] EX_alu_src1   ;
wire [31:0] EX_alu_src2   ;
wire [31:0] alu_result ;
wire [31:0] ex_final_result ;
wire [31:0]div_result;
wire div_done;
wire is_div;
wire [4:0] EX_to_ID_dest;
wire EX_is_div_mod_s;
wire EX_is_div_mod_u;
wire EX_div_or_mod;
assign {EX_alu_op,
        EX_alu_src1,
        EX_alu_src2,
        EX_gr_we,
        EX_mem_we,
        EX_dest,
        EX_rkd_value,
        EX_pc,
        EX_res_from_mem,
		EX_is_div_mod_s,
		EX_is_div_mod_u,
		EX_div_or_mod
} = ID_to_EX_bus_reg;


assign EX_to_MEM_bus = {EX_res_from_mem,  
                       EX_gr_we       ,  
                       EX_dest        ,  
                       ex_final_result  ,  
                       EX_pc          
                      };
assign EX_to_ID_forward = {EX_gr_we,
                         EX_to_ID_dest,
                         ex_final_result
                        };

assign EX_ready_go    = (is_div & EX_valid) ? div_done : 1'b1;

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

divider my_divider(
	.clk(clk),
	.rst(reset),
	.src1(EX_alu_src1),
	.src2(EX_alu_src2),
	.is_div_mod_s(EX_is_div_mod_s),
	.is_div_mod_u(EX_is_div_mod_u),
	.div_or_mod(EX_div_or_mod),
	.div_result(div_result),
	.div_done(div_done)
);
assign is_div = (EX_is_div_mod_s | EX_is_div_mod_u) & EX_valid;
assign ex_final_result = is_div ? div_result : alu_result;
assign EX_to_ID_dest = EX_dest & {5{EX_valid}};
assign data_sram_en    = (EX_mem_we | EX_res_from_mem) & EX_valid;
assign data_sram_we    = {4{EX_mem_we && EX_valid}};
assign data_sram_addr  = ex_final_result;
assign data_sram_wdata = EX_rkd_value;

endmodule
