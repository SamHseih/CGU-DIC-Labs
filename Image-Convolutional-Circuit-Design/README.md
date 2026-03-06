# Image Convolutional Circuit (CONV)
<table>
  <tr>
    <td width="50%">
      <img src="https://github.com/user-attachments/assets/45658784-cbc8-414c-9f8e-4234e0e7a84f" alt="APR Result 1" width="100%">
    </td>
    <td width="50%">
      <img src="https://github.com/user-attachments/assets/b54ade54-5e52-49e6-aecc-67e5b06b40c7" alt="APR Result 2" width="100%">
    </td>
  </tr>
</table>

## Description

This project implements the **Image Convolutional Circuit (CONV)** from the 2019 IC Design Contest Preliminary – Standard Cell Digital Circuit Design (Undergraduate Level).

The circuit processes a **64×64 grayscale image** using a two-layer architecture:

* **Layer 0:** Convolution + ReLU
* **Layer 1:** Max-pooling

All intermediate and final results are written back to on-chip memories (`L0_MEM0`, `L1_MEM0`) inside the testfixture for verification.

## Implementation Results (APR Post-Route)
* Completed end-to-end CNN circuit design from RTL coding to APR, and passed DRC/LVS as well as post-layout simulation verification (target: 100 MHz)
* APR total cell area: 97,743 µm², below the IC design contest evaluation threshold 270,000 µm² (≈ 63.8% smaller ), meeting the S-grade evaluation criteria
---
### Design Strategy 
* FSM-based control architecture
* Sequential computation
* Single multiplier resource sharing
* Area-oriented optimization
* Full APR flow completion (Placement → Routing → DRC/LVS → Post-Sim)
---
### Verification Status 
* RTL Simulation: **Passed (Layer 0 & 1)**
* Pre-layout Gate-level Simulation: **Passed**
* Post-layout Gate-level Simulation: **Passed**
* DRC: **0 Violations**
* Connectivity: **0 Violations / 0 Warnings**
---
### Timing Summary
**Setup (Max):**
* WNS: **0.034 ns**
* TNS: **0.000 ns**
* Violating Paths: **0**

**Hold (Min):**

* WNS: **0.039 ns**
* TNS: **0.000 ns**
* Violating Paths: **0**
---
### Area Summary
| Item                  | Value           |
| --------------------- | --------------- |
| Total Chip Area       | 97743.744 μm² |
| Total Core Area       | 71778.739μm²  |
| Standard Cell Area    | 63485.184 μm²  |
| Effective Utilization | 88.2%         |
| Pure Gate Density     | 88.4%         |


## I/O Port Definition

| Signal     | Dir | Width | Description                                                |
| ---------- | --- | ----- | ---------------------------------------------------------- |
| `clk`      | in  | 1     | System clock (rising-edge triggered)                       |
| `reset`    | in  | 1     | Active-high asynchronous reset                             |
| `ready`    | in  | 1     | Input image ready signal                                   |
| `busy`     | out | 1     | Processing status indicator                                |
| `iaddr`    | out | 12    | Input image address                                        |
| `idata`    | in  | 20    | Input pixel data (4-bit integer + 16-bit fraction, signed) |
| `crd`      | out | 1     | Memory read enable                                         |
| `cwr`      | out | 1     | Memory write enable                                        |
| `caddr_rd` | out | 12    | Memory read address                                        |
| `cdata_rd` | in  | 20    | Memory read data                                           |
| `caddr_wr` | out | 12    | Memory write address                                       |
| `cdata_wr` | out | 20    | Memory write data                                          |
| `csel`     | out | 3     | Memory bank select (Layer selection)                       |

## Operation

### Layer 0 – Convolution + ReLU

1. **Zero-padding:**
   The 64×64 input image is padded with one-pixel zero border.

2. **3×3 Convolution:**
   * Single kernel (Kernel 0)
   * Signed fixed-point arithmetic (4-bit integer + 16-bit fraction)
   * Bias addition after convolution
   * Rounding to 20-bit output format

3. **ReLU Activation:**

$$
y =
\begin{cases}
x, & x > 0 \\
0, & x \le 0
\end{cases}
$$

5. Results are written to `L0_MEM0` (`csel = 3'b001`)
   Output size: **64×64**

### Layer 1 – Max-Pooling
1. **2×2 Window**
2. **Stride = 2**
3. Maximum value selection from each 2×2 region
4. Results written to `L1_MEM0` (`csel = 3'b011`)
Output size: **32×32**

## Data Format
* **Signed fixed-point**
* **Total width:** 20 bits
* **Format:** 4-bit integer + 16-bit fraction
* All outputs are rounded to 20-bit precision

## Timing & Design Constraints
* **Operating Frequency:** 100 MHz (`CYCLE = 10.0 ns`)
* **Simulation Timescale:** `1ns/10ps`
* Synchronous design (rising-edge triggered)
* Asynchronous active-high reset
* Busy/Ready handshake protocol
* Memory access controlled by `crd` / `cwr`
* Gate-level simulation includes SDF back-annotation
* No setup/hold violations allowed
