## Overview
This repository contains a bare-metal interactive hardware multiplier developed entirely in pure Assembly for the Texas Instruments MSP430FR6989. It interfaces with a custom daughter board to create a complete, real-time hardware user interface. Users set hexadecimal operands (0x00 to 0xFF) via an analog potentiometer, use tactile push buttons to load the specific operands into memory, and trigger a hardware-accelerated multiplication. All current states, loaded operands, and final 16-bit products are dynamically multiplexed to a 4-digit 7-segment display.

## Key Technical Features
* **Interactive State Machine:** Manages multiple hardware states (loading Operand 1, loading Operand 2, calculating product) triggered by debounced physical push buttons (`P1.3`, `P1.5`, `P4.7`).
* **Real-Time ADC User Interface:** Configures the 12-bit ADC to continuously sample a potentiometer, providing a live, responsive input mechanism to select 8-bit values without a serial terminal.
* **Hardware Acceleration:** Leverages the MSP430's integrated hardware multiplier (`&MPY`, `&OP2`) to calculate 16-bit products instantly upon user command, bypassing slow software multiplication routines.
* **Interrupt-Driven Multiplexing:** Utilizes Timer A0 for deterministic, non-blocking execution to keep the 7-segment display perfectly multiplexed regardless of user input delays.
