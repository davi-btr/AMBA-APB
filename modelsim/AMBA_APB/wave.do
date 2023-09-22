onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /apb_tb/pclk_ext
add wave -noupdate /apb_tb/prstn_ext
add wave -noupdate /apb_tb/mstr_data_ext
add wave -noupdate /apb_tb/state_curr_tst
add wave -noupdate /apb_tb/state_next_tst
add wave -noupdate /apb_tb/mode_s
add wave -noupdate /apb_tb/pwrite_int
add wave -noupdate /apb_tb/slave_s
add wave -noupdate /apb_tb/psel1_int
add wave -noupdate /apb_tb/psel2_int
add wave -noupdate /apb_tb/penable_int
add wave -noupdate -radix unsigned /apb_tb/mstr_addr_ext
add wave -noupdate -radix unsigned /apb_tb/paddr_int
add wave -noupdate -radix hexadecimal /apb_tb/mstr_wdata_ext
add wave -noupdate -radix hexadecimal /apb_tb/pwdata_int
add wave -noupdate -radix hexadecimal /apb_tb/prdata_int
add wave -noupdate -radix hexadecimal /apb_tb/mstr_rdata_ext
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
WaveRestoreZoom {0 ps} {2305 ps}
