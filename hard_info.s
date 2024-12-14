  @ For system.apk [ver.1412] 
    .section .data
cpuinfo_file:
    .ascii "/proc/cpuinfo\0"
buildprop_file:
    .ascii "/system/build.prop\0"

read_buf:
    .space 1024             @ Buffer for reading

    .section .text
    .global _start

    .equ SYS_READ,    3     @ system call numbers (ARM EABI)
    .equ SYS_WRITE,   4
    .equ SYS_OPEN,    5
    .equ SYS_CLOSE,   6
    .equ O_RDONLY,    0

_start:
    @ Print header for cpuinfo
    ldr r0, =header_cpuinfo
    bl print_string
    
    @ Open /proc/cpuinfo
    ldr r0, =cpuinfo_file
    mov r1, #O_RDONLY
    mov r7, #SYS_OPEN
    svc #0
    mov r4, r0    @ fd for cpuinfo

    @ Read data from cpuinfo and write to stdout
    ldr r1, =read_buf
    mov r2, #1024
read_cpuinfo:
    mov r0, r4
    mov r7, #SYS_READ
    svc #0
    cmp r0, #0
    ble close_cpuinfo
    mov r5, r0      @ number of bytes read
    mov r0, #1      @ stdout
    ldr r1, =read_buf
    mov r2, r5
    mov r7, #SYS_WRITE
    svc #0
    b read_cpuinfo

close_cpuinfo:
    @ Close the cpuinfo file descriptor
    mov r0, r4
    mov r7, #SYS_CLOSE
    svc #0

    @ Print header for build.prop
    ldr r0, =header_buildprop
    bl print_string

    @ Open /system/build.prop
    ldr r0, =buildprop_file
    mov r1, #O_RDONLY
    mov r7, #SYS_OPEN
    svc #0
    mov r4, r0    @ fd for build.prop

    @ Read data from build.prop and write to stdout
read_buildprop:
    mov r0, r4
    ldr r1, =read_buf
    mov r2, #1024
    mov r7, #SYS_READ
    svc #0
    cmp r0, #0
    ble close_buildprop
    mov r5, r0
    mov r0, #1      @ stdout
    ldr r1, =read_buf
    mov r2, r5
    mov r7, #SYS_WRITE
    svc #0
    b read_buildprop

close_buildprop:
    mov r0, r4
    mov r7, #SYS_CLOSE
    svc #0

    @ Exit program with code 0
    mov r0, #0
    mov r7, #1      @ SYS_EXIT = 1
    svc #0

@---------------------------------------------------------
@ print_string subroutine:
@ Prints a null-terminated string pointed to by r0.
print_string:
    push {r4, r5, lr}
    mov r4, r0        @ r4 = ptr
loop_print:
    ldrb r5, [r4], #1
    cmp r5, #0
    beq end_print
    mov r0, #1        @ stdout
    mov r1, r4, lsl #0
    sub r1, r4, #1    @ adjust pointer back by one since we've incremented r4
    mov r2, #1
    mov r7, #SYS_WRITE
    svc #0
    b loop_print
end_print:
    pop {r4, r5, pc}

    .section .rodata
header_cpuinfo:
    .ascii "\n=== /proc/cpuinfo ===\n"

header_buildprop:
    .ascii "\n=== /system/build.prop ===\n"
