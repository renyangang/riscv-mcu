iverilog.exe -y . -y ./core -y ./testbench  -I ./core -o testbench.vvp ./testbench/%1_tb.v 
vvp.exe ./testbench.vvp
