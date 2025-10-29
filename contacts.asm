;==== DATA ===========================================================
section .data
	;prompts, messages, and menu options
	intro db "==============================================", 10,"========== Contact Directory System ==========", 10, "==============================================", 10, 0
	main_menu_opt db 10, "===== Main Menu =====", 10, "[1] Add Contact", 10, "[2] Delete Contact", 10, "[3] Search", 10, "[4] Display All", 10, "[5] Display By Letter", 10, "[0] Exit Program", 10, 0
	delete_menu_opt db "[1] Delete by Name", 10, "[2] Delete by Number", 10, "[0] Return to Main Menu", 10, 0
	search_menu_opt db "[1] Search by Name", 10, "[2] Search by Number", 10, "[0] Return to Main Menu", 10, 0
	display_letter_prompt db "Enter the starting letter: ", 0
	prompt_choice db "Enter your choice: ", 0
	invalid_choice db "Invalid choice. Please try again.", 10, 0
	thank_you_msg db "Thank you for using the Contact Directory System!", 10, 0
	prompt_name db "Enter contact name: ", 0
	prompt_number db "Enter contact number: ", 0
	no_contacts_msg db "No contacts available.", 10, 0

	;formats for scanf and printf
	fmt_choice db "%d", 0
	fmt_namenum db "%s", 0
	confirm_added db "Contact added successfully: %s", 10, 0
	fmt_display_contact db "Contact %d: %s, %s", 10, 0

	;constants
	NAME_SIZE equ 32
	NUMBER_SIZE equ 11
	RECORD_SIZE equ (NAME_SIZE + NUMBER_SIZE)
	MAX_CONTACTS equ 100

;==== BSS ===========================================================
section .bss
	contacts resb (RECORD_SIZE * MAX_CONTACTS)
	contact_count resd 1
	input_name resb NAME_SIZE
	input_number resb NUMBER_SIZE
	choice resd 1

;==== TEXT ===========================================================
section .text
	global _main
	extern _printf, _scanf

%macro GET_CONTACT_ADDR 2
	; %1 = index (register), %2 = output register (edi/esi/etc)
	mov eax, %1
	mul RECORD_SIZE
	mov %2, contacts
	add %2, eax
%endmacro

;--- add contact --------------
add_contact:
	; prompt name
	push prompt_name
	call _printf
	add esp, 4

	push input_name
	push fmt_namenum
	call _scanf
	add esp, 8

	; prompt phone
	push prompt_number
	call _printf
	add esp, 4

	push input_number
	push fmt_namenum
	call _scanf
	add esp, 8

	; copy into contacts array
	mov eax, [contact_count]       ; index
	cmp eax, MAX_CONTACTS
	jae main_menu                  ; directory full, skip

	mov ecx, eax
	imul ecx, RECORD_SIZE
	mov edi, contacts
	add edi, ecx                   ; edi = record_ptr

	; copy name
	mov esi, input_name
	mov ecx, NAME_SIZE
.copy_name:
	lodsb
	stosb
	loop .copy_name

	; copy phone
	mov esi, input_number
	mov ecx, NUMBER_SIZE
.copy_phone:
	lodsb
	stosb
	loop .copy_phone

	; increment count
	mov eax, [contact_count]
	inc eax
	mov [contact_count], eax

	; confirm
	push input_name
	push confirm_added
	call _printf
	add esp, 12

	jmp main_menu
	
;--- display all contacts --------------
display_all_contacts:
    mov eax, [contact_count]
    cmp eax, 0
    je main_menu

    mov ebx, 0
.display_loop:
    cmp ebx, [contact_count]
    jge main_menu

    ; compute record_ptr
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    ; name = esi
    mov edx, esi
    add esi, NAME_SIZE
    ; phone = esi

    push esi
    push edx
    push ebx
    push fmt_display_contact
    call _printf
    add esp, 16

    inc ebx
    jmp .display_loop

	jmp main_menu




;--- main program loop --------------
_main:
	;initialize contact count to 0
	mov dword [contact_count], 0

	push intro
	call _printf
	add esp, 4

	main_menu:
		;display main menu
		push main_menu_opt
		call _printf
		add esp, 4
		push prompt_choice
		call _printf
		add esp, 4
		push choice
		push fmt_choice
		call _scanf
		add esp, 8

		mov eax, [choice]
		cmp eax, 0
			je exit_program
		cmp eax, 1
			je add_contact
		cmp eax, 2
			je delete_menu
		cmp eax, 3
			je search_menu
		cmp eax, 4
			je display_all_contacts
		; cmp eax, 5
		; 	je display_contacts_by_letter
		push invalid_choice
		call _printf
		add esp, 4
		jmp main_menu

	;-------------------------
	delete_menu:
		;display delete menu
		push delete_menu_opt
		call _printf
		add esp, 4
		push prompt_choice
		call _printf
		add esp, 4
		push choice
		push fmt_choice
		call _scanf
		add esp, 8

		mov eax, [choice]
		cmp eax, 0
			je main_menu
		; cmp eax, 1
		; 	je delete_by_name
		; cmp eax, 2
		; 	je delete_by_number
		push invalid_choice
		call _printf
		add esp, 4
		jmp delete_menu

	; -------------------------
	search_menu:
		;display search menu
		push search_menu_opt
		call _printf
		add esp, 4
		push prompt_choice
		call _printf
		add esp, 4
		push choice
		push fmt_choice
		call _scanf
		add esp, 8

		mov eax, [choice]
		cmp eax, 0
			je main_menu
		; cmp eax, 1
		; 	je search_by_name
		; cmp eax, 2
		; 	je search_by_number
		push invalid_choice
		call _printf
		add esp, 4
		jmp search_menu

	; -------------------------
	exit_program:
			push thank_you_msg
			call _printf
			add esp, 4
			ret