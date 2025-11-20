;==== DATA ===========================================================
section .data
	;prompts, messages, and menu options
	intro db "==============================================", 10,"========== Contact Directory System ==========", 10, "==============================================", 10, 0
	main_menu_opt db 10, "================= MAIN MENU =================", 10, "[1] Add Contact", 10, "[2] Delete Contact", 10, "[3] Search", 10, "[4] Display All", 10, "[5] Display By Letter", 10, "[0] Exit Program", 10, 0

    delete_menu_opt db "[1] Delete by Name", 10, "[2] Delete by Number", 10, "[0] Return to Main Menu", 10, 0
	search_menu_opt db "[1] Search by Name", 10, "[2] Search by Number", 10, "[0] Return to Main Menu", 10, 0

    ; HEADERS
    add_hdr db 10, "++++++++++++++++ ADD Contact ++++++++++++++++", 10, 0
    delete_hdr db 10, "--------------- DELETE Contact ---------------", 10, 0
    search_hdr db 10, "~~~~~~~~~~~~~~~ SEARCH Contact ~~~~~~~~~~~~~~~", 10, 0
    display_hdr db 10, "*************** Contact List ****************", 10, 0

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

    ; Error messages
    name_invalid_chars db 10, "Error: Name must only contain letters and spaces.", 10, 10, 0
    name_too_long db 10, "Error: Name is too long (Max 31 characters).", 10, 10, 0

    num_invalid_chars db 10, "Error: Number must only contain digits (0-9).", 10, 10, 0
    num_invalid_len db 10, "Error: Number must be exactly 10 digits long.", 10, 10, 0

    ; For exiting
    thank_you_msg db 10, "Thank you for using the Contact Directory System!", 10, 0

	; formats for scanf and printf
	fmt_choice db "%d", 0
	fmt_namenum db "%s", 0

	fmt_display_contact db "----------------------------------------------", 10, "Contact %d: %s, %s", 10, "----------------------------------------------", 10, 0
    char_fmt db "%c", 0

	; constants
	NAME_SIZE equ 32
	NUMBER_SIZE equ 12
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
	extern _printf, _scanf, _exit

; === VALIDATION SUBROUTINES ===
; ---- helper function: validate name ----
validate_name:
    push ebp
    mov ebp, esp
    push esi
    push ecx
    push edx

    mov esi, [ebp+8]    ; address of string
    mov ecx, 0          ; char counter

.name_char_loop:
    movzx edx, byte [esi+ecx]   ; load current char

    cmp edx, 0
    je .name_check_length   ; null terminator

    cmp ecx, NAME_SIZE - 1      ; check if length  (NAME_SIZE = 32, max 31 chars + null)
    jge .name_invalid

    cmp edx, 'A'
    jl .check_lower

    cmp edx, 'Z'
    jle .name_continue

.check_lower:
    cmp edx, 'a'
    jl .check_space

    cmp edx, 'z'
    jle .name_continue

.check_space:
    cmp edx, ' '
    je .name_continue

    jmp .name_invalid

.name_continue:
    inc ecx
    jmp .name_char_loop

.name_check_length:
    cmp ecx, 0
    je .name_invalid

    mov eax, 0
    jmp .name_done

.name_invalid:
    mov eax, 1

.name_done:
    pop edx
    pop ecx
    pop esi
    pop ebp
    ret

; ---- helper function: validate name ----
validate_num:
    push ebp
    mov ebp, esp
    push esi
    push ecx
    push edx

    mov esi, [ebp+8]
    mov ecx, 0

.num_char_loop:
    movzx edx, byte [esi+ecx]

    cmp edx, 0
    je .num_check_length

    cmp edx, '0'
    jl .num_invalid_char

    cmp edx, '9'
    jg .num_invalid_char

    inc ecx

    cmp ecx, NUMBER_SIZE - 1
    jg .num_too_long

    jmp .num_char_loop

.num_invalid_char:
    mov eax, 1
    jmp .num_done

.num_too_long:
    mov eax, 2
    jmp .num_done

.num_check_length:
    cmp ecx, NUMBER_SIZE - 1
    jne .num_invalid_length

    mov eax, 0
    jmp .num_done

.num_invalid_length:
    mov eax, 2

.num_done:
    pop edx
    pop ecx
    pop esi
    pop ebp
    ret

; ==== ADD FUNCTIONS ====

;--- add contact --------------
add_contact:
    ; print header
    push add_hdr
    call _printf
    add esp, 4

.prompt_name_loop:
	; prompt name
	push prompt_name
	call _printf
	add esp, 4

    call clear_input_buffer

	push input_name
	push fmt_namenum
	call _scanf
	add esp, 8

    push input_name
    call validate_name
    add esp, 4

    cmp eax, 0
    jne .name_validation_failed

    jmp .prompt_number_loop

.name_validation_failed:
    push name_invalid_chars
    call _printf
    add esp, 4
    jmp .prompt_name_loop

.prompt_number_loop:
	; prompt phone
	push prompt_number
	call _printf
	add esp, 4

    call clear_input_buffer

	push input_number
	push fmt_namenum
	call _scanf
	add esp, 8

    push input_number
    call validate_num
    add esp, 4

    cmp eax, 0
    je .copy_contact

    cmp eax, 1
    je .raiseInvalidChar

    jmp .raiseInvalidLen

.raiseInvalidChar:
    push num_invalid_chars
    call _printf
    add esp, 4

    jmp .prompt_number_loop

.raiseInvalidLen:
    push num_invalid_len
    call _printf
    add esp, 4

    jmp .prompt_number_loop

.copy_contact:

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
search_by_name:
    ; check if there are any contacts
    mov eax, [contact_count]
    cmp eax, 0
    je .no_contacts

    ; prompt for name
    push prompt_name
    call _printf
    add esp, 4

    push input_name
    push fmt_namenum
    call _scanf
    add esp, 8

    mov ebx, 0  ; index counter

.name_search_loop:
    cmp ebx, [contact_count]
    jge .not_found          ; reached end of list

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx            ; current record ptr

    push NAME_SIZE
    push esi
    push input_name
    call compare_str
    add esp, 12

    cmp eax, 0
    je .found

    inc ebx
    jmp .name_search_loop

.found:
    push display_hdr
    call _printf
    add esp, 4

    ; compute record ptr again to display
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    mov edx, esi
    add esi, NAME_SIZE

    push esi
    push edx
    push ebx
    push fmt_display_contact
    call _printf
    add esp, 16

    jmp search_menu

.not_found:
    push contact_not_found
    call _printf
    add esp, 4
    jmp search_menu

.no_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4
    jmp search_menu


; ----- search_by_number -----
search_by_number:
    ; check if there are any contacts
    mov eax, [contact_count]
    cmp eax, 0
    je .no_contacts

    ; prompt for number
    push prompt_number
    call _printf
    add esp, 4

    push input_number
    push fmt_namenum
    call _scanf
    add esp, 8

    mov ebx, 0  ; index counter

.num_search_loop:
    cmp ebx, [contact_count]
    jge .not_found          ; reached end of list

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    add esi, NAME_SIZE      ; skip name to get to number

    push NUMBER_SIZE
    push esi
    push input_number
    call compare_str
    add esp, 12

    cmp eax, 0
    je .found

    inc ebx
    jmp .num_search_loop

.found:
    push display_hdr
    call _printf
    add esp, 4

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    mov edx, esi
    add esi, NAME_SIZE

    push esi
    push edx
    push ebx
    push fmt_display_contact
    call _printf
    add esp, 16

    jmp search_menu

.not_found:
    push contact_not_found
    call _printf
    add esp, 4
    jmp search_menu

.no_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4
    jmp search_menu





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
display_contacts_by_letter:
    push display_hdr
    call _printf
    add esp, 4

    push display_letter_prompt
    call _printf
    add esp, 4

    call clear_input_buffer

    push clear_buffer
    push char_fmt
    call _scanf
    add esp, 8

    mov al, [clear_buffer]    ; letter to search
    mov bl, al                ; save letter in bl

    mov esi, 0                ; contact index
    mov edi, 0                ; byte offset in contacts

    mov eax, [contact_count]
    cmp eax, 0
    je .no_contacts_letter

.loop_letter:
    cmp esi, [contact_count]
    jge .end_letter

    mov edx, contacts
    add edx, edi              ; pointer to current record
    mov al, [edx]             ; first char of name
    cmp al, bl
    jne .skip_letter

    lea ecx, [edx + NAME_SIZE] ; pointer to number

    push ecx                   ; number
    push edx                   ; name
    push esi                   ; contact index
    push fmt_display_contact
    call _printf
    add esp, 16

.skip_letter:
    inc esi
    add edi, RECORD_SIZE
    jmp .loop_letter

.end_letter:
    jmp main_menu

.no_contacts_letter:
    push no_contacts_msg
    call _printf
    add esp, 4
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

        push main_menu
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
		cmp eax, 5
		 	je display_contacts_by_letter

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

        push search_menu
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
		 	je search_by_name
		cmp eax, 2
		 	je search_by_number

        push inputChoiceInvalid
		call _printf
		add esp, 4
		jmp search_menu

	; -------------------------
	exit_program:
		push thank_you_msg
		call _printf
		add esp, 4

    push 0
    call _exit

; ===== VALIDATIONS ======
raiseChoiceNotInt:
    push ebp
    mov ebp, esp

    ; Error handling for when input not int
    call clear_input_buffer     ; clear residual input

    ; Display error message
    push inputFormatInvalid           ; push error message
    call _printf                ; display error
    add esp, 4                  ; clean stack

    ; Retrieve return address from stack
    mov ebx, [ebp+8]

    pop ebp
    jmp ebx

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
