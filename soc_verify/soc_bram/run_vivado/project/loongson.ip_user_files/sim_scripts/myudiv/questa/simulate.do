onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib myudiv_opt

do {wave.do}

view wave
view structure
view signals

do {myudiv.udo}

run -all

quit -force
