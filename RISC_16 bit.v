module RISC_behav( output [31:0] WBdata,
input clock, input rst
);
reg [5:0] pc;
wire Stallbit, RS1Depend, RS2Depend; reg [7:0] memory [63:0];
reg [31:0] RegisterFile [31:0]; reg [31:0] IF_ID, ALUout;
reg [72:0] ID_EX;
reg [37:0] EX_WB;
wire [31:0] OpA, OpB; wire [2:0] ALUControls;
always @(posedge clock) begin
if(rst) begin
if(Stallbit)
pc <= pc; else
pc <= pc +4;
end
 end 
else
pc <= 0;
always @(posedge clock) begin
if(rst) begin
if(!Stallbit) begin
IF_ID[7:0] <= memory [pc]; IF_ID[15:8] <= memory [pc+1]; IF_ID[23:16] <= memory [pc+2]; IF_ID[31:24] <= memory [pc+3];
end else
IF_ID <= IF_ID;
end
else begin
IF_ID <= 32'hFFFF_FFFF;
memory[0] <= 8'h41; memory[1] <= 8'h8C; memory[2] <= 8'h00; memory[3] <= 8'h00;

end end
memory[8] <= 8'h66; memory[9] <= 8'hA0; memory[10] <= 8'h01; memory[11] <= 8'h00;
memory[12] <= 8'h2A; memory[13] <= 8'h2D; memory[14] <= 8'h02; memory[15] <= 8'h00;
assign RS1Depend = ((ID_EX[4:0] == IF_ID[4:0]) && (!ID_EX[72])) ||
((EX_WB[36:32] == IF_ID[4:0]) &&
(!EX_WB[37]));

always @(posedge clock) begin
if(rst) begin
ID_EX [72] <= Stallbit; if(!Stallbit)
begin
ID_EX [4:0] <= IF_ID[14:10];	//regd ID_EX [71:69] <= IF_ID[17:15]; //opcode
ID_EX [68:37] <= RegisterFile[IF_ID[9:5]]; //OpA ID_EX [36:5] <= RegisterFile[IF_ID[4:0]]; //OpB
end else
ID_EX [71:0] <= 72'd0;
end
else
ID_EX[72:0] <= 0;
RegisterFile[1] = 40;
RegisterFile[2] = 60;
RegisterFile[4] = 60;
RegisterFile[5] = 40; RegisterFile[7] = 32'hFFFF856D;RegisterFile[11] = 32'hFFFF765E;
always @(negedge clock) begin
if(rst) begin
if(!EX_WB[37])
begin
RegisterFile[EX_WB[36:32]] <= WBdata;
end
end
end
assign OpA =	ID_EX [68:37]; assign OpB =	ID_EX [36:5];
assign ALUControls = ID_EX [71:69];
always @(OpA, OpB, ALUControls) begin
ALUout = OpA - OpB; 2'b11:
ALUout = ~(OpA & OpB); endcase
end
always @(posedge clock)
begin
if(rst) begin
EX_WB[37] <= ID_EX[72]; if(!ID_EX[72])
begin
EX_WB[31:0] <= ALUout; EX_WB[36:32] <= ID_EX[4:0];
end
end else
EX_WB[36:0] <= 37'd0;
end
else
EX_WB <=	0;
assign WBdata = EX_WB[31:0]; endmodule

/****** Stall/forwarding logic ******/

module RISC_DF( output [31:0] WBdata,
input clock, input rst
);
reg [5:0] pc;
wire DFbit, RS1Depend, RS2Depend; reg [7:0] memory [63:0];
reg [31:0] RegisterFile [31:0]; reg [31:0] IF_ID, ALUout;
reg [71:0] ID_EX;
reg [36:0] EX_WB;
wire [31:0] OpA, OpB; wire [2:0] ALUControls;
always @(posedge clock) begin
if(rst) begin
pc <= pc +4;
end
end else
pc <= 0;
always @(posedge clock) begin
if(rst) begin
IF_ID[7:0] <= memory [pc]; IF_ID[15:8] <= memory [pc+1]; IF_ID[23:16] <= memory [pc+2]; IF_ID[31:24] <= memory [pc+3];
end else begin
IF_ID <= 32'hFFFF_FFFF;
memory[0] <= 8'h41; memory[1] <= 8'h8C; memory[2] <= 8'h00; memory[3] <= 8'h00;
memory[4] <= 8'hA3; memory[5] <= 8'h18; memory[6] <= 8'h01; memory[7] <= 8'h00;
memory[8] <= 8'h66; memory[9] <= 8'hA0; memory[10] <= 8'h01; memory[11] <= 8'h00;
end end
memory[12] <= 8'h2A; memory[13] <= 8'h2D; memory[14] <= 8'h02; memory[15] <= 8'h00;
assign RS1Depend = (ID_EX[4:0] == IF_ID[4:0]); assign RS2Depend = (ID_EX[4:0] == IF_ID[9:5]);
//	assign DFbit = RS1Depend || RS2Depend ;
always @(posedge clock) begin
if(rst)
begin
ID_EX [4:0] <= IF_ID[14:10];	//regd ID_EX [71:69] <= IF_ID[17:15]; //opcode
if(RS2Depend)	//OpA
ID_EX [68:37] <= ALUout;
else
ID_EX[68:37] <= RegisterFile[IF_ID[9:5]]; //OpA if(RS1Depend)	//opB
ID_EX [36:5] <= ALUout;
else
ID_EX[36:5] <= RegisterFile[IF_ID[4:0]];
end
end else
ID_EX[71:0] <= 0;
RegisterFile[1] = 40;
RegisterFile[2] = 60;
RegisterFile[4] =
if(rst) begin
RegisterFile[EX_WB[36:32]] <= WBdata;
end
end
assign OpA =	ID_EX [68:37]; assign OpB =	ID_EX [36:5];
assign ALUControls = ID_EX [71:69];
always @(OpA, OpB, ALUControls) begin
case (ALUControls) 2'b00:
ALUout = ~(OpA | OpB); 2'b01:
ALUout = OpA + OpB; 2'b10:
ALUout = OpA - OpB;
end
2'b11:
ALUout = ~(OpA & OpB); endcase
always @(posedge clock) begin
if(rst) begin
EX_WB[31:0] <= ALUout; EX_WB[36:32] <= ID_EX[4:0];
end
end else
EX_WB <=	0;
assign WBdata = EX_WB[31:0]; endmodule
