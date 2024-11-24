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
    # cust flag set instruction code
    .insn 0x8000007F
    # close interrupts
    csrrw t0,mstatus,zero
    # ssd base address
    li t1, 0x40000000
    # offset
    li t2, 0x2000000
    # total 4096 bytes
    li t3, 0x2003000

 load:
    lbu a1, 0(t1)
    sb a1, 0(t2)
    addi t1, t1, 1
    addi t2, t2, 1
    bltu t2, t3, load
    # set boot status
    li t1, 0xC0000100
    csrrw t2,misa, t1
    csrrw t2,mvendorid,zero
    csrrw t2,marchid,zero
    csrrw t2,mimpid,zero
    csrrw t2,mhartid,zero
    csrrw t2,mtvec,zero
    csrrw t2,mepc,zero
    csrrw t2,mcause,zero
    csrrw t2,mtval,zero
    csrrw t2,mip,zero
    csrrw t2,mie,zero
    li t3,0x1808
    csrrw t2,mstatus,t3
    # clear all registers
    li t0, 0
    li t1, 0
    li t2, 0
    li t3, 0
    li t4, 0
    li a1, 0

    # jump to start
    call 0x2000000
