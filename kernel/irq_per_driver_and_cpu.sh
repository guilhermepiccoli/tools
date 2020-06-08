#!/bin/bash
#
# Shows PCI MSI IRQs' CPU (effective) assignment per driver; if the
# parameter "-g" is provided, also show the regular/generic CPU affinity
#
# Only for kernels >= 4.13 (see git.kernel.org/linus/0d3f54257dc3)
#
# Guilherme G. Piccoli (2020) 
#
IRQDIR="/proc/irq"
PCIDIR="/sys/bus/pci"

find "${IRQDIR}/" | grep -q "effective_affinity_list"
if [ $? != 0 ]; then
	echo "IRQ effective affinity unavailable, is this kernel < 4.13?"
	exit 1
fi

GENERIC=0
while test $# -gt 0
do
    case "$1" in
        -g) GENERIC=1
            ;;
        *) echo "Ignoring unknown parameter $1"
            ;;
    esac
    shift
done

#IFS=$'\n'
for drv in ${PCIDIR}/drivers/*
do
	DRIVER=$(basename ${drv}/)
	for addr in $(find ${drv} | grep "....:..")
	do
		if [ ! -d "${addr}/msi_irqs" ]; then
			continue
		fi

		for irq in ${addr}/msi_irqs/*
		do
			irqnum=$(basename ${irq})
			if [ ! -d ${IRQDIR}/${irqnum} ]; then
				continue
			fi

			if [ ! -z ${DRIVER} ]; then
				printf "\n\n### ${DRIVER} ###\n"
				DRIVER=""
			fi

			if [ ! -z ${addr} ]; then
					
				printf "\n@ $(basename ${addr})\n"
				addr=""
			fi

			if [ ${GENERIC} != 0 ]; then
				affinity=$(cat ${IRQDIR}/${irqnum}/smp_affinity_list)
				generic=" [generic affinity: ${affinity}]"
			fi

			effective=$(cat ${IRQDIR}/${irqnum}/effective_affinity_list)
			echo "** ${irqnum}: CPU -> ${effective}${generic}"
		done
	done
done
