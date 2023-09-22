#!/bin/python

# ####################################################################################################
# Description  : Utility script to autogenerate and initialise a 64x16 ROM memory in AMBA_APB project
# File         : scripts/ROM_generation.py
# Author(s)    : Davide Bettarini, Diego Pacini
# Language     : python3.x
#
# Freely inspired by "LUT_generation.py" from digital PSM course materials
# ####################################################################################################

import random

WORDL = 16
ADDRB = 6
CELLN = 2**ADDRB
# Script is intended to be launched from project home directory, otherwise modify FNAME variable
# with correct destination path
FNAME = "src/ROM.vhd"

# Start to write the file
out_file = open(FNAME, "w")

out_file.write("library IEEE;\n")
out_file.write("  use IEEE.std_logic_1164.all;\n")
out_file.write("  use IEEE.numeric_std.all;\n")
out_file.write("\n")
out_file.write("entity ROM_64x16 is\n")
out_file.write("	port (\n")
out_file.write("		en_in		: in std_logic;\n")
out_file.write("		addr_in		: in  std_logic_vector(" + str(ADDRB - 1) + " downto 0);\n")
out_file.write("		data_out	: out std_logic_vector(" + str(WORDL - 1) + " downto 0)\n")
out_file.write("	);\n")
out_file.write("end entity;\n")
out_file.write("\n")
out_file.write("architecture rtl of ROM_64x16 is\n")
out_file.write("\n")
out_file.write("	type ROM_t is array (natural range 0 to " + str(CELLN - 1) + ") of integer;\n")
out_file.write("	constant ROM_c	: ROM_t := (\n\t\t")

for x in range(CELLN):
	rnum = random.randrange(0,1023)
	rnum *= 64
	rnum += x;		#Random number on 16 bits whose last 6 digits contain the corresponding address (easier to test)
	val = str(rnum)
	if x != 63:
		out_file.write(str(rnum) + ", ")
	else:
		out_file.write(str(rnum))
	
	if x % 8 == 7:
		out_file.write("\n\t\t")

out_file.write(");\n")
out_file.write("	signal data_s	: std_logic_vector(" + str(WORDL - 1) + " downto 0);")
out_file.write("\n")
out_file.write("begin\n")

out_file.write("	data_out <= std_logic_vector(to_unsigned(ROM_c(to_integer(unsigned(addr_in)))," + str(WORDL) + ")) when en_in = '1' else (others => 'Z');\n")
out_file.write("	data_out <= data_s;\n")

out_file.write("end architecture;\n")

out_file.close()
