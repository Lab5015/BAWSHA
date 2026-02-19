## BAWSHA Lock-In Firmware

Firmware images, source code, and design resources for the **BAWSHA Lock-In** implementation.

---

### Structure

| Path             | Description                                                                                                       |
| ---------------- | ----------------------------------------------------------------------------------------------------------------- |
| `constraints/`   | Constraint files for the RFSoC4x2 target implementation                                                           |
| `firmware_imgs/` | Generated firmware outputs: FPGA bitstreams (`.bit`) and hardware handoff files (`.hwh`)                          |
| `ip_repo/`       | Packaged custom IP cores currently used by the project                                                            |
| `lockin.xpr`     | Vivado project file                                                                                               |
| `src/`           | VHDL source code                                                                                                  |
| `test/`          | Verification environment including VHDL and Python testbenches                                                    |
| `schematics/`    | Design diagrams: single lock-in architecture, full firmware system schematic, and predicted filter-chain response |

---

### Notes

- Bitstreams in `firmware_imgs/` correspond to the latest successful build.
- Schematics provide architectural reference and expected signal-processing behavior.
