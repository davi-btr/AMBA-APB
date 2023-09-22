onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ram_tb/clk_tb
add wave -noupdate /ram_tb/en_ext
add wave -noupdate /ram_tb/mode_s
add wave -noupdate /ram_tb/wrt_ext
add wave -noupdate -radix unsigned /ram_tb/addr_ext
add wave -noupdate -radix hexadecimal /ram_tb/din_ext
add wave -noupdate -radix hexadecimal /ram_tb/dout_ext
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2489 ps}
