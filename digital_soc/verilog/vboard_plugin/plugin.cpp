/*                                                                      
    Designer   : Renyangang               
                                                                            
    Licensed under the Apache License, Version 2.0 (the "License");         
    you may not use this file except in compliance with the License.        
    You may obtain a copy of the License at                                 
                                                                            
        http://www.apache.org/licenses/LICENSE-2.0                          
                                                                            
    Unless required by applicable law or agreed to in writing, software    
    distributed under the License is distributed on an "AS IS" BASIS,       
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and     
    limitations under the License. 
*/
#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vvboard_soc_top.h"
#include <thread>
#include <time.h>
#include <mutex>

#define SIG_SIZE 128

std::mutex mtx; 

static volatile char run_flag = 0;
static volatile char cpu_thread_flag = 0;

VerilatedContext *contextp;
Vvboard_soc_top *topp;
VerilatedVcdC *tfp;

void setInput(unsigned char* input,int input_size) {
    int pos = 0;
    topp->clk = input[pos];
    pos++;
    topp->rst_n = input[pos];
    pos++;
    topp->clk_timer = input[pos];
    pos++;
    topp->digital_flash_data = input[pos];
    pos++;
    topp->digital_flash_ready = input[pos];
    pos++;
    topp->digital_mem_data = *(IData*)&(input[pos]);
    pos += sizeof(IData);
    topp->digital_mem_ready = input[pos];
    pos++;
    topp->gpio_values_in = *(IData*)&(input[pos]);
    pos += sizeof(IData);
    topp->uart_rx = input[pos];
}

void getOutput(unsigned char* output,int output_size) {
    int pos = 0;
    memcpy((void*)&(output[pos]), &(topp->digital_flash_addr), sizeof(IData));
    pos += sizeof(IData);
    memcpy((void*)&(output[pos]), &(topp->digital_flash_read_en), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_flash_write_en), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_flash_byte_size), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_flash_wdata), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_mem_write_en), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_mem_read_en), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_mem_addr), sizeof(IData));
    pos += sizeof(IData);
    memcpy((void*)&(output[pos]), &(topp->digital_mem_byte_size), sizeof(CData));
    pos += sizeof(CData);
    memcpy((void*)&(output[pos]), &(topp->digital_mem_wdata), sizeof(IData));
    pos += sizeof(IData);
    memcpy((void*)&(output[pos]), &(topp->gpio_values_out), sizeof(IData));
    pos += sizeof(IData);
    memcpy((void*)&(output[pos]), &(topp->uart_tx), sizeof(CData));
}

double sc_time_stamp() { return contextp->time(); }

extern "C" {

    DLL_EXPORT void init() {
        if (!run_flag) {
            contextp = new VerilatedContext();
            topp = new Vvboard_soc_top{contextp};
            tfp = new VerilatedVcdC();
            contextp->debug(0);
            contextp->randReset(0);
            contextp->traceEverOn(true);
            contextp->trace(tfp, 0);
            tfp->open("d:\\vboard_soc_top.vcd");
            run_flag = 1;
        }
    }

    DLL_EXPORT void eval(unsigned char* input,int input_size,unsigned char* output,int output_size) {
        setInput(input,input_size);
        // printf("%d %d %d \n",input[0],input[1],input[2]);
        topp->eval();
        contextp->timeInc(1);
        tfp->dump(contextp->time());
        getOutput(output,output_size);
    }

    DLL_EXPORT void stop() {
        run_flag = 0;
        tfp->flush();
        tfp->close();
        topp->final();
        contextp->statsPrintSummary();
        contextp->traceEverOn(false);
        delete(topp);
        delete(tfp);
        delete(contextp);
        // delete topp;
        // delete contextp;
    }

    DLL_EXPORT void nanoSleep(int ns) {
        struct timespec ns_sleep;
        ns_sleep.tv_sec = 0;
        ns_sleep.tv_nsec = ns;
        nanosleep(&ns_sleep,NULL);
    }
}