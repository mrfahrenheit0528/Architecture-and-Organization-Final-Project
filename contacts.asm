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
    contact_not_found db 10, "Contact NOT FOUND.", 10, 0

    ; For when there's no records in contact to display
	no_contacts_msg db 10, "No contacts available.", 10, 0

    ; Error messages
    name_invalid_chars db 10, "Error: Name must only contain letters, spaces, and digits.", 10, 10, 0
    num_invalid_chars db 10, "Error: Number must only contain digits (0-9).", 10, 10, 0
    num_invalid_len db 10, "Error: Number must be exactly 11 digits long.", 10, 10, 0
    num_invalid_prefix db 10, "Error: Number must start with 09.", 10, 10, 0
    name_too_long db 10, "Error: Name is too long (Max 31 characters).", 10, 10, 0

    dupli_contact db 10, "Error: Contact already exists.", 10, 0
    dupli_number db 10, "Error: Contact with this number already exists. Please try again.", 10, 10, 0
    dupli_name db 10, "Notice: Contact with this name already exists. Continue? (y/n): ", 0

    ; For exiting
    thank_you_msg db 10, "Thank you for using the Contact Directory System!", 10, 0

	; formats for scanf and printf
	fmt_choice db "%d", 0
	fmt_namenum db "%s", 0
    fmt_name db "%31[a-zA-Z0-9 ]", 0
    fmt_num db "%11s", 0            ; NEW: for numbers (no spaces)

    fmt_display_contact db "----------------------------------------------", 10, "%-31s | %s", 10, 0
    fmt_display_add db "%-31s | %s", 10, 0
    char_fmt db "%c", 0

    choice_format db "[%d] %-31s | %s", 10, 0
    select_number_prompt db "Select number to delete (or 0 to cancel): ", 0
    newline db 10, 0

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
    temp_name resb NAME_SIZE
	choice resd 1
    continue_choice resb 2

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

    ; Check for uppercase letter
    cmp edx, 'A'
    jl .check_lower

    cmp edx, 'Z'
    jle .name_continue

.check_lower:
    ; Check for lowercase letter
    cmp edx, 'a'
    jl .check_digit

    cmp edx, 'z'
    jle .name_continue

.check_digit:
    ; Check for digits
    cmp edx, '0'
    jl .check_space

    cmp edx, '9'
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

    ; check if num starts with 0
    movzx edx, byte [esi]
    cmp edx, '0'
    jne .num_invalid_prefix

    ; check if second char is 9
    movzx edx, byte [esi+1]
    cmp edx, '9'
    jne .num_invalid_prefix

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
    mov eax, 1          ; invalid character
    jmp .num_done

.num_too_long:
    mov eax, 2          ; invalid length
    jmp .num_done

.num_invalid_prefix:
    mov eax, 3          ; invalid prefix
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

; ---- helper function: check for duplciate name ----
; ---- helper function: check for duplicate name ----
check_duplicate_name:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov ebx, 0      ; index counter

.check_dupli_name_loop:
    cmp ebx, [contact_count]
    jge .no_duplicate

    ; Set pointer to current record
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    ; Convert both names to lowercase before comparing
    push temp_name + NAME_SIZE
    push esi
    call to_lowercase
    add esp, 8

    push temp_name
    push input_name
    call to_lowercase
    add esp, 8

    ; Compare lowercase versions
    push NAME_SIZE
    push temp_name + NAME_SIZE
    push temp_name
    call compare_str
    add esp, 12

    cmp eax, 0
    je .is_duplicate

.next_contact:
    inc ebx
    jmp .check_dupli_name_loop

.is_duplicate:
    mov eax, 1
    jmp .check_done

.no_duplicate:
    mov eax, 0

.check_done:
    pop esi
    pop ebx
    pop ebp
    ret

; ---- helper function: check for duplicate number ----
check_duplicate_num:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov ebx, 0      ; index counter

.check_dupli_num_loop:
    cmp ebx, [contact_count]
    jge .no_duplicate

    ; Set pointer to current record
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    add esi, NAME_SIZE      ; skip to number

    ; Compare number
    push NUMBER_SIZE
    push esi
    push input_number
    call compare_str
    add esp, 12

    cmp eax, 0
    je .is_duplicate

.next_contact:
    inc ebx
    jmp .check_dupli_num_loop

.is_duplicate:
    mov eax, 1
    jmp .check_done

.no_duplicate:
    mov eax, 0

.check_done:
    pop esi
    pop ebx
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
	push fmt_name
	call _scanf
	add esp, 8

    ; validate name
    push input_name
    call validate_name
    add esp, 4

    cmp eax, 0
    jne .name_validation_failed

    ; check if name already exists
    call check_duplicate_name
    cmp eax, 1
    je .duplicate_name_found

    ; name is valid, unique, proceed to number
    jmp .prompt_number_loop

.name_validation_failed:
    push name_invalid_chars
    call _printf
    add esp, 4
    jmp .prompt_name_loop

.duplicate_name_found:
    ; ask user if they want to continue
    push dupli_name
    call _printf
    add esp, 4

    ; get user input (y/n)
    call clear_input_buffer

    push continue_choice
    push char_fmt
    call _scanf
    add esp, 8

    ; check response
    mov al, [continue_choice]

    ; check if y or Y
    cmp al, 'Y'
    je .prompt_number_loop
    cmp al, 'y'
    je .prompt_number_loop

    ; user chose not to continue
    jmp main_menu

.prompt_number_loop:
	; prompt phone
	push prompt_number
	call _printf
	add esp, 4

    call clear_input_buffer

	push input_number
	push fmt_num
	call _scanf
	add esp, 8

    ; validate number
    push input_number
    call validate_num
    add esp, 4

    cmp eax, 0
    je .check_duplicate_number

    cmp eax, 1
    je .raiseInvalidChar

    cmp eax, 3
    je .raiseInvalidPrefix

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

.raiseInvalidPrefix:
    push num_invalid_prefix
    call _printf
    add esp, 4
    jmp .prompt_number_loop

.check_duplicate_number:
    ; check if number already exists
    call check_duplicate_num
    cmp eax, 1
    je .duplicate_num_found

    ; no duplicate number, proceed to copy
    jmp .copy_contact

.duplicate_num_found:
    ; reject - number already exists
    push dupli_number
    call _printf
    add esp, 4
    jmp .prompt_number_loop

.copy_contact:
    ; copy into contacts array
    mov eax, [contact_count]
    cmp eax, MAX_CONTACTS
    jae main_menu

    mov ecx, eax
    imul ecx, RECORD_SIZE
    mov edi, contacts
    add edi, ecx

    ; copy name
    mov esi, input_name
    mov ecx, NAME_SIZE

.copy_name:
    lodsb
    stosb
    dec ecx
    jnz .copy_name

    ; copy phone
    mov esi, input_number
    mov ecx, NUMBER_SIZE

.copy_phone:
    lodsb
    stosb
    dec ecx
    jnz .copy_phone

    ; increment count
    mov eax, [contact_count]
    inc eax
    mov [contact_count], eax

    ; confirm
    push input_name
    push confirm_added
    call _printf
    add esp, 8

    jmp main_menu

; ===== DELETE FUNCTIONS =====

delete_by_name:
    ; check if there are any contacts
    mov eax, [contact_count]
    cmp eax, 0
    je no_contacts

    ; prompt for name to delete
    push prompt_name
    call _printf
    add esp, 4

    call clear_input_buffer

    push input_name
    push fmt_name
    call _scanf
    add esp, 8

    ; First pass: count matches and display them
    mov ebx, 0      ; index counter
    mov edi, 0      ; match counter

.count_matches_loop:
    cmp ebx, [contact_count]
    jge .check_matches

    ; compute record_ptr
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    ; compare names (case-insensitive)
    push temp_name + NAME_SIZE
    push esi
    call to_lowercase
    add esp, 8

    push temp_name
    push input_name
    call to_lowercase
    add esp, 8

    push NAME_SIZE
    push temp_name + NAME_SIZE
    push temp_name
    call compare_str
    add esp, 12

    cmp eax, 0
    jne .next_match_check

    ; Found a match
    cmp edi, 0
    jne .not_first_display

    ; First match - display header
    push display_hdr
    call _printf
    add esp, 4

.not_first_display:
    inc edi     ; increment match counter

    ; Display this contact with choice number
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    mov edx, esi
    add esi, NAME_SIZE

    ; Display: [match_number] name | number
    push esi
    push edx
    push edi
    push choice_format      ; "[%d] %-31s | %s\n"
    call _printf
    add esp, 16

.next_match_check:
    inc ebx
    jmp .count_matches_loop

.check_matches:
    cmp edi, 0
    je not_found        ; no matches found

    cmp edi, 1
    je .single_match    ; only one match, delete it directly

    ; Multiple matches - ask user to choose
    push newline
    call _printf
    add esp, 4

    push select_number_prompt   ; "Select number to delete (or 0 to cancel): "
    call _printf
    add esp, 4

    push choice
    push fmt_choice
    call _scanf
    add esp, 8

    mov eax, [choice]

    ; Check if user cancelled
    cmp eax, 0
    je delete_menu

    ; Validate choice
    cmp eax, 1
    jl delete_menu
    cmp eax, edi
    jg delete_menu

    ; Find the nth match and delete it
    mov edi, eax        ; EDI = target match number
    mov ebx, 0          ; contact index
    mov esi, 0          ; current match counter

.find_nth_match:
    cmp ebx, [contact_count]
    jge delete_menu

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov edx, contacts
    add edx, ecx

    ; Compare name
    push temp_name + NAME_SIZE
    push edx
    call to_lowercase
    add esp, 8

    push temp_name
    push input_name
    call to_lowercase
    add esp, 8

    push NAME_SIZE
    push temp_name + NAME_SIZE
    push temp_name
    call compare_str
    add esp, 12

    cmp eax, 0
    jne .next_nth_match

    inc esi             ; increment match counter
    cmp esi, edi        ; is this the nth match?
    je .delete_this_contact

.next_nth_match:
    inc ebx
    jmp .find_nth_match

.single_match:
    ; Only one match - find and delete it
    mov ebx, 0

.find_single_match:
    cmp ebx, [contact_count]
    jge not_found

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    ; Compare name
    push temp_name + NAME_SIZE
    push esi
    call to_lowercase
    add esp, 8

    push temp_name
    push input_name
    call to_lowercase
    add esp, 8

    push NAME_SIZE
    push temp_name + NAME_SIZE
    push temp_name
    call compare_str
    add esp, 12

    cmp eax, 0
    je .delete_this_contact

    inc ebx
    jmp .find_single_match

.delete_this_contact:
    ; Save the number before deletion for confirmation message
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    add esi, NAME_SIZE

    ; Copy number to temp buffer for confirmation message
    mov edi, input_number
    mov ecx, NUMBER_SIZE

.save_number:
    mov edi, input_number
    mov ecx, NUMBER_SIZE

.save_number_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz .save_number_loop

    sub esi, NUMBER_SIZE    ; restore esi to point to number start
    sub esi, NAME_SIZE      ; move back to name start

    ; Now perform deletion (shift records)
    mov eax, [contact_count]
    dec eax
    cmp ebx, eax
    je .last_contact

    ; Shift all subsequent contacts
    mov ecx, ebx
    inc ecx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov edi, contacts
    add edi, ecx

    mov eax, [contact_count]
    sub eax, ebx
    dec eax
    imul eax, RECORD_SIZE
    mov ecx, eax

.shift_loop:
    cmp ecx, 0
    jle .last_contact
    movsb
    dec ecx
    jmp .shift_loop

.last_contact:
    ; Decrement count
    mov eax, [contact_count]
    dec eax
    mov [contact_count], eax

    ; Display confirmation with number
    push input_number
    push confirm_deleted
    call _printf
    add esp, 8

    jmp delete_menu

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
    push fmt_num
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

; ---- helper function: convert string to lowercase ----
to_lowercase:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push eax

    mov esi, [ebp+8]
    mov edi, [ebp+12]

.lower_loop:
    lodsb
    cmp al, 0
    je .lower_done

    cmp al, 'A'
    jl .copy_char
    cmp al, 'Z'
    jg .copy_char

    add al, 32

.copy_char:
    stosb
    jmp .lower_loop

.lower_done:
    mov byte [edi], 0

    pop eax
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

    call clear_input_buffer

    push input_name
    push fmt_name
    call _scanf
    add esp, 8

    ; convert input to lowercase
    push temp_name
    push input_name
    call to_lowercase
    add esp, 8

    mov ebx, 0  ; index counter
    mov edi, 0

.name_search_loop:
    cmp ebx, [contact_count]
    jge .check_found          ; reached end of list

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx            ; current record ptr

    ; convert contact name to lowercase, then compare
    push temp_name + NAME_SIZE
    push esi
    call to_lowercase
    add esp, 8

    push NAME_SIZE
    push temp_name + NAME_SIZE
    push temp_name
    call compare_str
    add esp, 12

    cmp eax, 0
    jne .next_contact

    cmp edi, 0
    jne .not_first_match

    push display_hdr
    call _printf
    add esp, 4

.not_first_match:
    mov edi, 1

    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    mov edx, esi
    add esi, NAME_SIZE

    push esi
    push edx
    push fmt_display_contact
    call _printf
    add esp, 12

.next_contact:
    inc ebx
    jmp .name_search_loop

.check_found:
    cmp edi, 0
    je .not_found
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
    push fmt_num
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

    push esi              ; number
    push edx              ; name
    push fmt_display_contact
    call _printf
    add esp, 12           ; 3 params × 4 bytes = 12

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

; ---- helper function: alphabetically sort contacts for displaying ----
bubble_sort_contacts:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov eax, [contact_count]
    cmp eax, 2
    jl .sort_done       ; no need to sort if 0 or 1

    dec eax
    mov edx, eax        ; outer loop counter (n-1)

.outer_loop:
    cmp edx, 0
    jle .sort_done

    mov ecx, 0          ; inner loop counter

.inner_loop:
    cmp ecx, edx
    jge .next_outer

    ; compare contacts[ecx] with contacts[ecx+1]
    mov ebx, ecx
    imul ebx, RECORD_SIZE
    lea esi, [contacts + ebx]       ; ptr to current

    add ebx, RECORD_SIZE
    lea edi, [contacts + ebx]       ; ptr to next

    ; compare names (case-insensitive)
    push edi
    push esi
    call compare_names_case_insensitive
    add esp, 8

    cmp eax, 0          ; if current > next, swap
    jle .no_swap

    ; swap two records
    mov ebx, ecx
    imul ebx, RECORD_SIZE
    lea esi, [contacts + ebx]
    add ebx, RECORD_SIZE
    lea edi, [contacts + ebx]

    push RECORD_SIZE
    push edi
    push esi
    call swap_records
    add esp, 12

.no_swap:
    inc ecx
    jmp .inner_loop

.next_outer:
    dec edx
    jmp .outer_loop

.sort_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret

; ---- compare two names case-insensitively ----
; returns: eax < 0 if name1 < name2, 0 if equal, > 0 if name1 > name2
compare_names_case_insensitive:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov esi, [ebp+8]    ; first name
    mov edi, [ebp+12]   ; second name

.cmp_loop:
    lodsb               ; load char from first
    mov bl, [edi]       ; load char from second
    inc edi

    ; convert both to lowercase
    cmp al, 'A'
    jl .check_bl
    cmp al, 'Z'
    jg .check_bl
    add al, 32

.check_bl:
    cmp bl, 'A'
    jl .do_compare
    cmp bl, 'Z'
    jg .do_compare
    add bl, 32

.do_compare:
    cmp al, bl
    jl .less_than
    jg .greater_than

    ; equal, check if end of string
    cmp al, 0
    je .equal

    jmp .cmp_loop

.less_than:
    mov eax, -1
    jmp .cmp_done

.greater_than:
    mov eax, 1
    jmp .cmp_done

.equal:
    mov eax, 0

.cmp_done:
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

; ---- swap two records ----
swap_records:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx
    push eax

    mov esi, [ebp+8]    ; first record
    mov edi, [ebp+12]   ; second record
    mov ecx, [ebp+16]   ; size

.swap_loop:
    mov al, [esi]
    mov ah, [edi]
    mov [edi], al
    mov [esi], ah

    inc esi
    inc edi
    dec ecx
    jnz .swap_loop

    pop eax
    pop ecx
    pop edi
    pop esi
    pop ebp
    ret

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

    ; sort contacts
    call bubble_sort_contacts

    mov ebx, 0      ; index_counter
    mov edi, 0      ; previous name ptr (0 = no previous)

.display_loop:
    cmp ebx, [contact_count]
    jge main_menu

    ; get current record
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx

    ; check if same name as previous
    cmp edi, 0
    je .display_full    ; first contact

    ; compare with previous name
    push esi
    push edi
    call compare_names_case_insensitive
    add esp, 8

    cmp eax, 0
    je .display_number_only

.display_full:
    ; display full (name, number)
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    mov edi, esi        ; save current name ptr
    push esi
    add esi, NAME_SIZE
    push esi
    pop esi
    sub esi, NAME_SIZE
    push esi
    add esi, NAME_SIZE

    push esi
    push edi
    push fmt_display_contact
    call _printf
    add esp, 12

    inc ebx
    jmp .display_loop

.display_number_only:
    ; display only number (indented)
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx
    add esi, NAME_SIZE

    ; set up empty string for name field
    mov byte [temp_name], ' '
    mov byte [temp_name+1], 0

    push esi            ; number
    push temp_name      ; empty string
    push fmt_display_add
    call _printf
    add esp, 12

    inc ebx
    jmp .display_loop

.no_dp_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4
    jmp main_menu

; ----- display_contacts_by_letter -----
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

    mov al, [clear_buffer]

    ; convert input to lowercase if uppercase
    cmp al, 'A'
    jl .already_lower
    cmp al, 'Z'
    jg .already_lower
    add al, 32

.already_lower:
    mov bl, al              ; BL = lowercase search letter

    mov eax, [contact_count]
    cmp eax, 0
    je .no_contacts_letter

    ; sort contacts
    call bubble_sort_contacts

    mov esi, 0              ; contact index
    mov edi, 0              ; found counter
    mov edx, 0              ; previous name ptr

.loop_letter:
    cmp esi, [contact_count]
    jge .end_letter

    ; get current contact address
    push ebx                ; SAVE BL (search letter)

    mov ecx, esi
    imul ecx, RECORD_SIZE
    mov eax, contacts
    add eax, ecx            ; EAX = current contact ptr

    ; get first character and convert to lowercase
    mov cl, byte [eax]
    cmp cl, 'A'
    jl .check_match
    cmp cl, 'Z'
    jg .check_match
    add cl, 32              ; convert to lowercase

.check_match:
    pop ebx                 ; RESTORE BL
    cmp cl, bl              ; compare first letters
    jne .skip_letter

    ; letter matches, check if same as previous name
    cmp edx, 0
    je .display_full_letter

    ; compare with previous name (case-insensitive)
    push eax                ; save current ptr
    push ebx                ; save search letter

    push eax
    push edx
    call compare_names_case_insensitive
    add esp, 8

    pop ebx                 ; restore search letter
    mov ecx, eax            ; save comparison result
    pop eax                 ; restore current ptr

    cmp ecx, 0
    je .display_number_only

.display_full_letter:
    mov edx, eax            ; save as previous ptr

    ; display name, number
    push edx                ; SAVE EDX before printf
    push ebx                ; save search letter

    mov ebx, eax
    add ebx, NAME_SIZE      ; point to number

    push ebx
    push eax
    push fmt_display_contact
    call _printf
    add esp, 12

    pop ebx                 ; restore search letter
    pop edx                 ; RESTORE EDX after printf
    inc edi
    jmp .skip_letter

.display_number_only:
    ; display only number (indented)
    push edx                ; SAVE EDX before printf
    push ebx                ; save search letter

    mov ebx, eax
    add ebx, NAME_SIZE

    mov byte [temp_name], ' '
    mov byte [temp_name+1], 0

    push ebx
    push temp_name
    push fmt_display_add
    call _printf
    add esp, 12

    pop ebx                 ; restore search letter
    pop edx                 ; RESTORE EDX after printf
    inc edi

.skip_letter:
    inc esi
    jmp .loop_letter

.end_letter:
    cmp edi, 0
    jg main_menu

    push contact_not_found
    call _printf
    add esp, 4
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
