#!/bin/bash
gcc -o vram.exe vram_map.c
./vram.exe
cl65 --cpu 65C02 -o WIREFRAM.PRG -l wireframe.list wireframe.asm
