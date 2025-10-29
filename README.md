# Architecture and Organization Final Project  
**Contact Directory in Assembly Language**

## Overview
This project is our final requirement for **CS 318 Organization and Architecture**.  
It implements a **Contact Directory System** in Assembly language with a **menu-driven interface**, modular design, and robust error handling.

The program allows users to manage contacts by adding, deleting, searching, and displaying entries, while ensuring input validation and user-friendly interaction.

---

## Features
- **Add Contact**  
  - Store a contact with *Name* and *Phone Number*  

- **Delete Contact**  
  - Delete by *Name*  
  - Delete by *Phone Number*  

- **Search Contact**  
  - Search by *Name*  
  - Search by *Phone Number*  

- **Display Contacts**  
  - Display all saved contacts  
  - Display contacts starting with a specific letter  

- **Other Highlights**  
  - Menu-driven interface  
  - Modular programming structure  
  - Input validation and error handling  

---

## Technologies Used
- **Assembly Language** (x86 / NASM)  
- Modular programming principles  
- Error handling and validation routines  

---

##  How to Contribute

To keep our `main` branch clean and stable, please follow this workflow when contributing:

1. **Fork the Repository**  
   - Click the **Fork** button at the top-right of this repo to create your own copy under your GitHub account.

2. **Clone Your Fork**  
   ```bash
   git clone https://github.com/<your-username>/Architecture-and-Organization-Final-Project.git
   ```
   Replace `<your-username>` with your GitHub username.

3. **Create a New Branch**  
   - Always create a branch for each feature or fix:  
   ```bash
   git checkout -b feature-name
   ```

4. **Make Your Changes**  
   - Implement your code, documentation, or fixes.  
   - Stage and commit with a clear message:  
   ```bash
   git add .
   git commit -m "Add search by phone number feature"
   ```

5. **Push to Your Fork**  
   ```bash
   git push origin feature-name
   ```

6. **Open a Pull Request (PR)**  
   - Go to your fork on GitHub.  
   - Click **New Pull Request** and set the base repo to  
     `mrfahrenheit0528/Architecture-and-Organization-Final-Project` and the compare branch to your feature branch.  
   - Add a description of your changes.

7. **Review & Merge**  
   - Other members will review your PR.  
   - Once approved, it will be merged into `main`.

---

### 🔑 Notes
- Do **not** push directly to `main`.  
- Keep your fork updated by syncing with the upstream repo:  
  ```bash
  git remote add upstream https://github.com/mrfahrenheit0528/Architecture-and-Organization-Final-Project.git
  git checkout main
  git pull upstream main
  git push origin main
  ```



---

## Documentation
- Google Docs:
  https://docs.google.com/document/d/1MfjFmMlAJt0RzWlr7dyyYsjDF3K0zApG5CoS3Rd58_Y/edit?usp=sharing

---
## Routines
1. **Menus**
    1. ```main_menu```: Central hub that displays options, reads user choice, and jumps to the correct routine
    2. ```delete_menu```: Sub‑menu for delete options
    3. ```search_menu```: Sub‑menu for search options
2. **Feature Routines**
    1. ```add_contact```: Inserts a new record (name + phone) into the array. Updates ```contact_count```.
    2. ```delete_by_name```: Finds a contact by name and removes it
    3. ```delete_by_phone```: Same as above but matches on phone number
    4. ```search_by_name```: Finds a contact by name. Returns index if found
    5. ```search_by_phone```: Finds a contact by phone. Returns index if found
    6. ```display_all```: Loops through all contacts and print them
    7. ```display_by_letter```: Prints only contacts whose names start with a given letter
3. **Utility Routines** 
    1. ```print_contact_by_index```: Given an index, prints that contact's name and phone. To be reused by *display* and *search*.
    2. ```get_contact_ptr_by_index```: Calculates the memory address of a contact record. Prevents duplicate math everywhere.
    3. ```string_compare```: Compare two strings. *(to be used in search and delete)*
    4. ```string_starts_with```: Checks if a string begins with a given letter. *(to be used in display_by_letter)*
    5. ```copy_string_fixed```: Copies input into a fixed-size buffer (pads or truncates). *(to be used in add_contact)*

## Constants
- ```NAME_SIZE EQU 30``` -> max characters for name
- ```PHONE_SIZE EQU 11``` -> max characters for phone
- ```RECORD_SIZE EQU (NAME_SIZE + PHONE_SIZE)``` -> total bytes per contact
- ```MAX_CONTACTS EQU 100``` -> maximum number of contacts
## Data Storage
- ```contacts```: -> (```RECORD_SIZE``` * ```MAX_CONTACTS```) bytes reserved
- ```contact_count```: -> integer tracking how many contacts are currently stored.
## Input Buffers
- ```input_name```: temporary space for user-entered name
- ```input_phone```: temporary space for user-entered phone number
- ```input_letter```: single character buffer for ```display_by_letter```
- ```choice```: single character buffer for user selection

---
## Flow
- Main Menu
```flow
main_menu
   ↓
User chooses option
   ├── 1 → add_contact
   ├── 2 → delete
       ├── 1 → delete_by_name
       ├── 2 → delete_by_phone
       └── 0 → back_to_main_menu
   ├── 3 → search
       ├── 1 → search_by_name
       ├── 2 → search_by_phone
       └── 0 → back_to_main_menu
   ├── 4 → display_all
   ├── 5 → display_by_letter
   └── 0 → exit_program
```
- Add Contact
```flow
add_contact
   ↓
Check if contact_count < MAX_CONTACTS
   ├── No → return "Directory full"
   └── Yes
        ↓
   Compute record_ptr = contacts + (contact_count * RECORD_SIZE)
        ↓
   Copy name → record_ptr
   Copy phone → record_ptr + NAME_SIZE
        ↓
   Increment contact_count
        ↓
   Return success
```
- Delete by Name
```flow
delete_by_name
   ↓
Loop through contacts (0 → contact_count-1)
   ↓
Compare input_name with record.name
   ├── Match → shift all later records left by 1
   │            decrement contact_count
   │            return success
   └── No match → continue loop
        ↓
If end reached → return "Not found"
```
- Delete by Phone *(Same as delete by name, but compare phone field instead)*
- Search by Name
```flow
search_by_name
   ↓
Loop through contacts
   ↓
Compare input_name with record.name
   ├── Match → return success + index
   └── No match → continue
        ↓
If end reached → return "Not found"
```
- Search by Phone *(Same as search by name, but compare phone field)*
- Display All
```flow
display_all
   ↓
Loop through contacts
   ↓
For each record:
   print name + phone
```
- Display by Letter
```flow
display_by_letter
   ↓
Loop through contacts
   ↓
Check if record.name[0] == input_letter
   ├── Yes → print contact
   └── No → skip
```
