# OKTAEDER.COM

A 256-byte MS-DOS intro showcasing a rotating 3D octahedron[cite: 4]. Released at the ROMA.EXE 2026 party, it claims to be the world's first 256b intro hardware-accelerated by the 3dfx Voodoo 1 graphics card[cite: 5].

**Author:** Rudi / DKE (rudi.stranden@gmail.com)[cite: 5]  
**Release Date:** 20/06/2026[cite: 5]  
**Assembler:** FASM (Flat Assembler)[cite: 3]  

## Technical Features

To fit a 3D hardware-accelerated intro into 256 bytes, standard conventions were bypassed[cite: 5]. The intro features:

*   **Custom Memory Addressing:** Enters 32-bit Flat / Unreal Mode dynamically at runtime using an overlapping 23-byte GDT patch[cite: 5].
*   **Bare-Metal Initialization:** Completely bypasses the standard `glide2x.ovl` API, manually waking the Voodoo 1 card via the PCI configuration port `0xCF8` and configuring the `FBZMODE` register for RGB+Z buffering[cite: 5].
*   **Procedural Geometry:** The 3D model is compressed into an 8-bit data array and expanded on the fly using a 90-degree stack-based lathe trick[cite: 3, 5].
*   **CORDIC Math:** Uses integer-only bitshifts for 3D rotations[cite: 5].
*   **Hardware Shading:** Calculates face normals via simple `imul` instructions to achieve Lambert shading, backface culling, and a fake Gouraud gradient[cite: 5].
*   **Rendering:** Unified back-buffer swap and clear[cite: 5].

## Compatibility & Requirements

*   **Emulator:** This intro requires DOSBox-X with Voodoo 1 emulation enabled[cite: 4, 5]. 
*   **Hardware Constraints:** The assembly hardcodes the Voodoo 1 PCI memory base address to `0xD0000000`[cite: 3]. Because of the size-optimized PCI initialization routine, compatibility on actual physical hardware is completely untested and probably will not work[cite: 5].
