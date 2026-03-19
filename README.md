# 🚀 UVM-Based Verification of Memory Interface


## 📌 Project Overview
This project verifies an **I2C-based memory module** using **Verilog** for RTL and a **SystemVerilog UVM-based verification environment**.    
The verification focuses on validating **memory write and read functionality**, ensuring correct data storage and retrieval based on address and control signals.

Verification completeness is ensured using:
- ✅ SystemVerilog Assertions  
- 📊 Functional Coverage  
- 📈 Code Coverage  

All simulations and coverage analysis are performed using **QuestaSim**, with **TCL scripting** used to automate the verification flow.

---

## 🧠 Design Under Test (DUT)
The Design Under Test is an **I2C memory module** that supports basic **write and read operations**.  
The design behaves as a memory system controlled through a write-enable signal and address input.

### 🔌 Interface Signals
- **clk**  
  System clock

- **rst**  
  Active-high reset signal. Clears memory outputs and internal state.

- **wr**  
  Operation control signal:  
  - `wr = 1` → Write operation  
  - `wr = 0` → Read operation  

- **addr**  
  Address input used to select the memory location.

- **din**  
  Data input used during write operations.

- **datard**  
  Data output used during read operations.

- **done**  
  Indicates completion of a read or write operation.

---

## ⚙️ Functional / Operation Specification

### 🧩 General Behavior
- All memory operations are valid only when reset is deasserted.
- Reset clears output signals and disables memory access.
- Only one operation (read or write) is active at a time.

---

### ✍️ Write Operation
- `wr` is asserted high (`wr = 1`)
- Address (`addr`) and input data (`din`) are applied
- Data is written into the memory location specified by `addr`
- `done` is asserted after successful write completion

---

### 📖 Read Operation
- `wr` is deasserted (`wr = 0`)
- Address (`addr`) is applied
- Data stored at the given address is presented on `datard`
- `done` is asserted after successful read completion

---

### ⏱️ Status Signaling
- `done` indicates completion of read or write operation
- `done` remains low during an active transaction
- Outside completed operations, `done` remains low

---

## 🧪 Verification Strategy
Verification is performed using a **SystemVerilog procedural testbench**.

### Verification includes:
- Reset verification
- Valid write operations
- Valid read operations
- Read-after-write data integrity
- Multiple address access
- Back-to-back read/write transactions

Self-checking logic compares expected and actual read data to validate correctness.

---

## 🛡️ Assertions

SystemVerilog assertions are used to continuously monitor critical control and data behavior during simulation.

### Implemented Assertions

- **Reset Control Assertion**  
  Ensures that no write operation is enabled during reset.  
  When `rst` is asserted, the write control signal `wr` must remain low.

- **Read Operation Data Assertion**  
  Ensures that no write data is driven during a read operation.  
  When the design is not in reset and `wr = 0` (read mode), the input data signal `din` must remain low.

These assertions help detect illegal control usage and prevent unintended data activity during read operations, improving overall design robustness.

---

## 📈 Code Coverage

### Summary
RTL code coverage for the I2C memory design was collected using **QuestaSim** with **statement, branch, condition, expression, FSM, and toggle coverage** enabled.

- **Statement Coverage:** 96.25%  
- **Branch Coverage:** 92.59%  
- **Condition Coverage:** 78.57%  
- **Expression Coverage:** 100%  
- **FSM Coverage:**  
  - State Coverage: 100%  
  - Transition Coverage: 100%  
- **Toggle Coverage:** 60.79%  

**Total RTL Coverage (filtered view):** **88.03%**

---

### Coverage Analysis
- **Statement and branch coverage** indicate that the majority of executable RTL paths are exercised.
- **FSM coverage** is complete for both `state` and `nstate` machines, with all states and transitions fully covered.
- **Condition coverage** is partially covered due to certain signal combinations (e.g., `scl = 0`) not occurring under normal functional operation.
- **Toggle coverage** is limited for wide counters, unused bits, and rarely changing internal signals, which is expected for a directed functional verification environment.

Partial coverage is primarily associated with default branches, idle behavior, and non-functional signal combinations that are not triggered during valid I2C memory transactions.


---

## 📊 Functional Coverage

Functional coverage is implemented using a **SystemVerilog covergroup** to measure whether all planned memory access scenarios are exercised during simulation.

### Covergroup Description
A single covergroup is defined with **per-instance coverage enabled**, sampling key transaction-level signals.

#### Covered Signals
- **Address (`addr`)**
  - Low range: `0–64`
  - High range: `65–127`

- **Write Data (`din`)**
  - Low: `0–31`
  - Mid: `32–127`
  - High: `128–255`

- **Read Data (`datard`)**
  - Low range: `0–64`
  - High range: `65–127`

- **Write Control (`wr`)**
  - Read (`0`)
  - Write (`1`)

- **Reset (`rst`)**
  - Deasserted (`0`)
  - Asserted (`1`)

- **Completion Flag (`done`)**
  - Incomplete (`0`)
  - Complete (`1`)

---

### Cross Coverage
- A cross is defined between **reset, write control, and read data** to observe read data behavior when:
  - Reset is deasserted
  - Write operation is inactive (`wr = 0`)

Invalid or non-functional scenarios are excluded using **ignore bins**:
- Reset asserted cases
- Write operation active cases

This ensures that only **meaningful read scenarios** contribute to coverage.

---

### Coverage Results
- **Total Covergroup Coverage:** **100%**
- **Covergroup Types:** 1

The achieved coverage confirms that all defined functional bins and valid cross scenarios are fully exercised.

---

## 🔧 Tool & Automation

### Simulation Tool
- **Simulator:** QuestaSim  
- **Languages:** Verilog, SystemVerilog  

### Automation
- **TCL scripting** is used to:
  - Compile RTL and testbench
  - Run simulations
  - Collect and save coverage results

Automation ensures repeatable and consistent verification runs.

---

## ⚠️ Limitations

- Certain **condition combinations** (e.g., specific `scl` low scenarios) are not exercised, resulting in partial condition coverage.
- **Toggle coverage** is limited for wide counters, unused bits, and infrequently changing internal signals.


---

## 🏁 Conclusion
This project demonstrates **end-to-end verification** of an I2C memory design written in **Verilog**, using a **SystemVerilog UVM-based environment**. 

The use of **assertions, functional coverage, code coverage**, and **TCL automation** reflects an **industry-aligned verification methodology**

---
