# Oktaeder Voodoo 2 Test Patches

This folder contains two experimental test builds of the 256b intro OKTAEDER.COM, compiled specifically to debug a hardware lockup issue on a physical 3dfx Voodoo 2. 

The original 256b code used a size-coding trick that blindly targeted PCI Bus 0, Device 0 to trigger the **initEnable** register.
These patches are hardcoded for a Voodoo 2 residing at memory base 0xDF000000 on **PCI Device 15**.

## The Test Files

* **`NU_PATCH.COM`**  
  Retains the PCI initialization loop but updates the configuration address offset to `0xDF007843` to safely target Device 15. Use this for a standalone "cold boot" test.

* **`NU_NOPCI.COM`**  
  Completely strips out the PCI initialization loop. To run this version, the Voodoo 2 must be "pre-warmed" by running and exiting a standard Glide application first (which leaves the `initEnable` register awake at `0x14003`). It then runs entirely via direct memory mapping.

*Massive props to Nuclear for the physical hardware testing!*
