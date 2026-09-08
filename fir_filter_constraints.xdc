################################################################################
# Vivado Design Constraints (.xdc)
# Design: Retimed 32-Tap FIR Filter for ECG Denoising
# Sampling Rate (fs): 360 Hz (MIT-BIH Standard)
# System Processing Clock: 100 MHz (10.0 ns period)
################################################################################

# ==============================================================================
# 1. Primary Clock Definition
# ==============================================================================
# 100 MHz processing clock (10.0 ns period, 50% duty cycle)
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

# System clock jitter and uncertainty (100 ps for FPGA fabric)
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.050 [get_clocks sys_clk]

# ==============================================================================
# 2. Input / Output Timing Constraints
# ==============================================================================
# Assuming external ADC / source synchronous interface:
# Input arrival delay bounded to 2.0 ns setup / 0.5 ns hold relative to clock
set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports valid_in]
set_input_delay -clock [get_clocks sys_clk] -min 0.500 [get_ports valid_in]

set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports x_in*]
set_input_delay -clock [get_clocks sys_clk] -min 0.500 [get_ports x_in*]

# Output valid and filtered sample y_out delays
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports valid_out]
set_output_delay -clock [get_clocks sys_clk] -min 0.500 [get_ports valid_out]

set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports y_out*]
set_output_delay -clock [get_clocks sys_clk] -min 0.500 [get_ports y_out*]

# ==============================================================================
# 3. Asynchronous & Static Path Exceptions
# ==============================================================================
# Active-low reset (rst_n) is asynchronous during assertion
set_false_path -from [get_ports rst_n]

# Filter coefficient reload bus is quasi-static (updated during configuration mode)
set_false_path -from [get_ports coeff_reload]
set_false_path -from [get_ports coeff_in*]

# ==============================================================================
# 4. Retiming and Synthesis Optimization Directives
# ==============================================================================
# Instruct Vivado synthesis engine to preserve the retiming registers (dR1 - dR4)
set_property DONT_TOUCH true [get_cells -hierarchical *reg_dr*]
set_property DONT_TOUCH true [get_cells -hierarchical *p_reg*]

# Maximize soft-logic LUT/Carry optimization (matches paper's multiplier-free DSP policy)
set_property USE_DSP48 "no" [get_cells -hierarchical *u_m*]