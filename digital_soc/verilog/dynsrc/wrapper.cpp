#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif
#include "verilated.h"
#include "Vdigital_soc_top.h"
#include <thread>
#include <time.h>
#include <mutex>

#define SIG_SIZE 128

std::mutex mtx; 

static volatile char input_sig[SIG_SIZE];
static volatile char output_sig[SIG_SIZE];
static volatile char run_flag = 0;
static volatile char cpu_thread_flag = 0;

VerilatedContext *contextp;
Vdigital_soc_top *topp;
// const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
// const std::unique_ptr<Vdigital_soc_top> topp{new Vdigital_soc_top{contextp.get()}};

void cpu_loop() {
    contextp = new VerilatedContext();
    topp = new Vdigital_soc_top{contextp};
    // Verilated::debug(0);
    contextp->debug(0);
    contextp->randReset(2);
    contextp->traceEverOn(true);
    memset((void*)input_sig, 0, SIG_SIZE);
    struct timespec ns_sleep;
    ns_sleep.tv_sec = 0;
    ns_sleep.tv_nsec = 5;
    unsigned char clk = 0;
    
    // Simulate until $finish
    while (!contextp->gotFinish() && run_flag) {
        // Evaluate model
        topp->clk = clk;
        mtx.lock();
        topp->input_sig = (*(QData*)input_sig);
        mtx.unlock();
        topp->eval();
        mtx.lock();
        memcpy((void*)output_sig, (char*)&(topp->output_sig.m_storage[0]), sizeof(EData)*topp->output_sig.Words);
        mtx.unlock();
        if (clk) {
            clk = 0;
        }else {
            clk = 1;
        }
        // Advance time
        contextp->timeInc(1);
        nanosleep(&ns_sleep,NULL);
    }

    // Execute 'final' processes
    topp->final();
    contextp->statsPrintSummary();
    delete topp;
    delete contextp;
}

extern "C" {

    DLL_EXPORT void cpuLoopInit() {
        if (!run_flag) {
            std::thread cpu_thread(cpu_loop);
            cpu_thread.detach();
            run_flag = 1;
        }
    }

    DLL_EXPORT void setInput(char* input, int size) {
        int len = size > SIG_SIZE ? SIG_SIZE : size;
        std::lock_guard<std::mutex> lock(mtx); 
        memcpy((void*)input_sig, input, len);
        // topp->input_sig = (*(QData*)input_sig);
        // topp->eval();
        // contextp->timeInc(1);
    }

    DLL_EXPORT void getOutput(char* output, int size) {
        int len = size > SIG_SIZE ? SIG_SIZE : size;
        std::lock_guard<std::mutex> lock(mtx); 
        memcpy(output, (void*)output_sig, len);
    }

    DLL_EXPORT void cpuLoopStop() {
        run_flag = 0;
    }

    DLL_EXPORT void nanoSleep(int ns) {
        struct timespec ns_sleep;
        ns_sleep.tv_sec = 0;
        ns_sleep.tv_nsec = ns;
        nanosleep(&ns_sleep,NULL);
    }
}