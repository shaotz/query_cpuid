; query_cpuid.asm

extern print

section .data
	fmt_plain db "%s",0
	str1 db 'Unable to set ID flag at 21h, cpuid is not available', 0
	
	efmask dd 1 << 21
section .bss
	cpuid_cpuname dq 4 ; db 64

section .text
global _start

checkCpuid:
	pushfd
	pop eax
	pushfd
	xor [dword esp], efmask	
	popfd
	pushfd
	xor eax, [dword esp]
	cmp eax, efmask
	mov eax, 0x1
	jne .end			; ef not changed
	mov eax, 0x0
.end:
	popfd
	ret 


_start:
	call checkCpuid
	cmp eax, 0
	jne .cpuidNotAvailable	
	
	; TODO argument intake
	mov eax, 0x0
	cpuid
	push eax
	call print
	jmp .end
.cpuidNotAvailable:
	push str1
	call print
	mov ebx, 1
.end:
	mov eax, 1
	int 80h

