#!/bin/bash
echo -e "" ; \
echo -e " \033[1;33m--- CPU Temperature ---\033[0m" ; \
echo -e " core : $(vcgencmd measure_temp)" ; \
echo -e "" ; \
#echo -e "\033[1;33m########## VOLTAGES ##########\033[0m" ; \
#echo -e "" ; \
echo -e " \033[1;31m--- CPU Voltage ---\033[0m" ; \
echo -e " core : $(vcgencmd measure_volts core)" ; \
echo -e "" ; \
echo -e "\033[1;32m---- RAMS Voltage ----\033[0m" ; \
for id in sdram_c sdram_i sdram_p ; do \
        echo -e "$id : $(vcgencmd measure_volts $id)" ; \
done
echo -e "" ; \
echo -e " \033[1;34m--- RAM Split ---\033[0m" ; \
echo -e "$(vcgencmd get_mem arm && vcgencmd get_mem gpu)" ; \
#echo -e "" ; \
#echo -e "\033[1;33m##############################\033[0m" ; \
echo -e "" ; \
