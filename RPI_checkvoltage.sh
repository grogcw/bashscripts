#!/bin/bash
echo -e "" ; \
echo -e "############### VOLTAGE ################" ; \
echo -e "" ; \
echo -e "--- CPU Voltage ---" ; \
echo -e "core : $(vcgencmd measure_volts core)" ; \
echo -e "" ; \
echo -e "---- RAMS Voltage ----" ; \
for id in sdram_c sdram_i sdram_p ; do \
        echo -e "$id : $(vcgencmd measure_volts $id)" ; \
done
echo -e "" ; \
echo -e "########################################" ; \
echo -e "" ; \
