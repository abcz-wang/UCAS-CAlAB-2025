module id_stage(
    input     wire                     clk           ,
    input     wire                      reset         ,
    input      wire                     EX_allow    ,
    output     wire                     ID_allow    ,
    input       wire                    IF_to_ID_valid,
    input wire  [63:0] IF_to_ID_bus  ,
    output       wire                   ID_to_EX_valid,
    output wire [153:0] ID_to_EX_bus  ,
    output wire [32:0] ID_to_IF_bus        ,
    input  wire [37:0] WB_to_ID_bus,
    input   wire        EX_to_ID_load_up,
    input  wire [37:0] MEM_to_ID_forward,
    input  wire [37:0] EX_to_ID_forward,
    input  wire [37:0] WB_to_ID_forward
);

wire        br_taken;
wire [31:0] br_target;
wire [31:0] ID_pc;
wire [31:0] ID_inst;
reg         ID_valid   ;
wire        ID_ready_go;

wire [14:0] alu_op;
wire        load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        mem_we;
wire        src_reg_is_rd;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;
wire 	  inst_slti;    //task_10
wire 	  inst_sltui;   //task_10
wire 	  inst_andi;    //task_10
wire 	  inst_ori;     //task_10
wire 	  inst_xori;    //task_10
wire        inst_sll;    //task_10
wire        inst_srl;    //task_10
wire        inst_sra;    //task_10
wire        inst_pcaddu12i; //task_10
wire        inst_mul_w;    //task_10
wire        inst_mulh_w;   //task_10
wire        inst_mulh_wu;  //task_10
wire        inst_div_w;    //task_10
wire        inst_mod_w;    //task_10
wire        inst_div_wu;   //task_10
wire        inst_mod_wu;  //task_10

wire        need_ui5;
wire 		need_ui12;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

wire [31:0] mem_result;
wire [31:0] final_result;


wire no_rj;
wire no_rk;
wire no_rd;
wire rj_wait;
wire rk_wait;
wire rd_wait;
wire no_wait;
wire load_stall;

wire [4:0]   EX_to_ID_dest;
wire [4:0]   MEM_to_ID_dest;
wire [4:0]   WB_to_ID_dest;
wire [31:0] EX_to_ID_result;
wire [31:0] WB_to_ID_result;
wire [31:0] MEM_to_ID_result;
wire  EX_to_ID_we;
wire WB_to_ID_we;
wire MEM_to_ID_we;


assign op_31_26  = ID_inst[31:26];
assign op_25_22  = ID_inst[25:22];
assign op_21_20  = ID_inst[21:20];
assign op_19_15  = ID_inst[19:15];

assign rd   = ID_inst[ 4: 0];
assign rj   = ID_inst[ 9: 5];
assign rk   = ID_inst[14:10];

assign i12  = ID_inst[21:10];
assign i20  = ID_inst[24: 5];
assign i16  = ID_inst[25:10];
assign i26  = {ID_inst[ 9: 0], ID_inst[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ID_inst[25];
//task_10 Add the following instructions
assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];  // opcode[31:22] = 0000001000b
assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];  // opcode[31:22] = 0000001001b
assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hD];  // opcode[31:22] = 0000001101b
assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'hE];  // opcode[31:22] = 0000001110b
assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hF];  // opcode[31:22] = 0000001111b

assign inst_sll    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0E];  
assign inst_srl    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0F]; 
assign inst_sra    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];  

assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ID_inst[25]; 

assign inst_mul_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19]; 
assign inst_mulh_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1A]; 
assign inst_div_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00]; 
assign inst_mod_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01]; 
assign inst_div_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02]; 
assign inst_mod_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03]; 



assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl |inst_pcaddu12i; 
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltui;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll;
assign alu_op[ 9] = inst_srli_w | inst_srl;
assign alu_op[10] = inst_srai_w | inst_sra;
assign alu_op[11] = inst_lu12i_w ;
assign alu_op[12]  = inst_mul_w ;
assign alu_op[13]  = inst_mulh_w;
assign alu_op[14]  = inst_mulh_wu;

wire is_div_mod_s = inst_div_w | inst_mod_w ;
wire is_div_mod_u = inst_div_wu | inst_mod_wu;
wire div_or_mod = inst_div_w | inst_div_wu;//若为除法，置为1，否则为mod,置为0


assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;


assign need_ui12  =  inst_andi | inst_ori | inst_xori;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w
				| inst_slti | inst_sltui;
assign need_si16  =  inst_jirl | inst_beq | inst_bne;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;


assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
			 need_ui12 ? {20'b0, i12[11:0]} :
/*need_ui5 || need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                              {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_slti   | 
                       inst_sltui  | 
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_pcaddu12i;

assign res_from_mem  = inst_ld_w;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b;
assign mem_we        = inst_st_w;
assign dest          = dst_is_r1 ? 5'd1 : rd;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rj_wait ? ((rj == EX_to_ID_dest && EX_to_ID_we) ? EX_to_ID_result :
                             (rj == MEM_to_ID_dest && MEM_to_ID_we) ? MEM_to_ID_result :
                             (rj == WB_to_ID_dest && WB_to_ID_we) ? WB_to_ID_result :rf_rdata1)
                        : rf_rdata1;
assign rkd_value = rk_wait ? ((rk == EX_to_ID_dest && EX_to_ID_we) ? EX_to_ID_result :
                             (rk == MEM_to_ID_dest && MEM_to_ID_we) ? MEM_to_ID_result :
                             (rk == WB_to_ID_dest && WB_to_ID_we) ? WB_to_ID_result : rf_rdata2) :
                    rd_wait ? ((rd == EX_to_ID_dest && EX_to_ID_we) ? EX_to_ID_result :
                             (rd == MEM_to_ID_dest && MEM_to_ID_we) ? MEM_to_ID_result :
                             (rd == WB_to_ID_dest && WB_to_ID_we) ? WB_to_ID_result : rf_rdata2) :
                    rf_rdata2;
assign rj_eq_rd = (rj_value == rkd_value);

assign br_taken = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_jirl
                   || inst_bl
                   || inst_b
)  && ID_valid && ~load_stall;

assign br_target = (inst_beq || inst_bne || inst_bl || inst_b) ? (ID_pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);
assign alu_src1 = src1_is_pc  ? ID_pc : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

assign ID_to_IF_bus = {br_taken, br_target};

reg  [63:0] IF_to_ID_bus_reg;

assign {ID_inst,
        ID_pc  } = IF_to_ID_bus_reg;

assign {rf_we   ,  
        rf_waddr,  
        rf_wdata   
       } = WB_to_ID_bus;

assign ID_to_EX_bus = {alu_op       ,   
                       alu_src1     , 
                       alu_src2     , 
                       gr_we        ,   
                       mem_we       ,   
                       dest         ,  
                       rkd_value    ,   
                       ID_pc        ,   
                       res_from_mem ,
					   is_div_mod_s ,
					   is_div_mod_u ,
					   div_or_mod
                    };

assign {EX_to_ID_we,
        EX_to_ID_dest,
        EX_to_ID_result
       } = EX_to_ID_forward;

assign {MEM_to_ID_we,
        MEM_to_ID_dest,
        MEM_to_ID_result
       } = MEM_to_ID_forward;

assign {WB_to_ID_we,
        WB_to_ID_dest,
        WB_to_ID_result
       } = WB_to_ID_forward;

assign ID_ready_go    = ~load_stall;
assign ID_allow     = !ID_valid || ID_ready_go && EX_allow;
assign ID_to_EX_valid = ID_valid && ID_ready_go;


                

assign no_rj    = inst_b | inst_bl | inst_lu12i_w | inst_pcaddu12i;
assign no_rk    = inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl | 
                inst_b | inst_bl | inst_beq | inst_bne | inst_lu12i_w| 
				inst_slti | inst_sltui
                | inst_andi | inst_ori | inst_xori
                | inst_pcaddu12i;
assign no_rd    = ~inst_st_w & ~inst_beq & ~inst_bne;//不使用rd作为源操作数

assign rj_wait = ~no_rj && (rj != 5'b00000) && ((rj == EX_to_ID_dest) || (rj == MEM_to_ID_dest) || (rj == WB_to_ID_dest));
assign rk_wait = ~no_rk && (rk != 5'b00000) && ((rk == EX_to_ID_dest) || (rk == MEM_to_ID_dest) || (rk == WB_to_ID_dest));
assign rd_wait = ~no_rd && (rd != 5'b00000) && ((rd == EX_to_ID_dest) || (rd == MEM_to_ID_dest) || (rd == WB_to_ID_dest));


assign load_stall = EX_to_ID_load_up && (((rj == EX_to_ID_dest) && rj_wait) ||
	                                        ((rk == EX_to_ID_dest) && rk_wait) ||
	                                        ((rd == EX_to_ID_dest) && rd_wait));


always @(posedge clk) begin
    if (reset) begin
        ID_valid <= 1'b0;
    end
    else if (ID_allow) begin
        ID_valid <= IF_to_ID_valid;
    end
    if (IF_to_ID_valid && ID_allow) begin
        IF_to_ID_bus_reg <= IF_to_ID_bus;
    end
end


endmodule
