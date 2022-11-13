module fileopen ();
    integer i,j,fd,rv;
    reg [31:0] mem[543:0];
    initial begin
        fd = $fopen("trace1.txt", "r");
        for (i = 0; i < 524; i = i + 1)
            rv = $fscanf(fd, "%h", mem[i]);
    end
    
    always @(*) begin
        for(i = 0;i<524;i = i+1)
            $display("%0h",mem[i]);
        
    end
endmodule
