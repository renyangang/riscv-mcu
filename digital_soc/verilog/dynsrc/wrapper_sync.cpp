#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif
#include "verilated.h"
#include "Vdigital_soc_top.h"
#include <thread>

#define SIG_SIZE 128

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
    
    // Simulate until $finish
    // while (!contextp->gotFinish() && run_flag) {
    //     // Evaluate model
    //     topp->input_sig = (*(QData*)input_sig);
    //     topp->eval();
    //     int pos = 0;
    //     memcpy((void*)output_sig, (char*)&(topp->output_sig.m_storage[0]), sizeof(EData)*topp->output_sig.Words);
    //     // Advance time
    //     contextp->timeInc(1);
    //     usleep(1);
    // }

    // if (!contextp->gotFinish()) {
    //     VL_DEBUG_IF(VL_PRINTF("+ Exiting without $finish; no events left\n"););
    // }

    // Execute 'final' processes
    // topp->final();
    // contextp->statsPrintSummary();
    // delete topp;
    // delete contextp;
}

extern "C" {

    DLL_EXPORT void cpuLoopInit() {
        // std::thread cpu_thread(cpu_loop);
        // cpu_thread.detach();
        if (!run_flag) {
            cpu_loop();
            run_flag = 1;
        }
    }

    DLL_EXPORT void setInput(char* input, int size) {
        cpuLoopInit();
        int len = size > SIG_SIZE ? SIG_SIZE : size;
        memcpy((void*)input_sig, input, len);
        topp->input_sig = (*(QData*)input_sig);
        topp->eval();
        memcpy((void*)output_sig, (char*)&(topp->output_sig.m_storage[0]), sizeof(EData)*topp->output_sig.Words);
        // Advance time
        contextp->timeInc(1);
    }

    DLL_EXPORT void getOutput(char* output, int size) {
        cpuLoopInit();
        topp->input_sig = (*(QData*)input_sig);
        topp->eval(); 
        memcpy((void*)output_sig, (char*)&(topp->output_sig.m_storage[0]), sizeof(EData)*topp->output_sig.Words);
        // Advance time
        contextp->timeInc(1);
        int len = size > SIG_SIZE ? SIG_SIZE : size;
        memcpy(output, (void*)output_sig, len);
    }

    DLL_EXPORT void cpuLoopStop() {
        topp->final();
        contextp->statsPrintSummary();
        delete topp;
        delete contextp;
        run_flag = 0;
    }
}