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
.section .text
.global _start
_start:
    li x1, 0x1
    li x2, 0x2
b0:
    add x3, x1, x2
    li x4, 0x3
    # bne x3, x0, b0
    # beq x3, x0, b0
    # beq x3, x0, b1
    # bne x3, x0, b1
    # j b1
    lw x9, 68(x0)
    lw x10, 72(x0)
    li x5, 0x5
    addi x11, x3, 0x1
    # addi x10, x9, 0x1
    li x6, 0x6
    li x7, 0x7
b1:
    li x8, 0x8
    li x12, 12
    li x13, 13
    li x14, 14

d0:
    .rept 10
    .long 0x1
    .endr

.end