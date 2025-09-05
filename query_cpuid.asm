; query_cpuid.asm

section .data
	str1 db 'Unable to set ID flag at EFLAGS bit 21, cpuid is not available', 10, 0
	len_str1 equ $-str1
	strVMX db 'ecx: VMX bit is '
	len_strVMX equ $-strVMX
	strSet db 'set',10
	len_strSet equ $-strSet
	strNotSet db 'not set',10
	len_strNotSet equ $-strNotSet
	
	efmask dd 1 << 21
	vmxmask dd 1 << 5
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
	mov edx, [ebp+8]
	mov ecx, [ebp+12]
	int 0x80
	
	pop ebp
	ret

checkCpuid:
	pushfd
	pop eax
	pushfd
	mov ebx, [efmask]
	xor [esp], ebx	
	popfd
	pushfd
	xor eax, dword [esp]
	xor eax, ebx
	cmp eax, 0
	mov eax, 0x1
	jne .end				; ef not changed
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
	mov esi, 0x80000002 			; using esi to keep leaf counter
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
.getVMXSupport:
	xor ecx, ecx
	mov eax, 0x1
	cpuid
	mov ebx, [vmxmask]
	and ecx, ebx
	xor ecx, ebx
	cmp ecx, 0x0
	push strVMX
	push len_strVMX
	call print

	jne .ifVMXNotSet
.ifVMXSet:
	push strSet
	push len_strSet
	call print
	jmp .end
.ifVMXNotSet:
	push strNotSet
	push len_strNotSet
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

