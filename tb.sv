`include "uvm_macros.svh"
 import uvm_pkg::*;


//////////////////////////////////////////////////////////

typedef enum bit [1:0]   {readd = 0, writed = 1, rstdut = 2} oper_mode;


class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
  oper_mode op;
  logic wr;
  logic rst;
  randc logic [6:0] addr;
  rand logic [7:0] din;
  logic [7:0] datard;
  logic done;

  function new(string name = "transaction");
    super.new(name);
  endfunction

endclass : transaction


///////////////////////////////////////////////////////////////////////


///////////////////write seq
class write_data extends uvm_sequence#(transaction);
  `uvm_object_utils(write_data)
  
  transaction tr;

  function new(string name = "write_data");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(15)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.op = writed;
        `uvm_info("SEQ", $sformatf("MODE : WRITE DIN : %0d ADDR : %0d ", tr.din, tr.addr), UVM_NONE);
        finish_item(tr);
      end
  endtask
  

endclass
//////////////////////////////////////////////////////////


class read_data extends uvm_sequence#(transaction);
  `uvm_object_utils(read_data)
  
  transaction tr;

  function new(string name = "read_data");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(15)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.op = readd;
        `uvm_info("SEQ", $sformatf("MODE : READ ADDR : %0d ", tr.addr), UVM_NONE);
        finish_item(tr);
      end
  endtask
  

endclass
/////////////////////////////////////////////////////////////////////

class reset_dut extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_dut)
  
  transaction tr;

  function new(string name = "reset_dut");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(15)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.op = rstdut;
        `uvm_info("SEQ", "MODE : RESET", UVM_NONE);
        finish_item(tr);
      end
  endtask
  

endclass
////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual i2c_i vif;
  transaction tr;

  
  function new(input string path = "drv", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     tr = transaction::type_id::create("tr");
      
      if(!uvm_config_db#(virtual i2c_i)::get(this,"","vif",vif))//uvm_test_top.env.agent.drv.aif
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  
  
  ////////////////////reset task
  task reset_dut(); 
    begin
    `uvm_info("DRV", "System Reset", UVM_MEDIUM);
    vif.rst       <= 1'b1;  ///active high reset
    vif.addr      <= 0;
    vif.din       <= 0; 
    vif.wr        <= 0;
    @(posedge vif.clk);
    end
  endtask
  
  ///////////////////////write 
  task write_d();
    `uvm_info("DRV", $sformatf("mode : WRITE addr : %0d  din : %0d", tr.addr, tr.din), UVM_NONE);
  vif.rst  <= 1'b0;
  vif.wr   <= 1'b1;
  vif.addr <= tr.addr;
  vif.din  <= tr.din;
  @(posedge vif.done);
   
  endtask 
            
   task read_d();         
  `uvm_info("DRV", $sformatf("mode : READ addr : %0d  din : %0d", tr.addr, tr.din), UVM_NONE);
  vif.rst  <= 1'b0;
  vif.wr   <= 1'b0;
  vif.addr <= tr.addr;
  vif.din  <= 0;
  @(posedge vif.done);        
   endtask
  
  

  virtual task run_phase(uvm_phase phase);
    forever begin
     
         seq_item_port.get_next_item(tr);
     
     
                   if(tr.op ==  rstdut)
                          begin
                          reset_dut();
                          end

                  else if(tr.op == writed)
                          begin
                          write_d();
                          end
    
                else if(tr.op ==  readd)
                          begin
					      read_d();
                          end
                          
       seq_item_port.item_done();
     
   end
  endtask

  
endclass

//////////////////////////////////////////////////////////////////////////////////////////////


class mon extends uvm_monitor;
`uvm_component_utils(mon)

uvm_analysis_port#(transaction) send;
transaction tr;
virtual i2c_i vif;

    function new(input string inst = "mon", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    send = new("send", this);
      if(!uvm_config_db#(virtual i2c_i)::get(this,"","vif",vif))//uvm_test_top.env.agent.drv.aif
        `uvm_error("MON","Unable to access Interface");
    endfunction
    
    
    virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      
      if(vif.rst)
        begin
        tr.op   = rstdut;
        tr.done = vif.done;
        tr.rst  = vif.rst;
        tr.wr   = vif.wr; 
        tr.din  = vif.din;
        tr.addr = vif.addr;
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send.write(tr);
        end
        
        
      else begin
        
        if(vif.wr)
               begin
                      tr.op   = writed;
                      tr.rst  = vif.rst;
                      tr.wr   = vif.wr;
                      tr.addr = vif.addr;
                      tr.din  = vif.din;
                      tr.done = vif.done;
                      @(posedge vif.done);
                      `uvm_info("MON", $sformatf("DATA WRITE addr:%0d data:%0d",tr.addr,tr.din), UVM_NONE); 
                      send.write(tr);
              end
        else if (!vif.wr)
              begin
                      tr.op = readd; 
                      tr.rst  = vif.rst;
                      tr.wr   = vif.wr;
                      tr.addr = vif.addr;
                      tr.din  = vif.din;
                      tr.done = vif.done;
                      @(posedge vif.done);  
                      tr.datard = vif.datard;
                      `uvm_info("MON", $sformatf("DATA READ addr:%0d data:%0d ",tr.addr,tr.datard), UVM_NONE); 
                      send.write(tr);
           end      
    end
end
   endtask 

endclass
//////////////////////////////////////////////////////////////////////////////////////////////////
class spi_cov_subscriber extends uvm_subscriber#(transaction);
  `uvm_component_utils(spi_cov_subscriber)

  transaction tr;
  uvm_analysis_imp#(transaction,spi_cov_subscriber) rec;

  covergroup cg(ref transaction tr);
    option.per_instance = 1;

    addr : coverpoint tr.addr {
      bins low = { [0:64]   };
      bins high = { [65:127]};
    }

    din  : coverpoint tr.din {
      bins low  = { [0:31]   };
      bins mid  = { [32:127] };
      bins high = { [128:255]};
    }

    datard : coverpoint tr.datard {
     bins low = { [0:64]   };
     bins high = { [65:127]};
    }

    wr   : coverpoint tr.wr {
      bins low  = {0};
      bins high = {1};
    }

    rst  : coverpoint tr.rst {
      bins low  = {0};
      bins high = {1};
    }

    done : coverpoint tr.done {
      bins low  = {0};
      bins high = {1};
    }

    // when wr is low what is datard
    write_rst0_wr0_datard : cross rst, wr, datard {
      ignore_bins rst_high            = binsof(rst)  intersect {1};
      ignore_bins wr_low              = binsof(wr)   intersect {1};
    }

  endgroup

  function new(string name="spi_cov_subscriber", uvm_component parent=null);
    super.new(name, parent);
    cg = new(tr);   
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    rec = new("rec", this);
  endfunction

  virtual function void write(transaction t);
    tr = t; 
    cg.sample();        
  endfunction

endclass
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class sco extends uvm_scoreboard;
`uvm_component_utils(sco)

  uvm_analysis_imp#(transaction,sco) recv;
  bit [7:0] arr[128] = '{default:0};
  bit [7:0] data_rd = 0;
 


    function new(input string inst = "sco", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
    endfunction
    
    
  virtual function void write(transaction tr);
    if(tr.op == rstdut)
              begin
                `uvm_info("SCO", "SYSTEM RESET DETECTED", UVM_NONE);
              end  
    else if (tr.op == writed)
      begin
          arr[tr.addr] = tr.din;
          `uvm_info("SCO", $sformatf("DATA WRITE OP  addr:%0d, wdata:%0d arr_wr:%0d",tr.addr,tr.din,  arr[tr.addr]), UVM_NONE);
      end
 
    else if (tr.op == readd)
                begin
                  data_rd = arr[tr.addr];
                  if (data_rd == tr.datard)
                    `uvm_info("SCO", $sformatf("DATA MATCHED : addr:%0d, rdata:%0d",tr.addr,tr.datard), UVM_NONE)
                         else
                     `uvm_info("SCO",$sformatf("TEST FAILED : addr:%0d, rdata:%0d data_rd_arr:%0d",tr.addr,tr.datard,data_rd), UVM_NONE) 
                end
     
  
    $display("----------------------------------------------------------------");
    endfunction

endclass


//////////////////////////////////////////////////////////////////////////////////////////////
                  


class agent extends uvm_agent;
`uvm_component_utils(agent)
  
 

function new(input string inst = "agent", uvm_component parent = null);
super.new(inst,parent);
endfunction

 driver d;
 uvm_sequencer#(transaction) seqr;
 mon m; 
 


virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);

   m = mon::type_id::create("m",this);
   d = driver::type_id::create("d",this);
   seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
 
  
  
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
endfunction

endclass

//////////////////////////////////////////////////////////////////////////////////

class env extends uvm_env;
`uvm_component_utils(env)

function new(input string inst = "env", uvm_component c);
super.new(inst,c);
endfunction

agent a;
sco s;
spi_cov_subscriber cov;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  a = agent::type_id::create("a",this);
  s = sco::type_id::create("s", this);
  cov=spi_cov_subscriber::type_id::create("cov", this);
endfunction

  
virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
 a.m.send.connect(s.recv);
 a.m.send.connect(cov.rec);
endfunction

endclass

//////////////////////////////////////////////////////////////////////////

class test extends uvm_test;
`uvm_component_utils(test)

function new(input string inst = "test", uvm_component c);
super.new(inst,c);
endfunction

env e;
write_data wdata; 
read_data rdata;
reset_dut rstdut;  

  
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
   e      = env::type_id::create("env",this);
   wdata  = write_data::type_id::create("wdata");
   rdata  = read_data::type_id::create("rdata");
   rstdut = reset_dut::type_id::create("rstdut");
endfunction

virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  
   rstdut.start(e.a.seqr);

   wdata.start(e.a.seqr);

   rdata.start(e.a.seqr);

phase.drop_objection(this);
endtask
endclass

//////////////////////////////////////////////////////////////////////
module tb;
  
    
    
  i2c_i vif();
  
  i2c_mem dut (.clk(vif.clk), .rst(vif.rst), .wr(vif.wr), .addr(vif.addr), .din(vif.din), .datard(vif.datard), .done(vif.done));

  bind i2c_mem assertion dut1 (.clk(vif.clk), .rst(vif.rst), .wr(vif.wr), .addr(vif.addr), .din(vif.din), .datard(vif.datard), .done(vif.done));

  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk;

   
  
  initial begin
    uvm_config_db#(virtual i2c_i)::set(null, "*", "vif", vif);
    run_test("test");
   end
  
endmodule

module assertion  (

input logic clk, rst, wr,
input logic [6:0] addr,
input logic [7:0] din,
input logic  [7:0] datard,
input logic done
);

// 1. wr must me 0 when reset is active
  assert property (@(posedge clk) rst |-> (wr == 1'b0))
    else $error("WR asserted during reset at %0t",$time);

 
// During read operation, din must remain 0
    assert property (@(posedge clk)  (!rst && wr == 1'b0) |-> (din == 0)) else $error("DIN active during READ at %0t", $time);


endmodule