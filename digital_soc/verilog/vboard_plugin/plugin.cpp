#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif
#include "verilated.h"
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

void setInput(unsigned char* input,int input_size) {
    topp->clk = input[0];
    topp->rst = input[1];
    topp->clk_timer = input[2];
    topp->digital_flash_data = input[3];
    topp->digital_flash_ready = input[4];
    topp->digital_mem_data = *(IData*)&(input[5]);
    topp->digital_mem_ready = input[5+sizeof(IData)];
    topp->gpio_values_in = *(IData*)&(input[5+sizeof(IData)+1]);
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
}

extern "C" {

    DLL_EXPORT void init() {
        if (!run_flag) {
            contextp = new VerilatedContext();
            topp = new Vvboard_soc_top{contextp};
            contextp->debug(0);
            contextp->randReset(2);
            contextp->traceEverOn(true);
            run_flag = 1;
        }
    }

    DLL_EXPORT void eval(unsigned char* input,int input_size,unsigned char* output,int output_size) {
        setInput(input,input_size);
        // printf("%d %d %d \n",input[0],input[1],input[2]);
        topp->eval();
        contextp->timeInc(1);
        getOutput(output,output_size);
    }

    DLL_EXPORT void stop() {
        run_flag = 0;
        topp->final();
        contextp->statsPrintSummary();
        delete topp;
        delete contextp;
    }

    DLL_EXPORT void nanoSleep(int ns) {
        struct timespec ns_sleep;
        ns_sleep.tv_sec = 0;
        ns_sleep.tv_nsec = ns;
        nanosleep(&ns_sleep,NULL);
    }
}