/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,    //in dut sunt invers tipurile de date (input output)
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;

  parameter WR_NR = 20;
  parameter RD_NR =  19;

  instruction_t  iw_reg_test[0:31];
  result_t result_test;

  int seed = 555;  

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles asteapta 2 fronturi pizitiv e de test clk
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    //repeat (3) begin Ana Popa: 3/6/2025
    repeat (WR_NR) begin 
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    for (int i=0; i<=RD_NR; i++) begin  //Ana Popa 3/6/2024
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk) read_pointer = i;
      @(negedge clk) print_results;
      check_results;
    end

    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;                               // nu se mai aloca alta variabila de memorie, doar prima dara cand primeste valoarea
    // random -> valori pe 32 de biti signed
    operand_a     <= $random(seed)%16;                 // between -15 and 15
    // unsigned = nr poz din nr negativ
    operand_b     <= $unsigned($random)%16;            // between 0 and 15
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    write_pointer <= temp++;                           // temp++ = mai intai asigneaza 0 si dupa se incrementeaza
    iw_reg_test[temp] = '{opcode, operand_a, operand_b, 'b0};
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);       //opcode.name = exact demunirea gen mult sub add
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  rezultat = %0d\n", instruction_word.rezultat);
  endfunction: print_results

  function void check_results;
    case (iw_reg_test[read_pointer].opc)
        ZERO: result_test = {64{1'b0}};
        PASSA: result_test = iw_reg_test[read_pointer].op_a;
        PASSB: result_test = iw_reg_test[read_pointer].op_b;
        ADD: result_test = iw_reg_test[read_pointer].op_a + iw_reg_test[read_pointer].op_b;
        SUB: result_test = iw_reg_test[read_pointer].op_a - iw_reg_test[read_pointer].op_b;
        MULT: result_test = iw_reg_test[read_pointer].op_a * iw_reg_test[read_pointer].op_b;
        DIV: if (iw_reg_test[read_pointer].op_b == {32{1'b0}})
               result_test = {64{1'b0}}; 
             else
               result_test = iw_reg_test[read_pointer].op_a / iw_reg_test[read_pointer].op_b;
        MOD: result_test = iw_reg_test[read_pointer].op_a % iw_reg_test[read_pointer].op_b;
        default: result_test = {64{1'b0}};
      endcase

    $display("\nCheck result function:");
    $display("  read_pointer = %0d", read_pointer);
    $display("  opcode = %0d (%s)", iw_reg_test[read_pointer].opc, iw_reg_test[read_pointer].opc.name);
    $display("  operand_a = %0d",   iw_reg_test[read_pointer].op_a);
    $display("  operand_b = %0d\n", iw_reg_test[read_pointer].op_b);
    $display("\nCalculated test result: %0d\n", result_test);

      if(result_test === instruction_word.rezultat) 
      begin
        $display("  result = %0d\n", result_test);
        $display("The result is correct! :) \n");
      end
      else 
      begin
        $display("The result is incorrect! PLEASE CHECK! :( \n");
      end
  endfunction: check_results

endmodule: instr_register_test
