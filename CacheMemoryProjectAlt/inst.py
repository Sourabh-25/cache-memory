import random

sizeOfAddress = 32
wordSize = 1
sizeOfData = wordSize * 8

f1= open("inst1.txt","w")
f2 = open("trace1.txt","r")

data = f2.readlines()

for i in data:
    x = int(i[:-1],16)
    s = "0" + bin(x)[2:].zfill(sizeOfAddress) + bin(random.randint(0,2**sizeOfData))[2:].zfill(sizeOfData)
    # print(s)
    f1.write(hex(int(s,2))[2:]+"\n")


f1.close()
f2.close()
    
    