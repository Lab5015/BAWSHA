# RFSoC Vivado Project

This repository contains the Vivado project sources and scripts for the RFSoC design.

The project is generated automatically using the `proj.tcl` script. The script creates the Vivado project, imports all HDL sources, constraints, IP repositories, and generates the required Block Designs.

The target device is:

- **Board:** RealDigital RFSoC4x2
- **FPGA:** Xilinx Zynq UltraScale+ RFSoC XCZU48DR
- **Vivado version:** 2023.2

---

## Repository structure

```
.
├── proj.tcl
├── README.md
│
├── src/
│   ├── HDL sources
│   ├── Block Design wrappers
│   └── other hardware modules
│
├── bd/
│   ├── lockin.tcl
│   └── main.tcl
│
├── ip_repo/
│   └── custom Vivado IP repositories
│
└── constraints/
    └── Xilinx Design Constraint files (.xdc)
```

---

## Folder description

### `proj.tcl`

Main Vivado TCL script used to recreate the project.

The script performs:

- creation of the Vivado project;
- FPGA and board configuration;
- IP repository setup;
- HDL source import;
- constraint import;
- Block Design creation;
- compilation order update;
- top module configuration.

The script is the recommended way to recreate the Vivado project from a clean environment.

---

# Building the project

## Requirements

The following software is required:

- Xilinx Vivado **2023.2**
- RFSoC4x2 board files (if not already installed globally)

---

## Generate the Vivado project

From the repository root, run:

```bash
vivado -mode batch -source proj.tcl
```

This creates a new Vivado project inside:

```
./top/
```

The generated project can then be opened with:

```bash
vivado top/top.xpr
```

---

# Synthesis and implementation

The automatic synthesis and implementation steps are currently disabled in `proj.tcl`.

They can be enabled by uncommenting the corresponding section at the end of the script.

Alternatively, synthesis and implementation can be executed from the Vivado GUI:

1. Open the generated project.
2. Run **Synthesis**.
3. Run **Implementation**.
4. Generate the bitstream.
