; query_cpuid.asm

extern print

section .data
	fmt_plain db "%s",0
	str1 db 'Unable to set ID flag at 21h',' cpuid is not available', 10, 0
	len_str1 equ $-str1
	
	efmask dd 1 << 21
	counter dd 0x80000002
section .bss
	cpuid_vendor resb 13
	cpuid_cpuname resb 49

section .text
global _start

print:
	push ebp
	mov ebp, esp

	mov eax, 4
	mov ebx, 1	
	mov edx, [esp+8]
	mov ecx, [esp+12]
	int 0x80
	
	mov esp, ebp
	pop ebp
	ret
checkCpuid:
	pushfd
	pop eax
	pushfd
	xor dword [esp], efmask	
	popfd
	pushfd
	and eax, dword [esp]
	and eax, efmask
	cmp eax, 0
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
.getVendorStr:
	mov eax, 0x0
	cpuid
	mov edi, cpuid_vendor
	mov [edi], ebx				; order is ebx,edx,ecx
	mov [edi+4], edx	
	mov [edi+8], ecx
	mov byte [edi+12], 10
	push cpuid_vendor
	push 13
	call print
.getNameStr:
	mov eax, 0x80000000 
	cpuid
	cmp eax, 0x80000004
	jb .end
	
	xor edi, edi
	lea edi, [cpuid_cpuname]
	
	xor esi, esi
	mov esi, 0x80000002 ; using esi to keep leaf counter
.getNameStrLoop:
	mov eax, esi
	xor ecx, ecx
	cpuid
	nop
	mov [edi], eax
	mov [edi+4], ebx
	mov [edi+8], ecx
	mov [edi+12], edx
	add edi, 16

	inc esi
	cmp esi, 0x80000005
	jb .getNameStrLoop
		
	mov byte [edi], 10
	push cpuid_cpuname
	push 49
	call print
	jmp .end
.cpuidNotAvailable:
	push str1
	push len_str1
	call print
	mov ebx, 1
.end:
	mov eax, 1
	mov ebx, 0
	int 0x80

