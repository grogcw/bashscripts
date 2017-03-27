#!/bin/sh

drives="sda sdb sdc sdd sde sdf"

for drive in $drives
do
	(
		brand="$(smartctl -i /dev/"$drive" | grep "Model Family" | awk '{print $3, $4, $5}')"
		serial="$(smartctl -i /dev/"$drive" | grep "Serial Number" | awk '{print $3}')"

                size="$(blockdev --getsize64 /dev/"$drive")"
                sizefinal=$(($size / 1000000000))
                echo $sizefinal

		echo ""
		echo "########## SMART status report for ${drive} drive (${brand}: ${serial}) [$sizefinal GB] ##########"
		echo ""
                smartctl -c /dev/"$drive"
        )
done

#Ask test length
read -p "Execute test [Short or Long] or Quit ? " prompt_test

case $prompt_test in

	[sS] | [sS][hH][oO][rR][tT] )

	echo "Starting short test..."

	for drive in $drives
	do
        	(
			smartctl -t short /dev/"$drive"
	        )
	done
	;;


	[lL] | [lL][oO][nN][gG] )

	echo "Starting long test..."

	for drive in $drives
	do
		(
		smartctl -t short /dev/"$drive"
		)
	done
	;;


	[qQ] | [qQ][uU][iI][tT] )
	exit
	;;
esac
