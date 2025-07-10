
# Bootloader + 32-bit Protected Mode Demo

This project features a basic x86 assembly bootloader and a second-stage program that transitions the CPU into 32-bit protected mode. It showcases essential functionality such as text output and number conversion, demonstrating how to load and execute code beyond the bootloader on real hardware or in an emulator.

---

## Overview

- **Stage 1 (bootloader):**  
  - Runs in 16-bit real mode.  
  - Resets the disk using BIOS interrupt 13h.    
  - Loads stage 2 from disk into memory.  
  - Transfers execution to stage 2.

- **Stage 2:**  
  - Runs in 32-bit protected mode.  
  - Sets up Global Descriptor Table (GDT).  
  - Initializes segment registers and stack.  
  - Clears the screen using VGA memory.  
  - Prints messages and converts an integer to ASCII decimal string.  
  - Displays the number on screen.
  - Displays a loading message with a progress bar. 
  - Halts the CPU.

---

## Files

| Filename        | Description                             |
|-----------------|---------------------------------------|
| `bootloader.asm`| 16-bit bootloader (stage 1)            |
| `stage2.asm`    | 32-bit protected mode code (stage 2)  |
| `bootloader.bin`| Compiled bootloader binary             |
| `stage2.bin`    | Compiled stage 2 binary                 |
| `os_image.img`  | Combined bootable image (bootloader + stage 2) |

---

## Requirements

- NASM assembler ([https://www.nasm.us/](https://www.nasm.us/))  
- Command-line tools to concatenate files (e.g., `cat` on Linux/macOS or PowerShell on Windows)  
- Emulator for testing, such as QEMU

---

## Building the Bootable Image

Run the following commands in your terminal or command prompt to assemble and create the bootable image:

```bash
nasm -f bin bootloader.asm -o bootloader.bin
nasm -f bin stage2.asm -o stage2.bin
cat bootloader.bin stage2.bin > os_image.img
```

---

## Running the Image in an Emulator

You can test the image using QEMU:

```bash
qemu-system-i386 -fda os_image.img
```

This will boot the image as a floppy disk, showing the bootloader’s messages and stage 2 output.

---

## Important Notes

- This project is **not a full operating system**, but a bootloader + demo to illustrate transitioning from real mode to protected mode.  
- The bootloader must be exactly 512 bytes and end with the boot signature `0xAA55`.  
- Stage 2 is loaded at memory location `0x8000`.  
- Screen output in protected mode writes directly to VGA memory at `0xB8000`. 
- Interrupts are disabled during protected mode initialization to avoid unexpected behavior.

---


