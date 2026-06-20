
; OKTAEDER.COM
; 256b intro for MS-DOS w. 3dfx card
; Released at ROMA.EXE 2026

; World's first 3dfx Voodoo 1 accelerated 256b?
; Features 3dfx Glide initialization, 3D CORDIC rotator,
; 90-degree lathe, Lambert shading & culling,
; fake Gouraud shading, and an 8-bit compressed octahedron

; Coded by Rudi / DKE
; FASM (Flat Assembler)

; Configuration
VOODOO_BASE equ 0xD0000000     ; SST-1 PCI Mem Base Address
FBIINIT0    equ 0x210          ; FBI Hardware Init Register 0
FIFOWB_FBI  equ 0x200000       ; 0001 - only FBI
FBZMODE     equ 0x110          ; Clip/chroma-key/stipple/W-buf/depth/dither/masks
; Read 3dfx documentation for more.

; Assumes EDX have PE=1 and A20 is on.
org 0x100
use16
null: mov ax, cs
      shl ax, 4
      push bx                  ; base high = 0
      jmp short setup

      ; 8-bit compressed data (Octahedron)
TRI3D db 0, -10, 0             ; Tri 1 - V0
      db 10, 0, 0              ; Tri 1 - V1
      db 0, 0, 10              ; Tri 1 - V2
      db 0, 10, 0              ; Tri 2 - V0
      db 0, 0, 10              ; Tri 2 - V1
      db 10 ;(Magic!) two 0's stolen from cddsc

      ; Define Flat GDT:
cddsc:dq ((0x0000) or (10011010b shl 40) or (0xf shl 48) or (0xc shl 52)) ; code
dtdsc:dq ((0xffff) or (10010010b shl 40) or (0xf shl 48) or (0xc shl 52)) ; data
setup:; Enter PMODE Flat:
      mov [cddsc + 2], ax      ; patch code descriptor base low
      inc ah
      ; Build 6-byte GDT-pointer on stack:
      push ax                  ; base low
      push ax                  ; limit = AX (>23)
      mov bx, sp               ; BX points to [Limit, BaseLow, BaseHigh]
      cli
      lgdt [bx]                ; load GDT
      mov cr0, edx             ; enter P(UNREAL)MODE (EDX PE=1 from DOS)
      mov dx, 0xcf8            ; safe in 16-bit
      jmp 0x18:pmode_entry     ; 16-bit far jump

pmode_entry:
use32 ; Set Flat Segments:
      push 0x20
      pop ds
      push ds                  ; copy DS to ES safely
      pop es

      ; Glide Init
      mov eax, VOODOO_BASE + 0x43
.pci_loop:
      out dx, eax              ; select word at 0x40
      mov dl, 0xfc
      out dx, al
      mov dl, 0xf8
      xor al, 0x80             ; Toggle 0x43 (Odd) to 0xC3 (Even Parity)
      jpe .pci_loop

      ; Trigger voodoo window!
      mov [VOODOO_BASE + FBIINIT0], eax ; assumes AL bit0 = 1

      ; RGB on, Z on, double buffering:
      mov edi, VOODOO_BASE + FIFOWB_FBI + FBZMODE
      mov ah, 0x46             ; Backbuf, RGB+Z, clip enable=1
      stosd                    ; FBZ_MODE
      scasd                    ; skip 4 bytes
      stosd                    ; CLIP_LEFTRIGHT
      stosd                    ; CLIP_LOWYHIGHY

draw: inc ebx                  ; rotation angle
      ; Outer Loop Init:
      mov cl, 4
.rot_loop:
      push ecx                 ; save outer counter
      mov si, TRI3D            ; reset vertex pointer
      mov cl, 2                ; upper bits in ECX are 0
.tri_loop:
      push ecx                 ; save inner counter
      mov di, 8
      push -3
      pop ecx
.emit_loop:
      push 3
      pop ebp
.read_vec:
      cs lodsb
      shl eax, 8            
      cwde
      push eax
      dec ebp
      jnz .read_vec
      pop edx
      pop ebp
      pop eax

      ; 90-degree Lathe:
      push ecx
      mov ecx, [esp + ecx * 8 + 32]
.lathe:
      xchg eax, edx
      neg edx
      loop .lathe

      ; 3D CORDIC Rotator:
      mov cl, 3
.axis_loop:
      push ecx
      mov cl, bh               ; set rotation speed
      inc ecx                         
.rot: push edx                 ; save Z
      sar edx, 5               ; shift directly
      add eax, edx             ; add to X
      pop edx                  ; restore Z
      push eax                 ; save X
      sar eax, 5               ; shift directly
      sub edx, eax             ; subtract from Z
      pop eax                  ; restore X
loop .rot
      xchg eax, ebp
      xchg eax, edx
      pop ecx
loop .axis_loop
      pop ecx
      push eax
      push ebp

      ; Projection:
      add ah, 0x14
      stosd
      xchg eax, ebp                   
      add ah, 0x0E
      stosd
      inc ecx
      jnz .emit_loop

      ; Shading & Culling:
      pop eax                  ; Y2
      pop ebp                  ; X2
      pop ecx                  ; Y1
      pop edx                  ; X1
      sub eax, ecx      
      sub ebp, edx      
      sub ecx, [esp]           ; Y1 - Y0
      imul ebp, ecx            ; EBP = dX2 * dY1
      pop ecx                  ; remove Y0
      pop ecx                  ; get X0 into ECX
      sub edx, ecx             ; X1 - X0
      imul eax, edx            ; EAX = dY2 * dX1
      sub eax, ebp
js .skip_draw                  ; cull backface
      shr eax, 5               ; experimentation: 5;6
      stosd                    ; red color
      ;stosd                   ; white color
      ;mov [edi + 0x58], eax   ; Lambert (only)

      ; Fake Gouraud Shading:
      mov [edi + 0x1C], edx    ; dRdX register. Exp: ecx ;edx
      mov [edi + 0x5C], eax    ; TRIANGLECMD
      ;mov [edi + 0x58], eax   ;
.skip_draw:
      pop ecx                  ; restore inner counter
      loop .tri_loop           ; BAM! next triangle
      pop ecx                  ; restore outer counter
      loop .rot_loop           ; next rotation

      ; Unified Swap & Clear
      mov di, 0x128            ; SWAPBUFFERCMD
      std                      ; write backwards
      stosd                    ; trigger swap
      stosd                    ; trigger fastfill
      cld                      ; reset direction flag

      ; ESC check
      in al, 96                ; read keyboard port
      dec al
      jnz near word draw       ; next frame
      mov [VOODOO_BASE + FBIINIT0], eax ; clear init writes
      mov cr0, ecx             ; return to realmode
      mov ah, 0x4c             ; terminate to DOS
      int 0x21
