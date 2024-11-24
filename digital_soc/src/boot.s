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
    li t0, 0x7
    li t1, 0xC0000000
    sw t0, 0(t1)
    li t0, 0x7
    sw t0, 4(t1)
    li a1, 1
    li a2, 2
    li a3, 3
    li a4, 4
    li a5, 5
    li a6, 6
    li a7, 7
    li s0, 8
    li s1, 9
    li s2, 10
    li s3, 11
    li s4, 12
    li s5, 13
    li s6, 14
    li s7, 15
    li t2, 16
    li t3, 17
loop:
    nop
    j loop

d0:
    .rept 10
    .long 0x1
    .endr

.end
