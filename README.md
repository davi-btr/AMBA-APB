# AMBA-APB

Universitary Project for academic year 2022-2023
Authors: Davide Bettarini, Diego Pacini

Design of a digital circuit capable of implementing a communication based on AMBA-APB standard. The blocks to be interconnected are: a generical digital circuit (i.e. microprocessor,. . . ) acting as the master of communication, a 64×16 Read-Only Memory (ROM) and a 128×8 Random Access Memory (RAM), both acting as a slave.

The system to be designed is hence required to communicate with the master (to detect its requests and exchange data), generate the signals compatible with APB protocol and handle the specific set of connections to the slave memories.
The project includes source file for the system in hardware description language, tests and simulations to verify its functionalities and also synthesis and implementation on FPGA.
