module tb();
reg clk;
initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0,tb);
        clk                  = 1;
        repeat(150000) #100 clk = ~clk;
    end
    memoryProject memoryProject(
        .clk(clk)
    );
endmodule