# Network-on-Chip
This project created for modeling of Network on Chip with simple routers and different topologies. After modeling statistics can be counted by special script.

For working Modelsim must be installed.

Configuring NoC in `src/configs.vh`

To run NoC testbench: `tests/test_NoC_modelsim.bat`

In .bat file used `rout_table_gen.py` script. It generates a routing table for topologies. To get additional info run `rout_table_gen.py -h`.

#REFERENCES
A.Y. Romanov, Development of routing algorithms in networks-on-chip based on ring circulant topologies, Heliyon. 5 (2019) e01516. doi:10.1016/J.HELIYON.2019.E01516.
A.Y. Romanov, A.D. Ivannikov, I.I. Romanova, Simulation and synthesis of networks-on-chip by using NoCSimp HDL library, in: 2016 IEEE 36th Int. Conf. Electron. Nanotechnol., IEEE, 2016: pp. 300–303. doi:10.1109/ELNANO.2016.7493072.
