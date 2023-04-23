echo "\nWorking..."

#fastqc *.fq.gz

for filename in *.fq.gz
do
	base=$(basename $filename .fq.gz)
	case=$(echo ${base} | cut -f 1 -d "_")
	ind=$(echo ${base} | cut -f 2 -d "_")
	: '
	echo "Aligning ${case}, ${ind}..."
	bowtie2 -U ${base}.fq.gz --rg-id "${base}" --rg "SM:${ind}" -x ../uni | samtools view -Sb | samtools sort -o ${base}.bam

	echo "Indexing sample ${base}..."

	samtools index ${base}.bam
	
	echo "Running bamQC on sample ${base}"

	qualimap bamqc --feature-file ../exons16Padded_sorted.bed  -bam ${base}.bam --outdir ${base}
	'
	echo "Computing coverage profile on sample ${base}..."

	bedtools genomecov -ibam ${base}.bam -bg -trackline -trackopts name=${ind} -max 100 > ${ind}Cov.bg

done

: '
echo "\nVariant Calling with freebayes..."

freebayes -f ../universe.fasta -m 20 -C 5 -Q 10 --min-coverage 10 --targets ../exons16Padded_sorted.bed ${case}_child.bam ${case}_father.bam ${case}_mother.bam  > ${case}.vcf

multiqc .
'
echo "Done"

