module mycpu_top(
    input  wire       clk,
    input  wire       resetn,
    // inst sram interface
    output  wire      inst_sram_en,
    output wire[ 3:0] inst_sram_we,
    output wire[31:0] inst_sram_addr,
    output wire[31:0] inst_sram_wdata,
    input  wire[31:0] inst_sram_rdata,
    // data sram interface
    output wire       data_sram_en,
    output wire[ 3:0] data_sram_we,
    output wire[31:0] data_sram_addr,
    output wire[31:0] data_sram_wdata,
    input  wire[31:0] data_sram_rdata,
    // trace debug interface
    output wire[31:0] debug_wb_pc,
    output wire[ 3:0] debug_wb_rf_we,
    output wire[ 4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);

reg         reset;
always @(posedge clk) reset <= ~resetn;

wire         ID_allow;
wire         EX_allow;
wire         MEM_allow;
wire         WB_allow;
wire         IF_to_ID_valid;
wire         ID_to_EX_valid;
wire         EX_to_MEM_valid;
wire         MEM_to_WB_valid;
wire [63:0] IF_to_ID_bus;
wire [153:0] ID_to_EX_bus;
wire [70:0] EX_to_MEM_bus;
wire [69:0] MEM_to_WB_bus;
wire [37:0] WB_to_ID_bus;
wire [32:0] ID_to_IF_bus;
wire [37:0] MEM_to_ID_forward;
wire [37:0] WB_to_ID_forward;
wire [37:0] EX_to_ID_forward;
wire      EX_to_ID_load_up;
// IF stage
if_stage if_stage(
    .clk            (clk),
    .reset          (reset),
    .ID_allow       (ID_allow),
    .ID_to_IF_bus   (ID_to_IF_bus),
    .IF_to_ID_valid (IF_to_ID_valid),
    .IF_to_ID_bus   (IF_to_ID_bus),
    // inst sram interface
    .inst_sram_en   (inst_sram_en),
    .inst_sram_we   (inst_sram_we),
    .inst_sram_addr (inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata)
);
// ID stage
id_stage id_stage(
    .clk            (clk),
    .reset          (reset),
    .EX_allow       (EX_allow),
    .ID_allow       (ID_allow),
    .IF_to_ID_valid (IF_to_ID_valid),
    .IF_to_ID_bus   (IF_to_ID_bus),
    .ID_to_EX_valid (ID_to_EX_valid),
    .EX_to_ID_forward(EX_to_ID_forward),
    .MEM_to_ID_forward(MEM_to_ID_forward),
    .WB_to_ID_forward(WB_to_ID_forward),
    .ID_to_EX_bus   (ID_to_EX_bus),
    .ID_to_IF_bus   (ID_to_IF_bus),
    .WB_to_ID_bus   (WB_to_ID_bus),
    .EX_to_ID_load_up(EX_to_ID_load_up)
);
// EX stage
ex_stage ex_stage(
    .clk            (clk),
    .reset          (reset),
    .MEM_allow      (MEM_allow),
    .EX_allow       (EX_allow),
    .ID_to_EX_valid (ID_to_EX_valid),
    .ID_to_EX_bus   (ID_to_EX_bus),
    .EX_to_MEM_valid(EX_to_MEM_valid),
    .EX_to_MEM_bus  (EX_to_MEM_bus),
    .EX_to_ID_forward(EX_to_ID_forward),
    .EX_to_ID_load_up(EX_to_ID_load_up),
    // data sram interface
    .data_sram_en   (data_sram_en),
    .data_sram_we   (data_sram_we),
    .data_sram_addr (data_sram_addr),
    .data_sram_wdata(data_sram_wdata)
);
// MEM stage
mem_stage mem_stage(
    .clk             (clk),
    .reset           (reset),
    .WB_allow        (WB_allow),
    .MEM_allow       (MEM_allow),
    .EX_to_MEM_valid (EX_to_MEM_valid),
    .EX_to_MEM_bus   (EX_to_MEM_bus),
    .MEM_to_WB_valid (MEM_to_WB_valid),
    .MEM_to_WB_bus   (MEM_to_WB_bus),
    .MEM_to_ID_forward (MEM_to_ID_forward),
    //from data-sram
    .data_sram_rdata(data_sram_rdata)
);
// WB stage
wb_stage wb_stage(
    .clk                (clk),
    .reset              (reset),
    .WB_allow           (WB_allow),
    .MEM_to_WB_valid    (MEM_to_WB_valid),
    .MEM_to_WB_bus      (MEM_to_WB_bus),
    .WB_to_ID_bus       (WB_to_ID_bus),
    .WB_to_ID_forward   (WB_to_ID_forward),
    //trace debug interface
    .debug_wb_pc        (debug_wb_pc),
    .debug_wb_rf_we     (debug_wb_rf_we),
    .debug_wb_rf_wnum   (debug_wb_rf_wnum),
    .debug_wb_rf_wdata  (debug_wb_rf_wdata)

);

endmodule
