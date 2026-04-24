# MSP430 Interactive Hardware Multiplier

## Overview
This repository contains a bare-metal interactive hardware multiplier developed entirely in pure Assembly for the Texas Instruments MSP430FR6989. It interfaces with a custom ECE daughter board to create a complete, real-time hardware user interface. Users set hexadecimal operands (0x00 to 0xFF) via an analog potentiometer, use tactile push buttons to load the specific operands into memory, and trigger a hardware-accelerated multiplication. All current states, loaded operands, and final 16-bit products are dynamically multiplexed to a 4-digit 7-segment display.

## Key Technical Features
* **Interactive State Machine:** Manages multiple hardware states (loading Operand 1, loading Operand 2, calculating product) triggered by debounced physical push buttons (`P1.3`, `P1.5`, `P4.7`).
* **Real-Time ADC User Interface:** Configures the 12-bit ADC to continuously sample a potentiometer, providing a live, responsive input mechanism to select 8-bit values without a serial terminal.
* **Hardware Acceleration:** Leverages the MSP430's integrated hardware multiplier (`&MPY`, `&OP2`) to calculate 16-bit products instantly upon user command, bypassing slow software multiplication routines.
* **Interrupt-Driven Multiplexing:** Utilizes Timer A0 for deterministic, non-blocking execution to keep the 7-segment display perfectly multiplexed regardless of user input delays.

## Hardware Interface
The system relies on a custom daughter board mapped directly to the MSP430 GPIO pins. The physical interface is defined below:

| Component | Function | MSP430 Port |
| :--- | :--- | :--- |
| **7-Segment Display** | Segments A-G, DP | `P2.0` - `P2.7` |
| | Digit 1-4 Select | `P3.0` - `P3.3` |
| **User Inputs** | Push Button S1 | `P4.7` |
| | Push Button S2 | `P1.3` |
| | Push Button S3 | `P1.5` |
| **Analog Input** | Potentiometer Voltage | `P8.4` |
| **Status Indicators** | LED | `P3.6` |

## System Architecture

```mermaid
graph TD
    subgraph MCU ["MSP-EXP430FR6989 (Assembly / Bare-Metal)"]
        ADC["12-bit ADC <br> Pin: P8.4"]
        Timer["Timer A0 <br> ISR Controller"]
        Core["CPU Core <br> Hardware Multiplier"]
        Port2["Port 2 <br> Segment Control"]
        Port3["Port 3 <br> Digit Multiplexer"]
    end

    subgraph Board ["Custom Daughter Board"]
        Pot["Analog Potentiometer"]
        Disp["4-Digit 7-Segment Display"]
    end

    Pot -- "Analog Voltage" --> ADC
    ADC -- "Converted Data" --> Core
    Timer -- "Interrupt Triggers" --> Core
    Core -- "Segment Data" --> Port2
    Core -- "Digit Select" --> Port3
    Port2 -- "Pins P2.0 - P2.7" --> Disp
    Port3 -- "Pins P3.0 - P3.3" --> Disp
```

## Firmware Highlight: Hardware Multiplication & Digit Separation
To maintain high performance, the firmware bypasses software multiplication routines. Instead, it feeds raw ADC values into the hardware multiplier. The resulting 16-bit product is separated into individual decimal digits using highly optimized bitwise masking and right-shift rotations, preparing it for the multiplexed display output.

```assembly
SEP_PROD:   mov            R4            ,        4(R13)
            mov            R4            ,        6(R13)
            mov            R4            ,        8(R13)
            mov            R4            ,        10(R13)

            and            #0x000F       ,        4(R13)        ; Isolate First Digit
            and            #0x00F0       ,        6(R13)        ; Isolate Second Digit
            and            #0x0F00       ,        8(R13)        ; Isolate Third Digit
            and            #0xF000       ,        10(R13)       ; Isolate Fourth Digit

            ;--------- Executing Arithmetic Shifts --------
            mov            #0x04         ,        R14
loop1:      rra            6(R13)
            dec            R14
            jnz            loop1
            
            mov            #0x08         ,        R14
loop2:      rra            8(R13)
            dec            R14
            jnz            loop2
```

## Development & Debugging Tools
* **IDE:** Texas Instruments Code Composer Studio (CCS)
* **Debugging Interface:** TI Spy-Bi-Wire (2-wire JTAG). Used for halting the CPU core, stepping through assembly instruction cycles, and performing real-time register inspections to ensure exact timing alignments across the hardware timer interrupts.
