module SW #(parameter WIDTH_SCORE = 8, parameter WIDTH_POS_REF = 7, parameter WIDTH_POS_QUERY = 6)
(
    input           clk,
    input           reset,
    input           valid,
    input [1:0]     data_ref,
    input [1:0]     data_query,
    output          finish,
    output [WIDTH_SCORE - 1:0]   max,
    output [WIDTH_POS_REF - 1:0]   pos_ref,
    output [WIDTH_POS_QUERY - 1:0]   pos_query
);

//------------------------------------------------------------------
// parameter
//------------------------------------------------------------------

//------------------------------------------------------------------
// reg & wire
//------------------------------------------------------------------

//------------------------------------------------------------------
// submodule
//------------------------------------------------------------------

//------------------------------------------------------------------
// combinational part
//------------------------------------------------------------------

    always @(*) begin
        
    end

//------------------------------------------------------------------
// sequential part
//------------------------------------------------------------------
    always@(posedge clk or posedge reset) begin
    if(reset) begin
        
    end
    else begin
        
    end
    end
    
endmodule
