for fld in case*
do
	cd $fld
	echo "Checking ${fld}"
	grep "^#CHR" *.vcf
	cd ..
	echo
done
