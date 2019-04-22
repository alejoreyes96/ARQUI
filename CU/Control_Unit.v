module test;
  reg [6:0] state1;
  reg Clr, Clk;
  reg [5:0] count;
  reg [31:0] IR, clear;
  wire [6:0] state, Y;
  wire COND, MOC, IR_Ld, MAR_Ld, 
  MDR_Ld, MuxMAR_Ld, RF_Ld, MuxC_Ld, 
  PC_Ld, nPC_Ld, MuxMDR_Ld, MOV, RW;
  wire [5:0] opcode;
  wire[1:0] MuxA_Ld, MuxB_Ld;
  reg[32:0] test;
Control_Unit CU(state, Y, state1, COND, IR, MOC, count, IR_Ld, MAR_Ld, MDR_Ld, MuxMAR_Ld, RF_Ld, MuxC_Ld, PC_Ld, nPC_Ld, MuxMDR_Ld, MOV, RW, opcode, MuxA_Ld, MuxB_Ld, Clr, Clk);

initial begin
count = 6'd0;
Clr = 1'b0;
#11 Clr = 1'b1;
end
 
 
initial #3000 $finish;
initial begin
IR = 32'b00000000001000010000000000100001;
#60
IR = 32'b10100000001000010000000000100001;
#90
IR = 32'b00010000001000010000000000100001;
#55
IR = clear;

end

assign MOC = 1'b0;
assign COND = 1'b0;
assign initstate = 7'd0;
// esta parte es par el reloj
initial begin
Clk =1'b0;
forever #5 Clk = ~Clk;
end

initial begin
  state1 = 7'd0;
end
initial begin
$display("                     Data                                   IR                  State   ");
#5
$display("\n   Data %b   %b     %d\n", CU.data_out, IR, CU.st);
repeat(20) begin
#10
$display("   Data %b    %b    %d\n", CU.data_out, IR,  CU.st);


end
end
endmodule



module Control_Unit(output [6:0] state, 
                    output [6:0] Y, 
                    input  [6:0] state1 , 
                    input COND,
                    input [31:0] IR, 
                    input MOC, 
                    input [5:0] count,
                    output IR_Ld,
                    output MAR_Ld,
                    output MDR_Ld,
                    output MuxMAR_Ld,
                    output RF_Ld,
                    output MuxC_Ld,
                    output PC_Ld,
                    output nPC_Ld,
                    output MuxMDR_Ld,
                    output MOV,
                    output RW,
                    output [5:0] opcode,
                    output [1:0] MuxA_Ld, MuxB_Ld,
                    input Clr, Clk);

// outputs 
wire [5:0] CR;  // esto es para los estados 
wire Sts ,in,Inv;  // aqui los el inverter y NSAddressSelector
wire[1:0] M, S;  // para los moc  y NSASelector
wire [2:0] N;  // para NSASelecto
wire [6:0] D;  // salida del adder  
wire [6:0] Q; // salida del incremento 
wire[32:0] data_out;
wire[6:0] st;
// instancias entre moduluos 
 IR_Encoder enc( state, IR,Clk);   
  MUX_COND mxcnd( in, MOC,COND, S); 
inverter inv( Sts, in, Inv);  
next_state_address_selector nsas( M,  N, Sts); 
  state_adder stadd( D,  st, 7'd1); 
incrementer_register increg( Q,  D, Clk);
  MUX_ROM mxrom( st, state, state1, CR, Q, M, Clr); 
microStore mcStr(st, data_out);  
control_register Creg(N, Inv, S, IR_Ld, MAR_Ld, MDR_Ld, MuxMAR_Ld, RF_Ld, MuxC_Ld, PC_Ld, nPC_Ld, MuxMDR_Ld, MOV, RW, opcode, MuxA_Ld, MuxB_Ld, CR, Y, data_out, Clr, Clk);

endmodule//////////////////////////////////////////////////////////////////////////////////////////


module IR_Encoder(output reg [6:0] state, input [31:0] IR, input Clk);
  wire [5:0] func;
  wire [5:0] opcode;

  assign func = IR[5:0];
  assign opcode = IR[31:26];
  always@(IR, Clk)
  
    case(opcode)
      6'b000000: 
        case(func)
          6'b100001: state = 7'd6;
        endcase
      6'b101000: state = 7'd67;
      6'b000100: state = 7'd80;
    endcase


 
endmodule

module MUX_COND(output reg out, input I0, I1, input [1:0] S);
  always @(S)
    case(S)
    2'b00: out = I0;
    2'b01: out = I1;
    endcase

endmodule

module MUX_ROM(output reg [6:0] Y, input [6:0] I0, I1, input[5:0] I2, input[6:0] I3, input [1:0] M, input Clr);
  always @*

//Clr redirects to state 0 and clears CR
  if(!Clr)
    Y = 7'd0;
  else
      case(M)
        2'b00: Y = I0; 
        2'b01: Y = I1;
        2'b10: Y = I2;
        2'b11: Y = I3;
      endcase

endmodule

module next_state_address_selector(output reg [1:0] M, input [2:0] N, input Sts);
  wire [3:0] A;

  assign A[0] = Sts;
  assign A[3:1] = N;
  always @(A)
    case(A)
    
    4'b0000: M = 2'b00;
    4'b0001: M = 2'b00;
    4'b0010: M = 2'b01;
    4'b0011: M = 2'b01;
    4'b0100: M = 2'b10;
    4'b0101: M = 2'b10;
    4'b0110: M = 2'b11;
    4'b0111: M = 2'b11;
    4'b1000: M = 2'b00;
    4'b1001: M = 2'b10;
    4'b1010: M = 2'b11;
    4'b1011: M = 2'b10;
    4'b1100: M = 2'b11;
    4'b1101: M = 2'b00;
    4'b1110: M = 2'b00;
    4'b1111: M = 2'b00;
    endcase

endmodule

module state_adder(output [6:0] Z, input [6:0] A, B);
  assign Z = A + B;

endmodule

module incrementer_register(output reg [6:0] Q, input [6:0] D, input  Clk);
  always @(posedge Clk)
  Q=D;
endmodule

module inverter(output reg out, input in, inv);
  wire [1:0] A;

  assign A[0] = in;
  assign A[1] = inv;

  always @(A)
    case(A)
    2'b00: out = 1'b0;
    2'b01: out = 1'b1;
    2'b10: out = 1'b1;
    2'b11: out = 1'b0;
    endcase

endmodule

module microStore(input [6:0] Y, output reg [32:0] data_out);

  reg[2:0] N;
  reg Inv;
  reg[1:0] S;
  reg IR_Ld;
  reg MAR_Ld;
  reg MDR_Ld;
  reg MuxMAR_Ld;
  reg RF_Ld;
  reg MuxC_Ld;
  reg PC_Ld;
  reg nPC_Ld;
  reg MuxMDR_Ld;
  reg MOV;
  reg RW;
  reg[5:0] opcode;
  reg[1:0] MuxA_Ld, MuxB_Ld;
  reg[5:0] CR;
  reg dummy1;
  reg [1:0] dummy2;
  reg [5:0] dummy3;

  always @(*)
  
    case(Y)
        7'd0:
        begin
            N = 3'b011;//  32
            Inv = 1'b0;//  29
            S = 2'b00;//  28
            IR_Ld = 1'b0;//  26
            MAR_Ld = 1'b0;//  25
            MDR_Ld = 1'b0;//  24
            MuxMAR_Ld = 1'b0;//  23
            RF_Ld = 1'b0;// 22
            MuxC_Ld = 1'b0;// 21
            PC_Ld = 1'b0;// 20
            nPC_Ld = 1'b0;// 19
            MuxMDR_Ld = 1'b0;// 18
            MOV = 1'b0;// 17
            RW = 1'b0;// 16
            opcode = 6'b000000;// 15
            MuxA_Ld = 2'b00;// 9
            MuxB_Ld = 2'b00; // 7
            CR = 6'b000001; // 5
          
            data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};

          end


         7'd1:
        begin
          N = 3'b011;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld = 1'b0;// 20
          PC_Ld = 1'b1;// 19
          nPC_Ld = 1'b1;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b0;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b01;// 8
          MuxB_Ld = 2'b01; // 6
          CR = 6'b000001; //4
          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};

        end
         7'd2:
        begin
          N = 3'b010;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b1;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld = 1'b0;// 20
          PC_Ld = 1'b1;// 19
          nPC_Ld = 1'b1;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b1;// 16
          RW = 1'b1;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000011; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};

        end
         7'd3:
        begin
            N = 3'b101;//  32
            Inv = 1'b0;//  28
            S = 2'b01;//  27
            IR_Ld = 1'b1;//  25
            MAR_Ld = 1'b0;//  24
            MDR_Ld = 1'b0;//  23
            MuxMAR_Ld = 1'b0;//  22
            RF_Ld = 1'b0;// 21
            MuxC_Ld = 1'b0;// 20
            PC_Ld = 1'b0;// 19
            nPC_Ld = 1'b0;// 18
            MuxMDR_Ld = 1'b0;// 17
            MOV = 1'b0;// 16
            RW = 1'b0;// 15
            opcode = 6'b000000;// 14
            MuxA_Ld = 2'b00;// 8
            MuxB_Ld = 2'b00; // 6
            CR = 6'b000011; //4
      
          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};

        end
         7'd4:
        begin
          N = 3'b000;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = dummy1;//  25
          MAR_Ld = dummy1;//  24
          MDR_Ld = dummy1;//  23
          MuxMAR_Ld = dummy1;//  22
          RF_Ld = dummy1;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = dummy1;// 19
          nPC_Ld = dummy1;// 18
          MuxMDR_Ld = dummy1;// 17
          MOV = dummy1;// 16
          RW = dummy1;// 15
          opcode = dummy3;// 14
          MuxA_Ld = dummy2;// 8
          MuxB_Ld = dummy2; // 6
          CR = 6'b000001; //4
          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};

        end
      7'd6:
        begin
          N = 3'b010;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b1;// 21
          MuxC_Ld = 1'b1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b0;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
      7'd67:
        begin
          N = 3'b011;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b1;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
          7'd68:
        begin
          N = 3'b011;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b1;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b1;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b1;// 17
          MOV = 1'b0;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b01;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
          7'd69:
        begin
          N = 3'b011;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b1;//  23
          MuxMAR_Ld = 1'b1;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b1;// 17
          MOV = 1'b1;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
          7'd70:
        begin
          N = 3'b010;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b1;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
      7'd80:
        begin
         
          N = 3'b011;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b0;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b0;// 19
          nPC_Ld = 1'b0;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b0;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b00;// 8
          MuxB_Ld = 2'b00; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end
         7'd81:
        begin
         N = 3'b010;//  32
          Inv = 1'b0;//  28
          S = 2'b00;//  27
          IR_Ld = 1'b0;//  25
          MAR_Ld = 1'b0;//  24
          MDR_Ld = 1'b0;//  23
          MuxMAR_Ld = 1'b0;//  22
          RF_Ld = 1'b1;// 21
          MuxC_Ld =dummy1;// 20
          PC_Ld = 1'b1;// 19
          nPC_Ld = 1'b1;// 18
          MuxMDR_Ld = 1'b0;// 17
          MOV = 1'b1;// 16
          RW = 1'b0;// 15
          opcode = 6'b000000;// 14
          MuxA_Ld = 2'b10;// 8
          MuxB_Ld = 2'b01; // 6
          CR = 6'b000001; //4

          data_out = {N,Inv,S,IR_Ld,MAR_Ld,MDR_Ld,MuxMAR_Ld,RF_Ld,MuxC_Ld,PC_Ld,nPC_Ld,MuxMDR_Ld,MOV,RW,opcode,MuxA_Ld,MuxB_Ld,CR};
        end

     
	endcase

endmodule

module control_register(output reg[2:0] N,
 output reg Inv,
 output reg[1:0] S,
 output reg IR_Ld,
 output reg MAR_Ld,
 output reg MDR_Ld,
 output reg MuxMAR_Ld,
 output reg RF_Ld,
 output reg MuxC_Ld,
 output reg PC_Ld,
 output reg nPC_Ld,
 output reg MuxMDR_Ld,
 output reg MOV,
 output reg RW,
 output reg[5:0] opcode,
 output reg[1:0] MuxA_Ld, MuxB_Ld,
 output reg[5:0] CR,
 output reg[6:0] Y, 
 input [32:0] Ds,
 input Clr, Clk);
  always @(posedge Clk)

      begin
        CR=Ds[5:0]; 
        MuxB_Ld=Ds[7:6]; 
        MuxA_Ld=Ds[9:8]; 
        opcode=Ds[15:10]; 
        RW=Ds[16]; 
        MOV=Ds[17]; 
        MuxMDR_Ld=Ds[18]; 
        nPC_Ld=Ds[19]; 
        PC_Ld=Ds[20]; 
        MuxC_Ld=Ds[21]; 
        RF_Ld=Ds[22]; 
        MuxMAR_Ld=Ds[23]; 
        MDR_Ld=Ds[24]; 
        MAR_Ld=Ds[25]; 
        IR_Ld=Ds[26]; 
        S=Ds[28:27]; 
        Inv=Ds[29]; 
        N=Ds[32:30];  

      end
    //  initial begin
    //  #5
    // $display("   Data in CR %b       %d\n", Ds,  CU.st);
    //  repeat(18) begin
    //  #10
    //   $display("   Data in CR %b       %d\n", Ds,  CU.st);
    // end
    //  end

endmodule