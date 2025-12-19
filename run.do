# Clean coverage outputs
file delete -force spi.ucdb

# Clean old compiled library if it exists
if {[file exists work]} {
    vdel -lib work -all
}

# Create fresh work library
vlib work
vmap work work


# Compile RTL for code coverage
vlog -sv -cover bcesft +acc i2c_mem.sv

# Compile testbench normally
vlog -sv +acc tb.sv

# Simulate testbench (it instantiates RTL)
vsim -coverage work.tb

# Run simulation
run -all

# Save coverage
coverage save spi.ucdb

# Report coverage summary (optional)
coverage report -details
