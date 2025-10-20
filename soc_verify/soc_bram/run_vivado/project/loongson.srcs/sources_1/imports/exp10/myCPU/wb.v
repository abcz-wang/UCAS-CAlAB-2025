module wb_stage(
    input     wire                       clk           ,
    input     wire                       reset         ,
    output    wire                       WB_allow    ,
    input      wire                      MEM_to_WB_valid,
    input  wire [69:0]  MEM_to_WB_bus  ,
    output wire [37:0]  WB_to_ID_bus  ,
    output wire [31:0] debug_wb_pc     ,
    output wire [ 3:0] debug_wb_rf_we  ,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    output wire [37:0] WB_to_ID_forward
);

reg         WB_valid;
wire        WB_ready_go;

reg [69:0] MEM_to_WB_bus_reg;
wire        WB_gr_we;
wire [ 4:0] WB_dest;
wire [31:0] WB_final_result;
wire [31:0] WB_pc;
wire [ 4:0] WB_to_ID_dest;
assign {WB_gr_we       ,  
        WB_dest        ,  
        WB_final_result,  
        WB_pc             
} = MEM_to_WB_bus_reg;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign WB_to_ID_bus = {rf_we   ,  
                       rf_waddr, 
                       rf_wdata   
                      };
assign WB_to_ID_forward = {WB_gr_we,
                         WB_to_ID_dest,
                         WB_final_result
                        };
assign WB_ready_go = 1'b1;
assign WB_allow  = !WB_valid || WB_ready_go;
always @(posedge clk) begin
    if (reset) begin
        WB_valid <= 1'b0;
    end
    else if (WB_allow) begin
        WB_valid <= MEM_to_WB_valid;
    end

    if (MEM_to_WB_valid && WB_allow) begin
        MEM_to_WB_bus_reg <= MEM_to_WB_bus;
    end
end

assign rf_we    = WB_gr_we && WB_valid;
assign rf_waddr = WB_dest;
assign rf_wdata = WB_final_result;
assign WB_to_ID_dest = WB_dest & {5{WB_valid}};
// debug info generate
assign debug_wb_pc       = WB_pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = WB_dest;
assign debug_wb_rf_wdata = WB_final_result;
endmodule
