# riscv-mcu

## 介绍

B站讲解视频(持续更新中): [讲解合集](https://space.bilibili.com/505193782/channel/collectiondetail?sid=3829887) 

目录结构进行了整理：
1. netlist 目录下，存放基于digital软件，通过连线方式设计的CPU，以及对应的启动和测试代码。这部分版本定型，不再更新。具体的介绍参见：[riscv-digital](doc/netlist_zh.md)。
2. verilog 目录下, 存放基于verilog开发的riscv cpu代码，持续更新中。
3. digital_soc 目录下， 存放基于digital软件使用verilog编写的cpu模块搭建的SoC，可以通过digital模拟方式运行。
4. fpga_soc 目录下， 存放基于fpga的riscv cpu模块搭建的SoC，暂未开始，目标是在fpga开发板上运行verilog实现的cpu ip并进行外设驱动运行。

## netlist 使用说明

1. 基于digital软件的仿真模拟，参考 [riscv-digital](doc/netlist_zh.md)。
2. B站视频中cpu流水线相关的测试，如果需要运行，请git获取tag v1.0.3版本，因后续对pipeline模块进行了修改，原先的testbench无法执行，获取tag命令如下:
```shell
 git checkout tags/v1.0.3
```

## digital_soc使用说明

**1. 编译引导测试程序**

引导和测试程序代码在 digital_soc/src 目录下，在目录下执行:
```shell
make; python3 ./mkhex.py
```
生成的boot.hex为引导程序字节码在digital仿真中使用，test.hex在verilog仿真中使用。


**2. verilog仿真**

在 verilog 目录下，执行如下命令进行综合仿真
```shell
./make.bat digital_soc 
```
然后执行如下命令查看波形
```shell
 gtkwave.exe ./digital_soc.vcd 
 ```


**3. digital仿真**

* 在digital软件中，打开 digital_soc/digital/digital_soc.dig文件。 
* 执行前，需要在 riscvmcu 组件上点击右键，然后在选项卡 中的 iverilog选项中，将依赖路径修改为本机对应的路径，然后保存关闭后运行。


**4. 开发环境安装**

  1. iverilog 安装：
     >windows下安装，[下载连接](http://bleyer.org/icarus/)  
     linux 下安装，[参考地址](https://steveicarus.github.io/iverilog/usage/installation.html)

  2. digital软件安装： [下载链接](https://github.com/hneemann/Digital)

  3. riscv编译工具链安装：
     >地址：[riscv-gnu-toolchain](https://gitee.com/riscv-mcu/riscv-gnu-toolchain)

        ```
        sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build  
        ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d   
        make linux
        ```

  4. FPGA开发工具Quartus安装：[下载链接](https://www.intel.com/content/www/us/en/software-kit/825278/intel-quartus-prime-lite-edition-design-software-version-23-1-1-for-windows.html)