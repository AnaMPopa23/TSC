/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter
 *
 * An error can be injected into the design by invoking compilation with
 * the option:  +define+FORCE_LOAD_ERROR
 *
 **********************************************************************/

module instr_register
//ca sa am tipurile de vatiabile
import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
// input = semnal de intrare, valori pe care le vom esantiona
// pe output se poate transmite
(input  logic          clk,
 input  logic          load_en,
 input  logic          reset_n,
 input  operand_t      operand_a,
 input  operand_t      operand_b,
 input  opcode_t       opcode,
 input  address_t      write_pointer,
 input  address_t      read_pointer,
 output instruction_t  instruction_word
);
  timeunit 1ns/1ns;
  // un array de 32 de biti de locatii de instruction_t; functioneaza ca o memorie care poate memora 32 de instr compuse din 3 chestii
  // logic test [0:31] -> registru ????
  instruction_t  iw_reg [0:31];  // an array of instruction_word structures

  // write to the register
  // orice este dupa @ este lista de sensibilitati
  // orice schimbare determina declansarea executiei; fnctioneaza ca un bistabil
  always@(posedge clk, negedge reset_n)   // write into register
    if (!reset_n) begin
      foreach (iw_reg[i]) // pt fiecare element din array
      // opc =  ZERO si a si b devin 0; initializez structura
      // resetul initializeaza toate registrele cu o valoare predefinita
      // frecventa = calea cea mai lunga dintre doua bistabile
        iw_reg[i] = '{opc:ZERO,default:0};  // reset to all zeros
    end
    else if (load_en) begin 
      // cand o sa fie load_en = 1 voi pune structura in array-ul iw_reg la adresa write_pointer
      // utlima valoaatre e valida la overwrite
    case (opcode)
      ZERO: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, 'b0};
      PASSA : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, operand_a};
      PASSB : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, operand_b};
      ADD   : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a + operand_b)};
      SUB   : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a - operand_b)};
      MULT  : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a * operand_b)};
      //DIV   : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a / operand_b)};    //12/3/2024 Ana Popa
      DIV   : if(operand_b == 0)
                iw_reg[write_pointer] = '{opcode, operand_a, operand_b, 'b0};
              else 
                iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a / operand_b)};
        
      MOD   : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, $signed(operand_a % operand_b)};
    default : iw_reg[write_pointer] = '{opcode, operand_a, operand_b, 'b0};
    endcase //32 de elemente
    end

  // read from the register
  // asignam unei valori de iesire
  assign instruction_word = iw_reg[read_pointer];  // continuously read from register

// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
`ifdef FORCE_LOAD_ERROR
initial begin
  force operand_b = operand_a; // cause wrong value to be loaded into operand_b
end
`endif

endmodule: instr_register
