iverilog.exe -y . -y ./core -y ./testbench  -I ./core -o testbench.vvp ./testbench/*.v 
vvp.exe ./testbench.vvp
