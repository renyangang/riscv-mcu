iverilog.exe -y . -y ./core -y ./testbench -y ./peripherals/digital -y ./soc -y ./peripherals -I ./core -o testbench.vvp ./testbench/%1_tb.v 
vvp.exe ./testbench.vvp
