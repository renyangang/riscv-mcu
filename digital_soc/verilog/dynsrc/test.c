extern void setInput(char* input, int size);
extern void getOutput(char* output, int size);
extern void cpuLoopInit();
void cpuLoopStop();

#include <stdio.h>
#include <unistd.h>

int main() {
    cpuLoopInit();
    char input[4] = {0};
    char output[20] = {0};
    char in[4] = {0xef,0x00,0x00,0x00};
    char flag = 0;
    int pos = 0;
    setInput(input, 4);
    usleep(100);
    input[0] = 2;
    int ins;
    for(int i = 0; i < 100; i++) {
        if(flag) {
            if((*(int*)output) > 0) {
                ins = 7;
                
            }else{
                ins = ((0xFF & in[0]) << 3) + 7;
            }
            memcpy(input,&ins,4);
            flag = 0;
        }else{
            if((*(int*)output) > 0) {
                ins = 2;
                
            }else{
                ins = ((0xFF & in[0]) << 3) + 2;
            }
            memcpy(input,&ins,4);
            flag = 1;
        }
        setInput(input, 4);
        getOutput(output, 20);
        printf("output: 0x%X\n",*(int*)output);
        // printf("output1: 0x%X\n",*(int*)&output[4]);
        usleep(1000);
    }

    cpuLoopStop();
}