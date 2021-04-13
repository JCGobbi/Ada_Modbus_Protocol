# Ada MODBUS Protocol

This repository contains Ada software for the implementation of an ASCII and RTU MODBUS protocol stack, both client (master) and server (slave).

The software is based on the serial demo blocking (polling, not interrupt driven) inside the [Ada Drivers Library](https://www.github.com/Adacore/Ada_Drivers_Library) from [Adacore](https://www.adacore.com). The main board used for developing this software was the NUCLEO-F429ZI, from [ST Microelectronics](https://www.st.com), that has connectors for Arduino shields, so you may connect any RS-485 Arduino shield on it. If you want to use other nucleo boards, do the **Project Wizard** that comes with the Ada Drivers Library choosing your board. You will need to change the hardware addresses of the `peripherals_blocking.ads` file inside the `src` folder to adapt to your board.

You may use the GNAT Programming Studio from Adacore or Visual Studio Code from Microsoft to cross-compile these sources. For VSCode, it has a `.vscode/tasks.json` file that permits to check syntax and semantic, compile, build, clean, convert elf to hex and bin files and flash hex and bin files to board. Both IDEs need the [ST-LINK](https://github.com/stlink-org/stlink) to flash the executable to the nucleo board.
