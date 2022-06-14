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

// test for github

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

reg signed[6:0] S_map[1:64][1:48];
reg signed[6:0] I_map[0:64][0:48];
reg signed[6:0] D_map[0:64][0:48];
reg signed[6:0] H_map[0:64][0:48];

reg[1:0] R[1:64];
reg[1:0] Q[1:48];

reg[1:0] cs, ns; //current state, next state
reg[11:0] counter;

reg finish_r;
reg [WIDTH_SCORE - 1:0]   max_r;
reg [WIDTH_POS_REF - 1:0]   pos_ref_r;
reg [WIDTH_POS_QUERY - 1:0]   pos_query_r;

wire[6:0] x;
wire[5:0] y;

//wire signed[2:0] S_map_value;
//wire signed[3:0] I_map_value;
//wire signed[3:0] D_map_value;
reg  signed[4:0] H_map_value;
wire signed[6:0] S_map_value;
wire signed[6:0] I_map_value;
wire signed[6:0] D_map_value;
reg  signed[6:0] H_map_value;

//assign x = counter%64 + 1; 
//assign y = counter/64 + 1; 


always@(*)begin
	if(ns == CAL)begin
		//cycle1 -> counter = 0, cycle2 -> counter = 1.....
		if(counter <= 15)begin
			for(i=1; i<counter+2; i=i+1)begin
				S_map[i][counter+2-i] = R[i] == Q[counter+2-i] ? match : mismatch;
				I_map[i][counter+2-i] = H_map[i][(counter+2-i)-1] - open > I_map[i][(counter+2-i)-1] - extend ? H_map[i][(counter+2-i)-1] - open : I_map[i][(counter+2-i)-1] - extend;
				D_map[i][counter+2-i] = H_map[i-1][(counter+2-i)] - open > D_map[i-1][(counter+2-i)] - extend ? H_map[i-1][(counter+2-i)] - open : D_map[i-1][(counter+2-i)] - extend;
				//H_map
				if(	H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= I_map[i][counter+2-i] && H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= D_map[i][counter+2-i] && H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i];
				end
				else if(I_map[i][counter+2-i] >= H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] && I_map[i][counter+2-i] >= D_map[i][counter+2-i] && I_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = I_map[i][counter+2-i];
				end
				else if(D_map[i][counter+2-i] >= H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] && D_map[i][counter+2-i] >= I_map[i][counter+2-i] && D_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = D_map[i][counter+2-i];
				end
				else begin
					H_map[i][counter+2-i] = 0;
				end
			end
		end
		else if(16 <= counter <= 63)begin
			for(i=1; i<=16; i=i+1)begin
				S_map[counter+2-i][i] = R[counter+2-i] == Q[i] ? match : mismatch;
				I_map[(counter+2-i)][i] = H_map[(counter+2-i)][i-1] - open > I_map[(counter+2-i)][i-1] - extend ? H_map[(counter+2-i)][i-1] - open : I_map[(counter+2-i)][i-1] - extend;
				D_map[(counter+2-i)][i] = H_map[(counter+2-i)-1][i] - open > D_map[(counter+2-i)-1][i] - extend ? H_map[(counter+2-i)-1][i] - open : D_map[(counter+2-i)-1][i] - extend;
				//H_map
				if(	H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i] >= I_map[(counter+2-i)][i] && H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i] >= D_map[(counter+2-i)][i] && H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i] >= 0)begin
					H_map[(counter+2-i)][i] = H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i];
				end
				else if(I_map[(counter+2-i)][i] >= H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i] && I_map[(counter+2-i)][i] >= D_map[(counter+2-i)][i] && I_map[(counter+2-i)][i] >= 0)begin
					H_map[(counter+2-i)][i] = I_map[(counter+2-i)][i];
				end
				else if(D_map[(counter+2-i)][i] >= H_map[(counter+2-i)-1][i-1] + S_map[(counter+2-i)][i] && D_map[(counter+2-i)][i] >= I_map[(counter+2-i)][i] && D_map[(counter+2-i)][i] >= 0)begin
					H_map[(counter+2-i)][i] = D_map[(counter+2-i)][i];
				end
				else begin
					H_map[(counter+2-i)][i] = 0;
				end
			end
		end
		else if(64 <= counter <= 79)begin
			for(i=1; i<counter-62; i=i+1)begin
				S_map[i][counter-46-i] = R[i] == Q[counter-46-i] ? match : mismatch;
				I_map[i][counter-46-i] = H_map[i][(counter-46-i)-1] - open > I_map[i][(counter-46-i)-1] - extend ? H_map[i][(counter-46-i)-1] - open : I_map[i][(counter-46-i)-1] - extend;
				D_map[i][counter-46-i] = H_map[i-1][(counter-46-i)] - open > D_map[i-1][(counter-46-i)] - extend ? H_map[i-1][(counter-46-i)] - open : D_map[i-1][(counter-46-i)] - extend;
			end
			for(i=64; i>counter-15; i=i-1)begin
				S_map[i][counter+2-i] = R[i] == Q[counter+2-i] ? match : mismatch;
				I_map[i][counter+2-i] = H_map[i][(counter+2-i)-1] - open > I_map[i][(counter+2-i)-1] - extend ? H_map[i][(counter+2-i)-1] - open : I_map[i][(counter+2-i)-1] - extend;
				D_map[i][counter+2-i] = H_map[i-1][(counter+2-i)] - open > D_map[i-1][(counter+2-i)] - extend ? H_map[i-1][(counter+2-i)] - open : D_map[i-1][(counter+2-i)] - extend;
			end
		end
		else if(80 <= counter <= 127)begin
			for(i=17; i<=32; i=i+1)begin
				S_map[counter-46-i][i] = R[counter-46-i] == Q[i] ? match : mismatch;
				I_map[counter-46-i][i] = H_map[counter-46-i][i-1] - open > I_map[counter-46-i][i-1] - extend ? H_map[counter-46-i][i-1] - open : I_map[counter-46-i][i-1] - extend;
				D_map[counter-46-i][i] = H_map[(counter-46-i)-1][i] - open > D_map[(counter-46-i)-1][i] - extend ? H_map[(counter-46-i)-1][i] - open : D_map[(counter-46-i)-1][i] - extend;
			end
		end
		else if(128 <= counter <= 143)begin
			for(i=1; i<counter-126; i=i+1)begin
				S_map[i][counter-94-i] = R[i] == Q[counter-94-i] ? match : mismatch;
				I_map[i][counter-94-i] = H_map[i][(counter-94-i)-1] - open > I_map[i][(counter-94-i)-1] - extend ? H_map[i][(counter-94-i)-1] - open : I_map[i][(counter-94-i)-1] - extend;
				D_map[i][counter-94-i] = H_map[i-1][(counter-94-i)] - open > D_map[i-1][(counter-94-i)] - extend ? H_map[i-1][(counter-94-i)] - open : D_map[i-1][(counter-94-i)] - extend;
			end
			
			for(i=64; i>counter-79; i=i-1)begin
				S_map[i][counter-46-i] = R[i] == Q[counter-46-i] ? match : mismatch;
				I_map[i][counter-46-i] = H_map[i][(counter-46-i)-1] - open > I_map[i][(counter-46-i)-1] - extend ? H_map[i][(counter-46-i)-1] - open : I_map[i][(counter-46-i)-1] - extend;
				D_map[i][counter-46-i] = H_map[i-1][(counter-46-i)] - open > D_map[i-1][(counter-46-i)] - extend ? H_map[i-1][(counter-46-i)] - open : D_map[i-1][(counter-46-i)] - extend;
			end
		end
		else if(144 <= counter <= 191)begin
			for(i=33; i<=48; i=i+1)begin
				S_map[counter-94-i][i] = R[counter-94-i] == Q[i] ? match : mismatch;
				I_map[counter-94-i][i] = H_map[counter-94-i][i-1] - open > I_map[counter-94-i][i-1] - extend ? H_map[counter-94-i][i-1] - open : I_map[counter-94-i][i-1] - extend;
				D_map[counter-94-i][i] = H_map[(counter-94-i)-1][i] - open > D_map[(counter-94-i)-1][i] - extend ? H_map[(counter-94-i)-1][i] - open : D_map[(counter-94-i)-1][i] - extend;
			end
		end
		else if(192 <= counter <= 206)begin
			for(i=64; i>counter-143; i=i+1)begin
				S_map[i][counter-94-i] = R[i] == Q[counter-94-i] ? match : mismatch;
				I_map[i][counter-94-i] = H_map[i][(counter-94-i)-1] - open > I_map[i][(counter-94-i)-1] - extend ? H_map[i][(counter-94-i)-1] - open : I_map[i][(counter-94-i)-1] - extend;
				D_map[i][counter-94-i] = H_map[i-1][(counter-94-i)] - open > D_map[i-1][(counter-94-i)] - extend ? H_map[i-1][(counter-94-i)] - open : D_map[i-1][(counter-94-i)] - extend;
			end
		end
	end
end

//compare
always@(*)begin
	if(ns == CAL)begin
		//cycle1 -> counter = 0, cycle2 -> counter = 1.....
		if(counter <= 15)begin
			for(i=1; i<counter+2; i=i+1)begin
				//H_map
				if(	H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= I_map[i][counter+2-i] && H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= D_map[i][counter+2-i] && H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i];
				end
				else if(I_map[i][counter+2-i] >= H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] && I_map[i][counter+2-i] >= D_map[i][counter+2-i] && I_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = I_map[i][counter+2-i];
				end
				else if(D_map[i][counter+2-i] >= H_map[i-1][(counter+2-i)-1] + S_map[i][counter+2-i] && D_map[i][counter+2-i] >= I_map[i][counter+2-i] && D_map[i][counter+2-i] >= 0)begin
					H_map[i][counter+2-i] = D_map[i][counter+2-i];
				end
				else begin
					H_map[i][counter+2-i] = 0;
				end
			end
		end
		else if(16 <= counter <= 63)begin
			//(17,1)
			if( H_map[(counter+2-1)][1]>H_map[counter+2-2][2]&&H_map[(counter+2-1)][1]>H_map[counter+2-3][3]&&H_map[(counter+2-1)][1]>H_map[counter+2-4][4]&&
				H_map[(counter+2-1)][1]>H_map[counter+2-5][5]&&H_map[(counter+2-1)][1]>H_map[counter+2-6][6]&&H_map[(counter+2-1)][1]>H_map[counter+2-7][7]&&
				H_map[(counter+2-1)][1]>H_map[counter+2-8][8]&&H_map[(counter+2-1)][1]>H_map[counter+2-9][9]&&H_map[(counter+2-1)][1]>H_map[counter+2-10][10]&&
				H_map[(counter+2-1)][1]>H_map[counter+2-11][11]&&H_map[(counter+2-1)][1]>H_map[counter+2-12][12]&&H_map[(counter+2-1)][1]>H_map[counter+2-13][13]&&
				H_map[(counter+2-1)][1]>H_map[counter+2-14][14]&&H_map[(counter+2-1)][1]>H_map[counter+2-15][15]&&H_map[(counter+2-1)][1]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-1)][1];
					x = (counter+2-1);
					y = 1;
			end
			//(16,2)
			else if(H_map[(counter+2-2)][2]>H_map[counter+2-1][1]&&H_map[(counter+2-2)][2]>H_map[counter+2-3][3]&&H_map[(counter+2-2)][2]>H_map[counter+2-4][4]&&
				H_map[(counter+2-2)][2]>H_map[counter+2-5][5]&&H_map[(counter+2-2)][2]>H_map[counter+2-6][6]&&H_map[(counter+2-2)][2]>H_map[counter+2-7][7]&&
				H_map[(counter+2-2)][2]>H_map[counter+2-8][8]&&H_map[(counter+2-2)][2]>H_map[counter+2-9][9]&&H_map[(counter+2-2)][2]>H_map[counter+2-10][10]&&
				H_map[(counter+2-2)][2]>H_map[counter+2-11][11]&&H_map[(counter+2-2)][2]>H_map[counter+2-12][12]&&H_map[(counter+2-2)][2]>H_map[counter+2-13][13]&&
				H_map[(counter+2-2)][2]>H_map[counter+2-14][14]&&H_map[(counter+2-2)][2]>H_map[counter+2-15][15]&&H_map[(counter+2-2)][2]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-2)][2];
					x = (counter+2-2);
					y = 2;
			end
			//(15,3)
			else if(H_map[(counter+2-3)][3]>H_map[counter+2-1][1]&&H_map[(counter+2-3)][3]>H_map[counter+2-2][2]&&H_map[(counter+2-3)][3]>H_map[counter+2-4][4]&&
				H_map[(counter+2-3)][3]>H_map[counter+2-5][5]&&H_map[(counter+2-3)][3]>H_map[counter+2-6][6]&&H_map[(counter+2-3)][3]>H_map[counter+2-7][7]&&
				H_map[(counter+2-3)][3]>H_map[counter+2-8][8]&&H_map[(counter+2-3)][3]>H_map[counter+2-9][9]&&H_map[(counter+2-3)][3]>H_map[counter+2-10][10]&&
				H_map[(counter+2-3)][3]>H_map[counter+2-11][11]&&H_map[(counter+2-3)][3]>H_map[counter+2-12][12]&&H_map[(counter+2-3)][3]>H_map[counter+2-13][13]&&
				H_map[(counter+2-3)][3]>H_map[counter+2-14][14]&&H_map[(counter+2-3)][3]>H_map[counter+2-15][15]&&H_map[(counter+2-3)][3]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-3)][3];
					x = (counter+2-3);
					y = 3;
			end
			//(14,4)
			else if(H_map[(counter+2-4)][4]>H_map[counter+2-1][1]&&H_map[(counter+2-4)][4]>H_map[counter+2-2][2]&&H_map[(counter+2-4)][4]>H_map[counter+2-3][3]&&
				H_map[(counter+2-4)][4]>H_map[counter+2-5][5]&&H_map[(counter+2-4)][4]>H_map[counter+2-6][6]&&H_map[(counter+2-4)][4]>H_map[counter+2-7][7]&&
				H_map[(counter+2-4)][4]>H_map[counter+2-8][8]&&H_map[(counter+2-4)][4]>H_map[counter+2-9][9]&&H_map[(counter+2-4)][4]>H_map[counter+2-10][10]&&
				H_map[(counter+2-4)][4]>H_map[counter+2-11][11]&&H_map[(counter+2-4)][4]>H_map[counter+2-12][12]&&H_map[(counter+2-4)][4]>H_map[counter+2-13][13]&&
				H_map[(counter+2-4)][4]>H_map[counter+2-14][14]&&H_map[(counter+2-4)][4]>H_map[counter+2-15][15]&&H_map[(counter+2-4)][4]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-4)][4];
					x = (counter+2-4);
					y = 4;
			end
			//(13,5)
			else if(H_map[(counter+2-5)][5]>H_map[counter+2-1][1]&&H_map[(counter+2-5)][5]>H_map[counter+2-2][2]&&H_map[(counter+2-5)][5]>H_map[counter+2-3][3]&&
				H_map[(counter+2-5)][5]>H_map[counter+2-4][4]&&H_map[(counter+2-5)][5]>H_map[counter+2-6][6]&&H_map[(counter+2-5)][5]>H_map[counter+2-7][7]&&
				H_map[(counter+2-5)][5]>H_map[counter+2-8][8]&&H_map[(counter+2-5)][5]>H_map[counter+2-9][9]&&H_map[(counter+2-5)][5]>H_map[counter+2-10][10]&&
				H_map[(counter+2-5)][5]>H_map[counter+2-11][11]&&H_map[(counter+2-5)][5]>H_map[counter+2-12][12]&&H_map[(counter+2-5)][5]>H_map[counter+2-13][13]&&
				H_map[(counter+2-5)][5]>H_map[counter+2-14][14]&&H_map[(counter+2-5)][5]>H_map[counter+2-15][15]&&H_map[(counter+2-5)][5]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-5)][5];
					x = (counter+2-5);
					y = 5;
			end
			//(12,6)
			else if(H_map[(counter+2-6)][6]>H_map[counter+2-1][1]&&H_map[(counter+2-6)][6]>H_map[counter+2-2][2]&&H_map[(counter+2-6)][6]>H_map[counter+2-3][3]&&
				H_map[(counter+2-6)][6]>H_map[counter+2-4][4]&&H_map[(counter+2-6)][6]>H_map[counter+2-5][5]&&H_map[(counter+2-6)][6]>H_map[counter+2-7][7]&&
				H_map[(counter+2-6)][6]>H_map[counter+2-8][8]&&H_map[(counter+2-6)][6]>H_map[counter+2-9][9]&&H_map[(counter+2-6)][6]>H_map[counter+2-10][10]&&
				H_map[(counter+2-6)][6]>H_map[counter+2-11][11]&&H_map[(counter+2-6)][6]>H_map[counter+2-12][12]&&H_map[(counter+2-6)][6]>H_map[counter+2-13][13]&&
				H_map[(counter+2-6)][6]>H_map[counter+2-14][14]&&H_map[(counter+2-6)][6]>H_map[counter+2-15][15]&&H_map[(counter+2-6)][6]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-6)][6];
					x = (counter+2-6);
					y = 6;
			end
			//(11,7)
			else if(H_map[(counter+2-7)][7]>H_map[counter+2-1][1]&&H_map[(counter+2-7)][7]>H_map[counter+2-2][2]&&H_map[(counter+2-7)][7]>H_map[counter+2-3][3]&&
				H_map[(counter+2-7)][7]>H_map[counter+2-4][4]&&H_map[(counter+2-7)][7]>H_map[counter+2-5][5]&&H_map[(counter+2-7)][7]>H_map[counter+2-6][6]&&
				H_map[(counter+2-7)][7]>H_map[counter+2-8][8]&&H_map[(counter+2-7)][7]>H_map[counter+2-9][9]&&H_map[(counter+2-7)][7]>H_map[counter+2-10][10]&&
				H_map[(counter+2-7)][7]>H_map[counter+2-11][11]&&H_map[(counter+2-7)][7]>H_map[counter+2-12][12]&&H_map[(counter+2-7)][7]>H_map[counter+2-13][13]&&
				H_map[(counter+2-7)][7]>H_map[counter+2-14][14]&&H_map[(counter+2-7)][7]>H_map[counter+2-15][15]&&H_map[(counter+2-7)][7]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-7)][7];
					x = (counter+2-7);
					y = 7;
			end
			//(10,8)
			else if(H_map[(counter+2-8)][8]>H_map[counter+2-1][1]&&H_map[(counter+2-8)][8]>H_map[counter+2-2][2]&&H_map[(counter+2-8)][8]>H_map[counter+2-3][3]&&
				H_map[(counter+2-8)][8]>H_map[counter+2-4][4]&&H_map[(counter+2-8)][8]>H_map[counter+2-5][5]&&H_map[(counter+2-8)][8]>H_map[counter+2-6][6]&&
				H_map[(counter+2-8)][8]>H_map[counter+2-7][7]&&H_map[(counter+2-8)][8]>H_map[counter+2-9][9]&&H_map[(counter+2-8)][8]>H_map[counter+2-10][10]&&
				H_map[(counter+2-8)][8]>H_map[counter+2-11][11]&&H_map[(counter+2-8)][8]>H_map[counter+2-12][12]&&H_map[(counter+2-8)][8]>H_map[counter+2-13][13]&&
				H_map[(counter+2-8)][8]>H_map[counter+2-14][14]&&H_map[(counter+2-8)][8]>H_map[counter+2-15][15]&&H_map[(counter+2-8)][8]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-8)][8];
					x = (counter+2-8);
					y = 8;
			end
			//(9,9)
			else if(H_map[(counter+2-9)][9]>H_map[counter+2-1][1]&&H_map[(counter+2-9)][9]>H_map[counter+2-2][2]&&H_map[(counter+2-9)][9]>H_map[counter+2-3][3]&&
				H_map[(counter+2-9)][9]>H_map[counter+2-4][4]&&H_map[(counter+2-9)][9]>H_map[counter+2-5][5]&&H_map[(counter+2-9)][9]>H_map[counter+2-6][6]&&
				H_map[(counter+2-9)][9]>H_map[counter+2-7][7]&&H_map[(counter+2-9)][9]>H_map[counter+2-8][8]&&H_map[(counter+2-9)][9]>H_map[counter+2-10][10]&&
				H_map[(counter+2-9)][9]>H_map[counter+2-11][11]&&H_map[(counter+2-9)][9]>H_map[counter+2-12][12]&&H_map[(counter+2-9)][9]>H_map[counter+2-13][13]&&
				H_map[(counter+2-9)][9]>H_map[counter+2-14][14]&&H_map[(counter+2-9)][9]>H_map[counter+2-15][15]&&H_map[(counter+2-9)][9]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-9)][9];
					x = (counter+2-9);
					y = 9;
			end
			//(8,10)
			else if(H_map[(counter+2-10)][10]>H_map[counter+2-1][1]&&H_map[(counter+2-10)][10]>H_map[counter+2-2][2]&&H_map[(counter+2-10)][10]>H_map[counter+2-3][3]&&
				H_map[(counter+2-10)][10]>H_map[counter+2-4][4]&&H_map[(counter+2-10)][10]>H_map[counter+2-5][5]&&H_map[(counter+2-10)][10]>H_map[counter+2-6][6]&&
				H_map[(counter+2-10)][10]>H_map[counter+2-7][7]&&H_map[(counter+2-10)][10]>H_map[counter+2-8][8]&&H_map[(counter+2-10)][10]>H_map[counter+2-9][9]&&
				H_map[(counter+2-10)][10]>H_map[counter+2-11][11]&&H_map[(counter+2-10)][10]>H_map[counter+2-12][12]&&H_map[(counter+2-10)][10]>H_map[counter+2-13][13]&&
				H_map[(counter+2-10)][10]>H_map[counter+2-14][14]&&H_map[(counter+2-10)][10]>H_map[counter+2-15][15]&&H_map[(counter+2-10)][10]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-10)][10];
					x = (counter+2-10);
					y = 10;
			end
			//(7,11)
			else if(H_map[(counter+2-11)][11]>H_map[counter+2-1][1]&&H_map[(counter+2-11)][11]>H_map[counter+2-2][2]&&H_map[(counter+2-11)][11]>H_map[counter+2-3][3]&&
				H_map[(counter+2-11)][11]>H_map[counter+2-4][4]&&H_map[(counter+2-11)][11]>H_map[counter+2-5][5]&&H_map[(counter+2-11)][11]>H_map[counter+2-6][6]&&
				H_map[(counter+2-11)][11]>H_map[counter+2-7][7]&&H_map[(counter+2-11)][11]>H_map[counter+2-8][8]&&H_map[(counter+2-11)][11]>H_map[counter+2-9][9]&&
				H_map[(counter+2-11)][11]>H_map[counter+2-10][10]&&H_map[(counter+2-11)][11]>H_map[counter+2-12][12]&&H_map[(counter+2-11)][11]>H_map[counter+2-13][13]&&
				H_map[(counter+2-11)][11]>H_map[counter+2-14][14]&&H_map[(counter+2-11)][11]>H_map[counter+2-15][15]&&H_map[(counter+2-11)][11]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-11)][11];
					x = (counter+2-11);
					y = 11;
			end
			//(6,12)
			else if(H_map[(counter+2-12)][12]>H_map[counter+2-1][1]&&H_map[(counter+2-12)][12]>H_map[counter+2-2][2]&&H_map[(counter+2-12)][12]>H_map[counter+2-3][3]&&
				H_map[(counter+2-12)][12]>H_map[counter+2-4][4]&&H_map[(counter+2-12)][12]>H_map[counter+2-5][5]&&H_map[(counter+2-12)][12]>H_map[counter+2-6][6]&&
				H_map[(counter+2-12)][12]>H_map[counter+2-7][7]&&H_map[(counter+2-12)][12]>H_map[counter+2-8][8]&&H_map[(counter+2-12)][12]>H_map[counter+2-9][9]&&
				H_map[(counter+2-12)][12]>H_map[counter+2-10][10]&&H_map[(counter+2-12)][12]>H_map[counter+2-11][11]&&H_map[(counter+2-12)][12]>H_map[counter+2-13][13]&&
				H_map[(counter+2-12)][12]>H_map[counter+2-14][14]&&H_map[(counter+2-12)][12]>H_map[counter+2-15][15]&&H_map[(counter+2-12)][12]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-12)][12];
					x = (counter+2-12);
					y = 12;
			end
			//(5,13)
			else if(H_map[(counter+2-13)][13]>H_map[counter+2-1][1]&&H_map[(counter+2-13)][13]>H_map[counter+2-2][2]&&H_map[(counter+2-13)][13]>H_map[counter+2-3][3]&&
				H_map[(counter+2-13)][13]>H_map[counter+2-4][4]&&H_map[(counter+2-13)][13]>H_map[counter+2-5][5]&&H_map[(counter+2-13)][13]>H_map[counter+2-6][6]&&
				H_map[(counter+2-13)][13]>H_map[counter+2-7][7]&&H_map[(counter+2-13)][13]>H_map[counter+2-8][8]&&H_map[(counter+2-13)][13]>H_map[counter+2-9][9]&&
				H_map[(counter+2-13)][13]>H_map[counter+2-10][10]&&H_map[(counter+2-13)][13]>H_map[counter+2-11][11]&&H_map[(counter+2-13)][13]>H_map[counter+2-12][12]&&
				H_map[(counter+2-13)][13]>H_map[counter+2-14][14]&&H_map[(counter+2-13)][13]>H_map[counter+2-15][15]&&H_map[(counter+2-13)][13]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-13)][13];
					x = (counter+2-13);
					y = 13;
			end
			//(4,14)
			else if(H_map[(counter+2-14)][14]>H_map[counter+2-1][1]&&H_map[(counter+2-14)][14]>H_map[counter+2-2][2]&&H_map[(counter+2-14)][14]>H_map[counter+2-3][3]&&
				H_map[(counter+2-14)][14]>H_map[counter+2-4][4]&&H_map[(counter+2-14)][14]>H_map[counter+2-5][5]&&H_map[(counter+2-14)][14]>H_map[counter+2-6][6]&&
				H_map[(counter+2-14)][14]>H_map[counter+2-7][7]&&H_map[(counter+2-14)][14]>H_map[counter+2-8][8]&&H_map[(counter+2-14)][14]>H_map[counter+2-9][9]&&
				H_map[(counter+2-14)][14]>H_map[counter+2-10][10]&&H_map[(counter+2-14)][14]>H_map[counter+2-11][11]&&H_map[(counter+2-14)][14]>H_map[counter+2-12][12]&&
				H_map[(counter+2-14)][14]>H_map[counter+2-13][13]&&H_map[(counter+2-14)][14]>H_map[counter+2-15][15]&&H_map[(counter+2-14)][14]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-14)][14];
					x = (counter+2-14);
					y = 14;
			end
			//(3,15)
			else if(H_map[(counter+2-15)][15]>H_map[counter+2-1][1]&&H_map[(counter+2-15)][15]>H_map[counter+2-2][2]&&H_map[(counter+2-15)][15]>H_map[counter+2-3][3]&&
				H_map[(counter+2-15)][15]>H_map[counter+2-4][4]&&H_map[(counter+2-15)][15]>H_map[counter+2-5][5]&&H_map[(counter+2-15)][15]>H_map[counter+2-6][6]&&
				H_map[(counter+2-15)][15]>H_map[counter+2-7][7]&&H_map[(counter+2-15)][15]>H_map[counter+2-8][8]&&H_map[(counter+2-15)][15]>H_map[counter+2-9][9]&&
				H_map[(counter+2-15)][15]>H_map[counter+2-10][10]&&H_map[(counter+2-15)][15]>H_map[counter+2-11][11]&&H_map[(counter+2-15)][15]>H_map[counter+2-12][12]&&
				H_map[(counter+2-15)][15]>H_map[counter+2-13][13]&&H_map[(counter+2-15)][15]>H_map[counter+2-14][14]&&H_map[(counter+2-15)][15]>H_map[counter+2-16][16])begin
					H_map_value = H_map[(counter+2-15)][15];
					x = (counter+2-15);
					y = 15;
			end
			//(2,16)
			else if(H_map[(counter+2-16)][16]>H_map[counter+2-1][1]&&H_map[(counter+2-16)][16]>H_map[counter+2-2][2]&&H_map[(counter+2-16)][16]>H_map[counter+2-3][3]&&
				H_map[(counter+2-16)][16]>H_map[counter+2-4][4]&&H_map[(counter+2-16)][16]>H_map[counter+2-5][5]&&H_map[(counter+2-16)][16]>H_map[counter+2-6][6]&&
				H_map[(counter+2-16)][16]>H_map[counter+2-7][7]&&H_map[(counter+2-16)][16]>H_map[counter+2-8][8]&&H_map[(counter+2-16)][16]>H_map[counter+2-9][9]&&
				H_map[(counter+2-16)][16]>H_map[counter+2-10][10]&&H_map[(counter+2-16)][16]>H_map[counter+2-11][11]&&H_map[(counter+2-16)][16]>H_map[counter+2-12][12]&&
				H_map[(counter+2-16)][16]>H_map[counter+2-13][13]&&H_map[(counter+2-16)][16]>H_map[counter+2-14][14]&&H_map[(counter+2-16)][16]>H_map[counter+2-15][15])begin
					H_map_value = H_map[(counter+2-16)][16];
					x = (counter+2-16);
					y = 16;
			end
		end
		else if(64 <= counter <= 79)begin
			for(i=1; i<counter-62; i=i+1)begin
				
			end
			for(i=64; i>counter-15; i=i-1)begin
				
			end
		end
		else if(80 <= counter <= 127)begin
			//(17,17)
			if(H_map[(counter-46-17)][17]>H_map[counter-46-18][18]&&H_map[(counter-46-17)][17]>H_map[counter-46-19][19]&&H_map[(counter-46-17)][17]>H_map[counter-46-20][20]&&
				H_map[(counter-46-17)][17]>H_map[counter-46-21][21]&&H_map[(counter-46-17)][17]>H_map[counter-46-22][22]&&H_map[(counter-46-17)][17]>H_map[counter-46-23][23]&&
				H_map[(counter-46-17)][17]>H_map[counter-46-24][24]&&H_map[(counter-46-17)][17]>H_map[counter-46-25][25]&&H_map[(counter-46-17)][17]>H_map[counter-46-26][26]&&
				H_map[(counter-46-17)][17]>H_map[counter-46-27][27]&&H_map[(counter-46-17)][17]>H_map[counter-46-28][28]&&H_map[(counter-46-17)][17]>H_map[counter-46-29][29]&&
				H_map[(counter-46-17)][17]>H_map[counter-46-30][30]&&H_map[(counter-46-17)][17]>H_map[counter-46-31][31]&&H_map[(counter-46-17)][17]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-17)][17];
					x = (counter-46-17);
					y = 17;
			end
			//(16,18)
			else if(H_map[(counter-46-18)][18]>H_map[counter-46-17][17]&&H_map[(counter-46-18)][18]>H_map[counter-46-19][19]&&H_map[(counter-46-18)][18]>H_map[counter-46-20][20]&&
				H_map[(counter-46-18)][18]>H_map[counter-46-21][21]&&H_map[(counter-46-18)][18]>H_map[counter-46-22][22]&&H_map[(counter-46-18)][18]>H_map[counter-46-23][23]&&
				H_map[(counter-46-18)][18]>H_map[counter-46-24][24]&&H_map[(counter-46-18)][18]>H_map[counter-46-25][25]&&H_map[(counter-46-18)][18]>H_map[counter-46-26][26]&&
				H_map[(counter-46-18)][18]>H_map[counter-46-27][27]&&H_map[(counter-46-18)][18]>H_map[counter-46-28][28]&&H_map[(counter-46-18)][18]>H_map[counter-46-29][29]&&
				H_map[(counter-46-18)][18]>H_map[counter-46-30][30]&&H_map[(counter-46-18)][18]>H_map[counter-46-31][31]&&H_map[(counter-46-18)][18]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-18)][18];
					x = (counter-46-18);
					y = 18;
			end
			//(15,19)
			else if(H_map[(counter-46-19)][19]>H_map[counter-46-17][17]&&H_map[(counter-46-19)][19]>H_map[counter-46-18][18]&&H_map[(counter-46-19)][19]>H_map[counter-46-20][20]&&
				H_map[(counter-46-19)][19]>H_map[counter-46-21][21]&&H_map[(counter-46-19)][19]>H_map[counter-46-22][22]&&H_map[(counter-46-19)][19]>H_map[counter-46-23][23]&&
				H_map[(counter-46-19)][19]>H_map[counter-46-24][24]&&H_map[(counter-46-19)][19]>H_map[counter-46-25][25]&&H_map[(counter-46-19)][19]>H_map[counter-46-26][26]&&
				H_map[(counter-46-19)][19]>H_map[counter-46-27][27]&&H_map[(counter-46-19)][19]>H_map[counter-46-28][28]&&H_map[(counter-46-19)][19]>H_map[counter-46-29][29]&&
				H_map[(counter-46-19)][19]>H_map[counter-46-30][30]&&H_map[(counter-46-19)][19]>H_map[counter-46-31][31]&&H_map[(counter-46-19)][19]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-19)][19];
					x = (counter-46-19);
					y = 19;
			end
			//(14,20)
			else if(H_map[(counter-46-20)][20]>H_map[counter-46-17][17]&&H_map[(counter-46-20)][20]>H_map[counter-46-18][18]&&H_map[(counter-46-20)][20]>H_map[counter-46-19][19]&&
				H_map[(counter-46-20)][20]>H_map[counter-46-21][21]&&H_map[(counter-46-20)][20]>H_map[counter-46-22][22]&&H_map[(counter-46-20)][20]>H_map[counter-46-23][23]&&
				H_map[(counter-46-20)][20]>H_map[counter-46-24][24]&&H_map[(counter-46-20)][20]>H_map[counter-46-25][25]&&H_map[(counter-46-20)][20]>H_map[counter-46-26][26]&&
				H_map[(counter-46-20)][20]>H_map[counter-46-27][27]&&H_map[(counter-46-20)][20]>H_map[counter-46-28][28]&&H_map[(counter-46-20)][20]>H_map[counter-46-29][29]&&
				H_map[(counter-46-20)][20]>H_map[counter-46-30][30]&&H_map[(counter-46-20)][20]>H_map[counter-46-31][31]&&H_map[(counter-46-20)][20]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-20)][20];
					x = (counter-46-20);
					y = 20;
			end
			//(13,21)
			else if(H_map[(counter-46-21)][21]>H_map[counter-46-17][17]&&H_map[(counter-46-21)][21]>H_map[counter-46-18][18]&&H_map[(counter-46-21)][21]>H_map[counter-46-19][19]&&
				H_map[(counter-46-21)][21]>H_map[counter-46-20][20]&&H_map[(counter-46-21)][21]>H_map[counter-46-22][22]&&H_map[(counter-46-21)][21]>H_map[counter-46-23][23]&&
				H_map[(counter-46-21)][21]>H_map[counter-46-24][24]&&H_map[(counter-46-21)][21]>H_map[counter-46-25][25]&&H_map[(counter-46-21)][21]>H_map[counter-46-26][26]&&
				H_map[(counter-46-21)][21]>H_map[counter-46-27][27]&&H_map[(counter-46-21)][21]>H_map[counter-46-28][28]&&H_map[(counter-46-21)][21]>H_map[counter-46-29][29]&&
				H_map[(counter-46-21)][21]>H_map[counter-46-30][30]&&H_map[(counter-46-21)][21]>H_map[counter-46-31][31]&&H_map[(counter-46-21)][21]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-21)][21];
					x = (counter-46-21);
					y = 21;
			end
			//(12,22)
			else if(H_map[(counter-46-22)][22]>H_map[counter-46-17][17]&&H_map[(counter-46-22)][22]>H_map[counter-46-18][18]&&H_map[(counter-46-22)][22]>H_map[counter-46-19][19]&&
				H_map[(counter-46-22)][22]>H_map[counter-46-20][20]&&H_map[(counter-46-22)][22]>H_map[counter-46-21][21]&&H_map[(counter-46-22)][22]>H_map[counter-46-23][23]&&
				H_map[(counter-46-22)][22]>H_map[counter-46-24][24]&&H_map[(counter-46-22)][22]>H_map[counter-46-25][25]&&H_map[(counter-46-22)][22]>H_map[counter-46-26][26]&&
				H_map[(counter-46-22)][22]>H_map[counter-46-27][27]&&H_map[(counter-46-22)][22]>H_map[counter-46-28][28]&&H_map[(counter-46-22)][22]>H_map[counter-46-29][29]&&
				H_map[(counter-46-22)][22]>H_map[counter-46-30][30]&&H_map[(counter-46-22)][22]>H_map[counter-46-31][31]&&H_map[(counter-46-22)][22]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-22)][22];
					x = (counter-46-22);
					y = 22;
			end
			//(11,23)
			else if(H_map[(counter-46-23)][23]>H_map[counter-46-17][17]&&H_map[(counter-46-23)][23]>H_map[counter-46-18][18]&&H_map[(counter-46-23)][23]>H_map[counter-46-19][19]&&
				H_map[(counter-46-23)][23]>H_map[counter-46-20][20]&&H_map[(counter-46-23)][23]>H_map[counter-46-21][21]&&H_map[(counter-46-23)][23]>H_map[counter-46-22][22]&&
				H_map[(counter-46-23)][23]>H_map[counter-46-24][24]&&H_map[(counter-46-23)][23]>H_map[counter-46-25][25]&&H_map[(counter-46-23)][23]>H_map[counter-46-26][26]&&
				H_map[(counter-46-23)][23]>H_map[counter-46-27][27]&&H_map[(counter-46-23)][23]>H_map[counter-46-28][28]&&H_map[(counter-46-23)][23]>H_map[counter-46-29][29]&&
				H_map[(counter-46-23)][23]>H_map[counter-46-30][30]&&H_map[(counter-46-23)][23]>H_map[counter-46-31][31]&&H_map[(counter-46-23)][23]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-23)][23];
					x = (counter-46-23);
					y = 23;
			end
			//(10,24)
			else if(H_map[(counter-46-24)][24]>H_map[counter-46-17][17]&&H_map[(counter-46-24)][24]>H_map[counter-46-18][18]&&H_map[(counter-46-24)][24]>H_map[counter-46-19][19]&&
				H_map[(counter-46-24)][24]>H_map[counter-46-20][20]&&H_map[(counter-46-24)][24]>H_map[counter-46-21][21]&&H_map[(counter-46-24)][24]>H_map[counter-46-22][22]&&
				H_map[(counter-46-24)][24]>H_map[counter-46-23][23]&&H_map[(counter-46-24)][24]>H_map[counter-46-25][25]&&H_map[(counter-46-24)][24]>H_map[counter-46-26][26]&&
				H_map[(counter-46-24)][24]>H_map[counter-46-27][27]&&H_map[(counter-46-24)][24]>H_map[counter-46-28][28]&&H_map[(counter-46-24)][24]>H_map[counter-46-29][29]&&
				H_map[(counter-46-24)][24]>H_map[counter-46-30][30]&&H_map[(counter-46-24)][24]>H_map[counter-46-31][31]&&H_map[(counter-46-24)][24]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-24)][24];
					x = (counter-46-24);
					y = 24;
			end
			//(9,25)
			else if(H_map[(counter-46-25)][25]>H_map[counter-46-17][17]&&H_map[(counter-46-25)][25]>H_map[counter-46-18][18]&&H_map[(counter-46-25)][25]>H_map[counter-46-19][19]&&
				H_map[(counter-46-25)][25]>H_map[counter-46-20][20]&&H_map[(counter-46-25)][25]>H_map[counter-46-21][21]&&H_map[(counter-46-25)][25]>H_map[counter-46-22][22]&&
				H_map[(counter-46-25)][25]>H_map[counter-46-23][23]&&H_map[(counter-46-25)][25]>H_map[counter-46-24][24]&&H_map[(counter-46-25)][25]>H_map[counter-46-26][26]&&
				H_map[(counter-46-25)][25]>H_map[counter-46-27][27]&&H_map[(counter-46-25)][25]>H_map[counter-46-28][28]&&H_map[(counter-46-25)][25]>H_map[counter-46-29][29]&&
				H_map[(counter-46-25)][25]>H_map[counter-46-30][30]&&H_map[(counter-46-25)][25]>H_map[counter-46-31][31]&&H_map[(counter-46-25)][25]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-25)][25];
					x = (counter-46-25);
					y = 25;
			end
			//(8,26)
			else if(H_map[(counter-46-26)][26]>H_map[counter-46-17][17]&&H_map[(counter-46-26)][26]>H_map[counter-46-18][18]&&H_map[(counter-46-26)][26]>H_map[counter-46-19][19]&&
				H_map[(counter-46-26)][26]>H_map[counter-46-20][20]&&H_map[(counter-46-26)][26]>H_map[counter-46-21][21]&&H_map[(counter-46-26)][26]>H_map[counter-46-22][22]&&
				H_map[(counter-46-26)][26]>H_map[counter-46-23][23]&&H_map[(counter-46-26)][26]>H_map[counter-46-24][24]&&H_map[(counter-46-26)][26]>H_map[counter-46-25][25]&&
				H_map[(counter-46-26)][26]>H_map[counter-46-27][27]&&H_map[(counter-46-26)][26]>H_map[counter-46-28][28]&&H_map[(counter-46-26)][26]>H_map[counter-46-29][29]&&
				H_map[(counter-46-26)][26]>H_map[counter-46-30][30]&&H_map[(counter-46-26)][26]>H_map[counter-46-31][31]&&H_map[(counter-46-26)][26]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-26)][26];
					x = (counter-46-26);
					y = 26;
			end
			//(7,27)
			else if(H_map[(counter-46-27)][27]>H_map[counter-46-17][17]&&H_map[(counter-46-27)][27]>H_map[counter-46-18][18]&&H_map[(counter-46-27)][27]>H_map[counter-46-19][19]&&
				H_map[(counter-46-27)][27]>H_map[counter-46-20][20]&&H_map[(counter-46-27)][27]>H_map[counter-46-21][21]&&H_map[(counter-46-27)][27]>H_map[counter-46-22][22]&&
				H_map[(counter-46-27)][27]>H_map[counter-46-23][23]&&H_map[(counter-46-27)][27]>H_map[counter-46-24][24]&&H_map[(counter-46-27)][27]>H_map[counter-46-25][25]&&
				H_map[(counter-46-27)][27]>H_map[counter-46-26][26]&&H_map[(counter-46-27)][27]>H_map[counter-46-28][28]&&H_map[(counter-46-27)][27]>H_map[counter-46-29][29]&&
				H_map[(counter-46-27)][27]>H_map[counter-46-30][30]&&H_map[(counter-46-27)][27]>H_map[counter-46-31][31]&&H_map[(counter-46-27)][27]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-27)][27];
					x = (counter-46-27);
					y = 27;
			end
			//(6,28)
			else if(H_map[(counter-46-28)][28]>H_map[counter-46-17][17]&&H_map[(counter-46-28)][28]>H_map[counter-46-18][18]&&H_map[(counter-46-28)][28]>H_map[counter-46-19][19]&&
				H_map[(counter-46-28)][28]>H_map[counter-46-20][20]&&H_map[(counter-46-28)][28]>H_map[counter-46-21][21]&&H_map[(counter-46-28)][28]>H_map[counter-46-22][22]&&
				H_map[(counter-46-28)][28]>H_map[counter-46-23][23]&&H_map[(counter-46-28)][28]>H_map[counter-46-24][24]&&H_map[(counter-46-28)][28]>H_map[counter-46-25][25]&&
				H_map[(counter-46-28)][28]>H_map[counter-46-26][26]&&H_map[(counter-46-28)][28]>H_map[counter-46-27][27]&&H_map[(counter-46-28)][28]>H_map[counter-46-29][29]&&
				H_map[(counter-46-28)][28]>H_map[counter-46-30][30]&&H_map[(counter-46-28)][28]>H_map[counter-46-31][31]&&H_map[(counter-46-28)][28]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-28)][28];
					x = (counter-46-28);
					y = 28;
			end
			//(5,29)
			else if(H_map[(counter-46-29)][29]>H_map[counter-46-17][17]&&H_map[(counter-46-29)][29]>H_map[counter-46-18][18]&&H_map[(counter-46-29)][29]>H_map[counter-46-19][19]&&
				H_map[(counter-46-29)][29]>H_map[counter-46-20][20]&&H_map[(counter-46-29)][29]>H_map[counter-46-21][21]&&H_map[(counter-46-29)][29]>H_map[counter-46-22][22]&&
				H_map[(counter-46-29)][29]>H_map[counter-46-23][23]&&H_map[(counter-46-29)][29]>H_map[counter-46-24][24]&&H_map[(counter-46-29)][29]>H_map[counter-46-25][25]&&
				H_map[(counter-46-29)][29]>H_map[counter-46-26][26]&&H_map[(counter-46-29)][29]>H_map[counter-46-27][27]&&H_map[(counter-46-29)][29]>H_map[counter-46-28][28]&&
				H_map[(counter-46-29)][29]>H_map[counter-46-30][30]&&H_map[(counter-46-29)][29]>H_map[counter-46-31][31]&&H_map[(counter-46-29)][29]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-29)][29];
					x = (counter-46-29);
					y = 29;
			end
			//(4,30)
			else if(H_map[(counter-46-30)][30]>H_map[counter-46-17][17]&&H_map[(counter-46-30)][30]>H_map[counter-46-18][18]&&H_map[(counter-46-30)][30]>H_map[counter-46-19][19]&&
				H_map[(counter-46-30)][30]>H_map[counter-46-20][20]&&H_map[(counter-46-30)][30]>H_map[counter-46-21][21]&&H_map[(counter-46-30)][30]>H_map[counter-46-22][22]&&
				H_map[(counter-46-30)][30]>H_map[counter-46-23][23]&&H_map[(counter-46-30)][30]>H_map[counter-46-24][24]&&H_map[(counter-46-30)][30]>H_map[counter-46-25][25]&&
				H_map[(counter-46-30)][30]>H_map[counter-46-26][26]&&H_map[(counter-46-30)][30]>H_map[counter-46-27][27]&&H_map[(counter-46-30)][30]>H_map[counter-46-28][28]&&
				H_map[(counter-46-30)][30]>H_map[counter-46-29][29]&&H_map[(counter-46-30)][30]>H_map[counter-46-31][31]&&H_map[(counter-46-30)][30]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-30)][30];
					x = (counter-46-30);
					y = 30;
			end
			//(3,31)
			else if(H_map[(counter-46-31)][31]>H_map[counter-46-17][17]&&H_map[(counter-46-31)][31]>H_map[counter-46-18][18]&&H_map[(counter-46-31)][31]>H_map[counter-46-19][19]&&
				H_map[(counter-46-31)][31]>H_map[counter-46-20][20]&&H_map[(counter-46-31)][31]>H_map[counter-46-21][21]&&H_map[(counter-46-31)][31]>H_map[counter-46-22][22]&&
				H_map[(counter-46-31)][31]>H_map[counter-46-23][23]&&H_map[(counter-46-31)][31]>H_map[counter-46-24][24]&&H_map[(counter-46-31)][31]>H_map[counter-46-25][25]&&
				H_map[(counter-46-31)][31]>H_map[counter-46-26][26]&&H_map[(counter-46-31)][31]>H_map[counter-46-27][27]&&H_map[(counter-46-31)][31]>H_map[counter-46-28][28]&&
				H_map[(counter-46-31)][31]>H_map[counter-46-29][29]&&H_map[(counter-46-31)][31]>H_map[counter-46-30][30]&&H_map[(counter-46-31)][31]>H_map[counter-46-32][32])begin
					H_map_value = H_map[(counter-46-31)][31];
					x = (counter-46-31);
					y = 31;
			end
			//(2,32)
			else if(H_map[(counter-46-32)][32]>H_map[counter-46-17][17]&&H_map[(counter-46-32)][32]>H_map[counter-46-18][18]&&H_map[(counter-46-32)][32]>H_map[counter-46-19][19]&&
				H_map[(counter-46-32)][32]>H_map[counter-46-20][20]&&H_map[(counter-46-32)][32]>H_map[counter-46-21][21]&&H_map[(counter-46-32)][32]>H_map[counter-46-22][22]&&
				H_map[(counter-46-32)][32]>H_map[counter-46-23][23]&&H_map[(counter-46-32)][32]>H_map[counter-46-24][24]&&H_map[(counter-46-32)][32]>H_map[counter-46-25][25]&&
				H_map[(counter-46-32)][32]>H_map[counter-46-26][26]&&H_map[(counter-46-32)][32]>H_map[counter-46-27][27]&&H_map[(counter-46-32)][32]>H_map[counter-46-28][28]&&
				H_map[(counter-46-32)][32]>H_map[counter-46-29][29]&&H_map[(counter-46-32)][32]>H_map[counter-46-30][30]&&H_map[(counter-46-32)][32]>H_map[counter-46-31][31])begin
					H_map_value = H_map[(counter-46-32)][32];
					x = (counter-46-32);
					y = 32;
			end
		end
		else if(128 <= counter <= 143)begin
			for(i=1; i<counter-126; i=i+1)begin
				
			end
			
			for(i=64; i>counter-79; i=i-1)begin
				
			end
		end
		else if(144 <= counter <= 191)begin
			for(i=33; i<=48; i=i+1)begin
				
			end
		end
		else if(192 <= counter <= 206)begin
			
			end
		end
	end
end

//assign S_map_value = R[x] == Q[y]? match : mismatch;
//assign I_map_value = H_map[x][y-1] - open > I_map[x][y-1] - extend ? H_map[x][y-1] - open : I_map[x][y-1] - extend;
//assign D_map_value = H_map[x-1][y] - open > D_map[x-1][y] - extend ? H_map[x-1][y] - open : D_map[x-1][y] - extend;

always@(*) begin
	if(	H_map[x-1][y-1] + S_map_value >= I_map_value && H_map[x-1][y-1] + S_map_value >= D_map_value && H_map[x-1][y-1] + S_map_value >= 0)begin
			H_map_value = H_map[x-1][y-1] + S_map_value;
	end
	else if(I_map_value >= H_map[x-1][y-1] + S_map_value && I_map_value >= D_map_value && I_map_value >= 0)begin
			H_map_value = I_map_value;
	end
	else if(D_map_value >= H_map[x-1][y-1] + S_map_value && D_map_value >= I_map_value && D_map_value >= 0)begin
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
			I_map[i][0] <= -30;
			D_map[i][0] <= -30;
		end
		for(j=0; j<=48; j=j+1) begin
			H_map[0][j] <= 0;
			I_map[0][j] <= -30;
			D_map[0][j] <= -30;
		end
	end
	/*else begin
		if(ns == CAL) begin
			S_map[x][y] <= S_map_value;
			I_map[x][y] <= I_map_value;
			D_map[x][y] <= D_map_value;
			H_map[x][y] <= H_map_value;
		end
	end*/
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
			if(counter == 206)
				ns = OUTPUT;
		end
		OUTPUT:begin
			ns = IDLE;
		end
	endcase
end
    
endmodule
