module memoryProject(clk);
    
    //parameters
    parameter sizeOfAddress = 32;
    parameter byteToBits    = 8; //which is also equal to number of bits of size of data
    
    parameter k                  = 8;                                                                        //k-way set associative cache
    parameter bitsOfk            = 3;                                                                    // log2(k)
    parameter index              = 64;
    parameter bitsOfIndex        = 6;                                                                // log2(index)
    parameter blockSize          = 2;                                                                  //number of bytes in a block
    parameter wordSize           = 1;                                                                  //number of bytes in a block
    parameter bitsOfBlockSize    = 1;
    parameter tag                = sizeOfAddress- bitsOfIndex-bitsOfBlockSize;                             //
    parameter cacheElementSize   = 1+ tag + blockSize*byteToBits;                             //  | validBit | Tag | Data |
    parameter instructionSize    = 1 + sizeOfAddress + wordSize*byteToBits;                             //  | read/write | Address | Data(word) |
    parameter instructionMemSize = 524; //
    parameter mainMemorySize     = 268435456; //Should not exceed than this value ,i.e., 2^28 because verilog doesn't support more than 2^30
    
    reg[cacheElementSize-1:0] cacheMemory[index-1:0][k-1:0];
    reg [instructionSize-1:0] instructionMem[instructionMemSize-1:0];
    reg[byteToBits-1:0] mainMemory[mainMemorySize-1:0];
    reg[bitsOfk-1:0] cost[index-1:0][k-1:0];                                                //for LRU implementation
    reg [31:0] mem[523:0];
    
    input clk;
    reg [32+byteToBits:0] instruction;                                                               // 1 read/0write 32 address  16 bits block   ->   49 bits
    
    reg [sizeOfAddress-1:0] address;
    reg [15:0] dataToWrite;                                                                 // used in write instruction
    reg readWrite;
    
    reg[31:0] PC;
    reg[31:0] temp;
    reg isHit;
    integer i = 0;
    integer j = 0;
    integer locationOfHit;
    integer writeOnMiss;
    integer countHit,countMiss,countTotal;
    integer fd = 0;
    integer rv = 0;
    integer o,p;
    
    reg[blockSize*byteToBits-1:0] dataFromMainMemory;
    integer addressForReadWhileHit;
    
    initial begin
        countHit           = 0;
        countMiss          = 0;
        countTotal         = 0;
        PC                 = 0;
        readWrite          = 0;
        dataToWrite        = 0;
        dataFromMainMemory = 0;
        addressForReadWhileHit=0;
        for(i = 0;i<index;i = i+1)begin
            for(j = 0;j<k;j = j+1) begin
                cost[i][j] = 0;
            end
        end
        for(i = 0;i<index;i = i+1)begin
            for(j = 0;j<k;j = j+1) begin
                cacheMemory[i][j] = 0;
            end
        end
        
        
        
        
        fd = $fopen("inst1.txt", "r");
        for (i = 0; i < instructionMemSize; i = i + 1)begin
            rv = $fscanf(fd, "%h",instructionMem[i]);
        end
        
    end
    
    // implementing cache
    always@(posedge clk)begin
        //code for instruction decode , comm
        instruction = instructionMem[PC];
        isHit <= 0;
        #0.5 begin
        readWrite   = instruction[instructionSize-1];
        address     = instruction[instructionSize-2:instructionSize-1-sizeOfAddress];
        dataToWrite = instruction[byteToBits-1:0];
        end
    
    //address = mem[PC];
    #2 for(i = 0;i<k;i = i+1)begin
    isHit = isHit||((cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1]) && (address[sizeOfAddress-1:bitsOfBlockSize+bitsOfIndex] == cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-2:cacheElementSize-1-tag]));
    if ((cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1]) && (address[sizeOfAddress-1:bitsOfBlockSize+bitsOfIndex] == cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-2:cacheElementSize-1-tag]))begin
        locationOfHit = i;
    end
    end
    
    
    
    #4 case(isHit)
    1'b1:begin
    //  address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]
    addressForReadWhileHit= wordSize*byteToBits*address[bitsOfBlockSize-1:0];  //addressForReadWhileHit+bytesToBits-1:addressForReadWhileHit
    for(i = 0;i<k;i = i+1)begin
        if (cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1]&&(cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i]<cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][locationOfHit]))begin
            cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i] = cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i]+1;
        end
        
    end
    cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][locationOfHit] = 0;
    end
    1'b0:begin
    addressForReadWhileHit= wordSize*byteToBits*address[bitsOfBlockSize-1:0];
    for(i = 0;i<k;i = i+1)begin
        if (cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1])begin
            if (cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i] != k-1) begin
                cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i] = cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i]+1;
            end
            else begin
                cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i] = 0;
                writeOnMiss                                                     = i;
            end
        end
    end
    for(i = 0;i<k;i = i+1)begin
        if (~cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1])begin
            cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i][cacheElementSize-1] = 1;
            cost[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][i]                            = 0;
            writeOnMiss                                                                                = i;
            i                                                                                          = k;
        end
    end
    
    end
    
    endcase


    #6 case(isHit)
    1'b1: begin
    //RN we are just maintaining count of hit and miss and just updating cache
    countHit   = countHit+1;
    countTotal = countTotal+1;
    case (readWrite)
        1'b1:begin

            // cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][locationOfHit][ (blockSize*wordSize*bytesToBits) -1 :0 ];
        end
        1'b0:begin          
        end
    endcase
    end
    1'b0: begin
    
    countMiss                                                                        = countMiss+1;
    countTotal                                                                       = countTotal+1;
    cacheMemory[address[bitsOfIndex+bitsOfBlockSize-1:bitsOfBlockSize]][writeOnMiss] = {1'b1,address[sizeOfAddress-1:bitsOfBlockSize+bitsOfIndex], dataFromMainMemory};
    end
    endcase
    #8 PC = PC+1'd1;
    #8 $display("CountHit %d", countHit);
    #8 $display("CountMiss %d", countMiss);
    #8 $display("CountTotal %d", countTotal);
    #8 $display("HitPercentage %d", 100*countHit/countTotal);
    end
    
endmodule
    
    
