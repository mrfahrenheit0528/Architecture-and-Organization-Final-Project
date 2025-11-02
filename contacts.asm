;==== DATA ===========================================================
section .data
	;prompts, messages, and menu options
	intro db "==============================================", 10,"========== Contact Directory System ==========", 10, "==============================================", 10, 0
	main_menu_opt db 10, "======== MAIN MENU ========", 10, "[1] Add Contact", 10, "[2] Delete Contact", 10, "[3] Search", 10, "[4] Display All", 10, "[5] Display By Letter", 10, "[0] Exit Program", 10, 0

    delete_menu_opt db "[1] Delete by Name", 10, "[2] Delete by Number", 10, "[0] Return to Main Menu", 10, 0
	search_menu_opt db "[1] Search by Name", 10, "[2] Search by Number", 10, "[0] Return to Main Menu", 10, 0

    ; HEADERS
    add_hdr db 10, "++++++++++ ADD Contact ++++++++++", 10, 0
    delete_hdr db 10, "---------- DELETE Contact ----------", 10, 0
    search_hdr db 10, "~~~~~~~~~~ SEARCH Contact ~~~~~~~~~~", 10, 0
    display_hdr db 10, "********** Contact List **********", 10, 0

    ; PROMPTS
    prompt_choice db 10, "Enter your choice: ", 0
    prompt_name db "Enter contact name: ", 0
	prompt_number db "Enter contact number: ", 0
    display_letter_prompt db "Enter the starting letter: ", 0

    ; SUCCESS & ERROR messages
    ; For when input format is invalid (not int)
    inputFormatInvalid db 10, "Invalid input format. Please enter a valid integer.", 10, 0

    ; For when choice number is not 0-5
    inputChoiceInvalid db 10, "The entered choice is not on the menu. Please enter a valid choice.", 10, 0

    ; For adding
    confirm_added db 10, "Contact ADDED successfully: %s", 10, 0

    ; For deletion
    confirm_deleted db 10, "Contact DELETED successfully: %s", 10, 0
    contact_not_found db 10, "Contact not found.", 10, 0

    ; For when there's no records in contact to display
	no_contacts_msg db 10, "No contacts available.", 10, 0

    ; For exiting
    thank_you_msg db 10, "Thank you for using the Contact Directory System!", 10, 0

	; formats for scanf and printf
	fmt_choice db "%d", 0
	fmt_namenum db "%s", 0
	fmt_display_contact db "----------------------------------", 10, "Contact %d: %s, %s", 10, "----------------------------------", 10, 0
    char_fmt db "%c", 0

	; constants
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

    clear_buffer resb 1     ; single char buffer for input clearing

;==== TEXT ===========================================================
section .text
	global _main
	extern _printf, _scanf

; ==== ADD FUNCTIONS ====

;--- add contact --------------
add_contact:
    ; print header
    push add_hdr
    call _printf
    add esp, 4

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

; ===== DELETE FUNCTIONS =====

; ----- delete_by_name -----
delete_by_name:
    ; check if there are any contacts
    mov eax, [contact_count]
    cmp eax, 0
    je no_contacts

    ; prompt for name to delete
    push prompt_name
    call _printf
    add esp, 4

    push input_name
    push fmt_namenum
    call _scanf
    add esp, 8

    ; search for contact by name
    mov ebx, 0      ; index counter

search_name_loop:
    cmp ebx, [contact_count]
    jge not_found              ; reached end of list, didn't find contact

    ; compute record_ptr
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx                ; ESI = current record_ptr

    ; compare names
    push NAME_SIZE          ; size param
    push esi                ; record name
    push input_name         ; input name
    call compare_str
    add esp, 12

    cmp eax, 0              ; check if names match
    je .name_found          ; if yes, delete contact

    inc ebx                 ; increment
    jmp search_name_loop

; add flags: 0 for deleting name
.name_found:
    push 0
    jmp contact_found

; ----- delete_by_number -----
delete_by_number:
    ; check if there are any contacts
    mov eax, [contact_count]
    cmp eax, 0
    je no_contacts

    ; prompt for number to delete
    push prompt_number
    call _printf
    add esp, 4

    push input_number
    push fmt_namenum
    call _scanf
    add esp, 8

    ; search for contact by name
    mov ebx, 0      ; index counter

search_num_loop:
    cmp ebx, [contact_count]
    jge not_found              ; reached end of list, didn't find contact

    ; compute record_ptr
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx                ; ESI = current record_ptr
    add esi, NAME_SIZE          ; skip name to get num

    ; compare number
    push NUMBER_SIZE        ; size param
    push esi                ; record number
    push input_number       ; input number
    call compare_str
    add esp, 12

    cmp eax, 0              ; check if names match
    je .num_found           ; if yes, display success msg

    inc ebx                 ; increment
    jmp search_num_loop

; add flags: 1 for deleting number
.num_found:
    push 1
    jmp contact_found

; === Deletion subroutines ===
contact_found:
    ; get address of string to print
    pop eax         ; flag (0 = name, 1 = number)
    push eax        ; save flag on stack for later

    mov eax, [contact_count]
    dec eax
    cmp ebx, eax            ; check if last contact
    je last_contact         ; if last contact, decrement count

    ; shift all subsequent contacts down by one position
    ; calculate source pointer
    mov ecx, ebx
    inc ecx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx            ; update record_ptr

    ; calculate destination pointer
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov edi, contacts
    add edi, ecx            ; EDI = pointer to current record (destination)

    ; calculate bytes to move
    mov eax, [contact_count]
    sub eax, ebx
    dec eax                     ; number of records to shift
    imul eax, RECORD_SIZE       ; convert to bytes
    mov ecx, eax

shift_loop:
    cmp ecx, 0
    jle last_contact

    movsb
    dec ecx
    jmp shift_loop

last_contact:
    ; decrement contact count
    mov eax, [contact_count]
    dec eax
    mov [contact_count], eax

    ; print success msg
    pop eax                 ; retrieve flag

    ; check flag
    cmp eax, 0             ; check if flag is 0
    jne .print_number      ; if not, print number

    ; else: flag == 0, print name
    push input_name
    push confirm_deleted
    call _printf
    add esp, 8

    jmp delete_menu

.print_number:
    push input_number
    push confirm_deleted
    call _printf
    add esp, 8

    jmp delete_menu

not_found:
    push contact_not_found
    call _printf
    add esp, 4

    jmp delete_menu

no_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4

    jmp delete_menu

; ---- helper function: compare two strings ----
compare_str:
    ; save registers
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov esi, [ebp+8]    ; access first str (input_name)
    mov edi, [ebp+12]   ; access second str (record name)
    mov ecx, [ebp+16]   ; access size parameters to get maximum chars to compare

.compare_loop:
    lodsb               ; load byte from ESI into AL, increment ESI

    mov dl, [edi]       ; load byte from EDI into DL
    cmp al, dl          ; compare chars
    jne .not_match      ; if different, str don't match

    cmp al, 0           ; check if null terminator reached
    je .is_match        ; if yes, str match

    inc edi
    dec ecx

    jnz .compare_loop   ; continue if ecx != 0

.is_match:
    mov eax, 0      ; return 0
    jmp .cmprdone

.not_match:
    mov eax, 1      ; return 1

.cmprdone:
    pop edi
    pop esi
    pop ebp

    ret


; ===== SEARCH FUNCTIONS =====
; ----- search_by_name -----

; ----- search_by_number -----






; ===== DISPLAY FUNCTIONS =====
; ----- display all contacts -----
display_all_contacts:
    ; print header
    push display_hdr
    call _printf
    add esp, 4

    mov eax, [contact_count]

    cmp eax, 0              ; check if there are contacts in record
    je .no_dp_contacts      ; if not, display no contacts msg

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

.no_dp_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4

    jmp main_menu

; ----- display_contacts_by_letter -----






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

        cmp eax,  1              ; check if scanf read one input
        jne raiseChoiceNotInt    ; if not, raise error msg

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

        push inputChoiceInvalid
		call _printf
		add esp, 4

		jmp main_menu

	;-------------------------
	delete_menu:
        ; print header
        push delete_hdr
        call _printf
        add esp, 4

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

        cmp eax,  1              ; check if scanf read one input
        jne raiseChoiceNotInt    ; if not, raise error msg

		mov eax, [choice]
		cmp eax, 0
			je main_menu
		cmp eax, 1
		 	je delete_by_name
		cmp eax, 2
		 	je delete_by_number

		push inputChoiceInvalid
		call _printf
		add esp, 4
		jmp delete_menu

	; -------------------------
	search_menu:
        ; print header
        push search_hdr
        call _printf
        add esp, 4

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

        cmp eax,  1              ; check if scanf read one input
        jne raiseChoiceNotInt    ; if not, raise error msg

		mov eax, [choice]
		cmp eax, 0
			je main_menu
		; cmp eax, 1
		; 	je search_by_name
		; cmp eax, 2
		; 	je search_by_number

        push inputChoiceInvalid
		call _printf
		add esp, 4
		jmp search_menu

	; -------------------------
	exit_program:
			push thank_you_msg
			call _printf
			add esp, 4
			ret

; ===== VALIDATIONS ======
raiseChoiceNotInt:
    ; Error handling for when input not int
    call clear_input_buffer     ; clear residual input

    push inputFormatInvalid           ; push error message
    call _printf                ; display error
    add esp, 4                  ; clean stack

    jmp main_menu              ; return to main menu

; Clear input buffer function
clear_input_buffer:
    ; clears stdin buffer by reading characters until newline
    push eax            ; Save EAX register

.clear_buffer_loop:
    ; Read one char at a time
    push clear_buffer       ; push address of buffer
    push char_fmt           ; push format string
    call _scanf             ; read one char
    add esp, 8              ; clean stack

    mov al, [clear_buffer]  ; load char into AL
    cmp al, 10              ; check if newline
    jne .clear_buffer_loop   ; if not, continue

    pop eax         ; restore EAX
    ret             ; return to caller
