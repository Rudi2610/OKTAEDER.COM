# OKTAEDER.COM

A 256-byte MS-DOS intro showcasing a rotating 3D octahedron. Released at the ROMA.EXE 2026 party, it claims to be the world's first 256b intro hardware-accelerated by the 3dfx Voodoo 1 graphics card.

**Author:** Rudi / DKE (rudi.stranden@gmail.com)  
**Release Date:** 20/06/2026  
**Assembler:** FASM (Flat Assembler) & NASM 

## Technical Features

To fit a 3D hardware-accelerated intro into 256 bytes, standard conventions were bypassed. The intro features:

*   **Custom Memory Addressing:** Enters 32-bit Flat / Unreal Mode dynamically at runtime using an overlapping 23-byte GDT patch.
*   **Bare-Metal Initialization:** Completely bypasses the standard `glide2x.ovl` API, manually waking the Voodoo 1 card via the PCI configuration port `0xCF8` and configuring the `FBZMODE` register for RGB+Z buffering.
*   **Procedural Geometry:** The 3D model is compressed into an 8-bit data array and expanded on the fly using a 90-degree stack-based lathe trick.
*   **CORDIC Math:** Uses integer-only bitshifts for 3D rotations.
*   **Hardware Shading:** Calculates face normals via simple `imul` instructions to achieve Lambert shading, backface culling, and a fake Gouraud gradient.
*   **Rendering:** Unified back-buffer swap and clear.

## Compatibility & Requirements

*   **Emulator:** This intro requires DOSBox-X with Voodoo 1 emulation enabled. 
*   **Hardware Constraints:** The assembly hardcodes the Voodoo 1 PCI memory base address to `0xD0000000`. Because of the size-optimized PCI initialization routine, compatibility on actual physical hardware is completely untested and probably will not work.
