.PHONY: build program clean

build:
	quartus_sh --no_banner --flow compile tld_divtiesus -c tld_divtiesus.qpf

program:
	quartus_pgm --no_banner --mode=jtag -o "BVP;output_files/tld_divtiesus.pof"

clean:
	rm -rf db incremental_db output_files

report:
	cat output_files/${REVISION}.*.smsg output_files/${REVISION}.*.rpt |grep -e Error -e Critical -e Warning |grep -v -e "Family doesn't support jitter analysis" -e "Force Fitter to Avoid Periphery Placement Warnings"
