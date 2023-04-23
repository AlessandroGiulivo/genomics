echo "Working on AR cases..."
for fld in case1642 case1682 case1705 case1765
do
	cd $fld
	echo "Working on ${fld}..."
	grep "0/1.*0/1.*1/1" ${fld}.vcf > ${fld}_res.vcf
	cd ..
	echo
done

echo "Working on AD cases..."
for fld in case1608
do
	cd $fld
	echo "Working on ${fld}..."
	grep "0/0.*0/0.*/1" ${fld}.vcf > ${fld}_res.vcf
	grep "[01]/[01].*[01]/[01].*/[23]" ${fld}.vcf >> ${fld}_res.vcf
	cd ..
	echo
done
