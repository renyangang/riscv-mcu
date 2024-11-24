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
.section .starttext
.global _start
.global set_mie
_start:
    # set sp
    li sp, 0x3f000000
    # register interrupts handler
    la a5,int_handler
    addi a5,a5, 0x1
    csrrw t2,mtvec,a5
    # open interrupts
    li t3,0x1808
    csrrw t2,mstatus,t3
    # goto c main
    call main

.section .exceptiontext
int_handler:
    j inner_exception_handler
mret_pos:
    mret


.section .softinttext
soft_handler:
    j inner_soft_handler

.section .timerinttext
timer_handler:
    j inner_timer_handler

.section .peripheralinttext
peripheral_handler:
    add	sp,sp,-4
    sw	ra,0(sp)
    call save_regs
    call int_peripheral_handler
    call restore_regs
    lw	ra,0(sp)
    addi	sp,sp,4
    mret

.section .text
set_mie:
    add	sp,sp,-4
    sw	ra,0(sp)
    csrrw t2,mie,a0
    lw	ra,0(sp)
    addi	sp,sp,4
    ret

save_regs:
    addi sp, sp, -36
    sw a2, 0(sp)
    sw a3, 4(sp)
    sw a4, 8(sp)
    sw a5, 12(sp)
    sw a6, 16(sp)
    sw a7, 20(sp)
    sw a0, 24(sp)
    sw a1, 28(sp)
    ret

restore_regs:
    lw a2, 0(sp)
    lw a3, 4(sp)
    lw a4, 8(sp)
    lw a5, 12(sp)
    lw a6, 16(sp)
    lw a7, 20(sp)
    lw a0, 24(sp)
    lw a1, 28(sp)
    addi sp, sp, 36
    ret

inner_soft_handler:
    add	sp,sp,-4
    sw	ra,0(sp)
    call save_regs
    call int_soft_handler
    call restore_regs
    lw	ra,0(sp)
    addi	sp,sp,4
    j mret_pos

inner_timer_handler:
    add	sp,sp,-4
    sw	ra,0(sp)
    call save_regs
    call int_timer_handler
    call restore_regs
    lw	ra,0(sp)
    addi	sp,sp,4
    j mret_pos

inner_exception_handler:
    add	sp,sp,-4
    sw	ra,0(sp)
    call save_regs
    call exception_handler
    call restore_regs
    lw	ra,0(sp)
    addi	sp,sp,4
    j mret_pos