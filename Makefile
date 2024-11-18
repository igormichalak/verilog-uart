pcf_file = ./io.pcf

ICELINK_DIR=$(shell df | grep iCELink | awk '{print $$6}')

build:
	yosys -s script.ys
	nextpnr-ice40 \
		--up5k \
		--package sg48 \
		--json top.json \
		--pcf $(pcf_file) \
		--asc top.asc
	icepack top.asc top.bin

prog:
	icesprog top.bin

prog_flash:
	@if [ -d '$(ICELINK_DIR)' ]; \
	then \
		cp top.bin $(ICELINK_DIR); \
	else \
		echo 'iCELink not found'; \
		exit 1; \
	fi

clean:
	rm -rf top.json top.asc top.bin
