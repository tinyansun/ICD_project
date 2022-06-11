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
parameter 	IDLE = 'd0,
			INPUT = 'd1,
			CAL = 'd2,
			OUTPUT = 'd3;
			
parameter	match = 'd2,
			mismatch = -'d1,
			open = 2,
			extend = 1;
			
integer i,j;

//------------------------------------------------------------------
// reg & wire
//------------------------------------------------------------------

reg signed[2:0] S_map[1:64][1:48];
reg signed[3:0] I_map[0:64][0:48];
reg signed[3:0] D_map[0:64][0:48];
reg signed[4:0] H_map[0:64][0:48];

reg[1:0] R[1:64];
reg[1:0] Q[1:48];

reg[1:0] cs, ns; //current state, next state
reg[3:0] counter;

reg finish_r;
reg [WIDTH_SCORE - 1:0]   max_r;
reg [WIDTH_POS_REF - 1:0]   pos_ref_r;
reg [WIDTH_POS_QUERY - 1:0]   pos_query_r;

wire[5:0] x;
wire[5:0] y;

wire signed[2:0] S_map_value;
wire signed[3:0] I_map_value;
wire signed[3:0] D_map_value;
reg  signed[4:0] H_map_value;

assign x = counter%64 + 1; 
assign y = counter/64 + 1; 

assign S_map_value = R[x] == Q[y]? match : mismatch;
assign I_map_value = H_map[x][y-1] - open > I_map[x][y-1] - extend ? H_map[x][y-1] - open : I_map[x][y-1] - extend;
assign D_map_value = H_map[x-1][y] - open > D_map[x-1][y] - extend ? H_map[x-1][y] - open : D_map[x-1][y] - extend;

always@(*) begin
	if(	H_map[x-1][y-1] + S_map_value >= I_map_value && 
		H_map[x-1][y-1] + S_map_value >= D_map_value && 
		H_map[x-1][y-1] + S_map_value >= 0)begin
			H_map_value = H_map[x-1][y-1] + S_map_value;
	end
	else if(I_map_value >= H_map[x-1][y-1] + S_map_value&&
			I_map_value >= D_map_value &&
			I_map_value >= 0)begin
			H_map_value = I_map_value;
	end
	else if(D_map_value >= H_map[x-1][y-1] + S_map_value&&
			D_map_value >= I_map_value &&
			D_map_value >= 0)begin
			H_map_value = D_map_value;
	end
	else begin
		H_map_value = 0;
	end
end


//------------------------------------------------------------------
// sequential part
//------------------------------------------------------------------
    
//S, I, D, H
always@(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=0; i<=64; i=i+1) begin
			H_map[i][0] <= 0;
			I_map[i][0] <= -8;
			D_map[i][0] <= -8;
		end
		for(j=0; j<=48; j=j+1) begin
			H_map[0][j] <= 0;
			I_map[0][j] <= -8;
			D_map[0][j] <= -8;
		end
	end
	else begin
		if(ns == CAL) begin
			S_map[x][y] <= S_map_value;
			I_map[x][y] <= I_map_value;
			D_map[x][y] <= D_map_value;
			H_map[x][y] <= H_map_value;
		end
	end
end

//counter
always@(posedge clk or posedge reset) begin
	if(reset) begin
		counter <= 0;
	end
	else begin
		case(ns)
			INPUT:begin
				counter <= counter + 1;
				if(counter == 63)
					counter <= 0 ;
			end
			CAL:begin
				counter <= counter+1;
			end
			default: counter <= 0;
		endcase
	end
end

//Reference & Query
always@(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=1; i<=64; i=i+1) begin
			R[i] <= 0;
		end
		for(j=1; j<=48; j=j+1) begin
			Q[j] <= 0;
		end
	end
	else begin
		if(ns == INPUT)begin
			for(i=1; i<64; i=i+1) begin
				R[i] <= R[i+1];
			end
			R[64] <= data_ref;
			if(counter<48) begin
				for(j=1; j<48; j=j+1) begin
					Q[j] <= Q[j+1];
				end
				Q[48] <= data_query;
			end
		end
	end
end

//output
always@(posedge clk or posedge reset) begin
	if(reset) begin
		max_r <= 0;
		finish_r <=0 ;
		pos_ref_r <=0 ;
		pos_query_r <=0 ;
	end
	else begin
		case(ns)
			CAL:begin
				if(H_map_value > max_r) begin
					max_r <= H_map_value;
					pos_ref_r <= x;
					pos_query_r <= y;
				end
			end
			OUTPUT:begin
				finish_r<=1;
				if(H_map_value > max_r) begin
					max_r <= H_map_value;
					pos_ref_r <= 64;
					pos_query_r <= 48;
				end
			end
			default:begin
				max_r <= 0;
				finish_r <= 0;
				pos_ref_r <= 0;
				pos_query_r <= 0;
			end
		endcase
	end
end

assign finish = finish_r;
assign max = max_r;
assign pos_ref = pos_ref_r;
assign pos_query = pos_query_r;

//FSM
always@(posedge clk or posedge reset) begin
	if(reset) begin
		cs <= IDLE;
	end
	else begin
		cs <= ns;
	end
end

always @(*) begin
    ns = cs;//else
	case(cs)
		IDLE:begin
			if(valid)
				ns = INPUT;
		end
		INPUT:begin
			if(!valid)
				ns = CAL;
		end
		CAL:begin
			if(counter == 3071)
				ns = OUTPUT;
		end
		OUTPUT:begin
			ns = IDLE;
		end
	endcase
end
    
endmodule
