; query_cpuid.asm

section .data
	str1 db 'Unable to set ID flag at EFLAGS bit 21, cpuid is not available', 10, 0
	len_str1 equ $-str1

	strVMX db 'ECX: VMX bit is '
	len_strVMX equ $-strVMX

	strSet db 'set',10
	len_strSet equ $-strSet

	strNotSet db 'not set',10
	len_strNotSet equ $-strNotSet
	
	strReg db 'EAX','EBX','ECX','EDX'
	strBit db ':bit '
	len_strBit equ $-strBit 
	strIs db ' is '
	len_strIs equ $-strIs
	
	
	
	efmask dd 1 << 21
	vmxmask dd 1 << 5
section .bss
	output_bitIndex resb 4
	cpuid_vendor resb 13
	cpuid_cpuname resb 49

section .text
global _start

print:
	pushad
	
	mov eax, 4
	mov ebx, 1	
	mov edx, [esp+12]
	mov edx, [edx+4]
	mov ecx, [esp+12]
	mov ecx, [ecx+8]
	int 0x80
	
	popad
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
	add esp, 8
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
	add esp, 8
	
.getVMXSupport:
	mov eax, 0x1
	mov ebx, 2
	mov edx, 5
	call testLeafRegBit
	mov eax, 0x1
	mov ebx, 2
	mov edx, 31
	call testLeafRegBit
	jmp .end				; test
	cmp eax, 1
	jne .ifVMXNotSet
.ifVMXSet:
	push strSet
	push len_strSet
	call print
	add esp, 8

	jmp .end
.ifVMXNotSet:
	push strNotSet
	push len_strNotSet
	call print
	add esp, 8

	jmp .end	
.cpuidNotAvailable:
	push str1
	push len_str1
	call print
	add esp, 8
	
	mov ebx, 1
.end:
	mov eax, 1
	mov ebx, 0
	int 0x80


testLeafRegBit: 			; eax=Leaf, ebx=Reg, edx=Bit, return is eax = tested bit
	mov esi, ebx
	mov edi, edx

	cmp esi, 3
	ja .end
	cmp esi, 0
	jb .end

	xor ecx, ecx
	cpuid
	
.ifEDX:
	cmp esi, 3 
	jb .ifECX
	mov eax, edx
	jmp .endRegIf 
.ifECX:
	cmp esi, 2 
	jb .ifEBX
	mov eax, ecx
	jmp .endRegIf
.ifEBX:
	cmp esi, 1
	jb .ifEAX
	mov eax, ebx
.ifEAX:
.endRegIf:	
	push eax		
	push edi
	
	mov eax, esi
	mov ebx, 3
	xor edx, edx 				; mul operates on EDX:EAX as well
	mul ebx
	
	lea edx, [strReg + eax]
	push edx
	push 3
	call print
	add esp, 8
	
	push strBit
	push len_strBit
	call print
	add esp, 8
	
.calcBit:			
	mov eax, edi
	
	lea edi, [output_bitIndex]		
	xor edx, edx				; div operates on EDX:EAX	
	mov ebx, 10	
	div ebx
	add edx, 48
	mov byte [edi+1], dl			; to write in reversed order, must take care of data length
	
	xor edx, edx
	div ebx
	add edx, 48
	mov byte [edi], dl			; use BYTE with 8-bit register to not override adjacent

	push edi
	push 2
	call print
	add esp, 8

	push strIs
	push len_strIs
	call print
	add esp, 8
	
	pop edi
	pop eax
	bt eax, edi	
	jc .bitSet
.bitNotSet:
	push strNotSet
	push len_strNotSet
	call print
	add esp, 8

	mov eax, 0
	jmp .end	
.bitSet:
	push strSet
	push len_strSet
	call print
	mov eax, 1
	add esp, 8
.end:	
	ret	
	
	
