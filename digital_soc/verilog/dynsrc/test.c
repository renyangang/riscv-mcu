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