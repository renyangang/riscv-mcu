iverilog.exe -y ../../verilog -y ../../verilog/core -y ../../verilog/testbench -y ../../verilog/peripherals/digital -y ../../verilog/soc -y ../../verilog/peripherals -I ../../verilog/core -o digital_soc.vvp ./digital_soc_top.v
vvp.exe -M. -mnetm  digital_soc.vvp