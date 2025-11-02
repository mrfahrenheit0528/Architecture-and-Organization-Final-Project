;--- search by name --------------
search_by_name:
    ; prompt for name
    push prompt_name
    call _printf
    add esp, 4

    push input_name
    push fmt_namenum
    call _scanf
    add esp, 8

    mov eax, [contact_count]
    cmp eax, 0
    je .no_contacts

    mov ebx, 0                      ; index = 0
.find_loop:
    cmp ebx, [contact_count]
    jge .not_found                  ; reached end

    ; compute record_ptr = contacts + index * RECORD_SIZE
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx                    ; esi = contact record
    mov edi, input_name             ; edi = name to compare

    mov ecx, NAME_SIZE
.compare_loop:
    mov al, [esi]
    mov dl, [edi]
    cmp al, dl
    jne .next_record
    cmp al, 0
    je .found_match
    inc esi
    inc edi
    loop .compare_loop

.next_record:
    inc ebx
    jmp .find_loop

.found_match:
    ; compute pointers for name and number again
    mov ecx, ebx
    imul ecx, RECORD_SIZE
    mov esi, contacts
    add esi, ecx                    ; esi = name
    mov edx, esi
    add esi, NAME_SIZE              ; esi = number

    ; print found contact
    push esi
    push edx
    push ebx
    push fmt_display_contact
    call _printf
    add esp, 16

    ; return index in eax
    mov eax, ebx
    jmp search_menu

.not_found:
    push db "Contact not found.", 10, 0
    call _printf
    add esp, 4
    jmp search_menu

.no_contacts:
    push no_contacts_msg
    call _printf
    add esp, 4
    jmp search_menu
