---
## mdtemp.md ##
## This document was compiled from a markdown file into a pdf using pandoc 3.1.1.
## pandoc -o mdtemp.pdf mdtemp.md -f markdown 
title: |
  | ![](images/unimi_logo.png){width=2.5in align=center}
  | Master’s Degree in Bioinformatics for Computational Genomics
  |
  | **Genomics - Final Project Report**
subtitle: |
  | **Molecular Diagnosis of Rare Genetic Disorders in 5 Individuals**
  | Professor Matteo Chiara
date: A.Y. 2022/2023
author: |
  | **Alessandro Giulivo**
  | matricola *11351A*
language: en-US
papersize: a4paper
fontsize: 10.5pt
geometry: margin=1.4cm
toc: true
numbersections: true
lof: true
lot: true
colorlinks: true
urlcolor: blue
citecolor: green
linkcolor: blue
header-includes: |
  \renewcommand\listfigurename{Figures}
  \renewcommand\listtablename{Tables}

keywords: [genomics, project-report, BCG]
description: This is Alessandro Giulivo's final report for the Genomics Project at Bioinformatics for Computational Genomics
---
\newpage

# Introduction

## Overview
In this final assessment project for the Genomics course at University of Milan, we applied experimental approaches studied during the course for the analysis and interpretation of human genomic data. 
In particular, we worked with **exome sequencing of chromosome 16** of five *TRIOs* of individuals (*mother, father, child*) where parents are known to be healthy, whilst the child is possibly affected by a **rare mendelian disease**.  
\
**The aim of the project was *to make a correct diagnosis for each child (out of the five TRIOs)*.**

## The Data

The TRIOs studied in this project were:

\begin{center}
case 1642; 		case 1608; 		case 1765; 		case 1682; 		case 1705.
\end{center}

The majority of the workflow was performed on the *unix server* of the course, within the `BCG2023_agiulivo/finalProj` folder; a subfolder for each *case* was created with the `mkdir` command.  
The data consists of:

* three `fastq` files for each case (raw DNA-sequencing reads of chr16 of the three individuals);
* a `universe.fasta` file along with its index files (our hg19 reference genome for chr16);
* an `exons16Padded_sorted.bed` file (which specifies the target regions).

The data were retrieved from the folder `BCG2023_genomics_exam`.


# Methods

Figure \ref{Workflow} shows the complete pipeline carried out on each *"case"*; it will be illustrated in this section.
\begin{figure} 
\begin{center}
\includegraphics[]{"images/pipeline.pdf"}
\caption{Workflow} 
\label{Workflow} 
\end{center}
\end{figure} 

## Preprocessing and Variant calling

The first part of the analysis consisted in a few **pre-processing** steps:  
**(1)** a quality control check of the reads with **FastQC**;  
**(2)** **alignment** of the reads to the reference genome (`universe.fasta`) with **bowtie**. The output of this tool is in `SAM` format: we compress the `.sam` files into `BAM` format and sort the obtained `.bam` files;  
**(3)** indexing of the latter with `samtools index`;  
**(4)** quality control on the results with `qualimap bamqc`;  
**(5)** computing coverage histograms of each individual's sequenced genome.  

Then, for each case, all the **quality control reports** were put together in a single `html` report with **MultiQC**.  
\
Finally, joint **variant calling** of the three individuals was done using `freebayes`.  
The options used with this command were: *minimum mapping quality = 20*; *minimum alternate count = 5*; *mismatch base quality threshold = 10*; *minimum coverage = 10*; target regions to consider were specified in the `exons16Padded_sorted.bed` file; `universe.fasta` file was used as the reference genome with `bedtools genomecov`.

To perform the procedure mentioned above, the following bash script was saved in a `processCase.sh` file, and executed over each *TRIO*:

```{.sh}
fastqc *.fq.gz																					#(1)

for filename in *.fq.gz											#iterating over the three .fq files
do
	base=$(basename $filename .fq.gz)							#filename variable
	case=$(echo ${base} | cut -f 1 -d "_")						#case number variable
	ind=$(echo ${base} | cut -f 2 -d "_")						#individual name variable

	echo "Aligning sample ${base}..."															#(2)
	bowtie2 -U ${base}.fq.gz --rg-id "${base}" --rg "SM:${ind}" -x ../uni | \
									samtools view -Sb | samtools sort -o ${base}.bam

	echo "Indexing sample ${base}..."															#(3)
	samtools index ${base}.bam

	echo "Running bamQC on sample ${base}"														#(4)
	qualimap bamqc --feature-file ../exons16Padded_sorted.bed  -bam ${base}.bam --outdir ${base}

	echo "Computing coverage profile on sample ${base}..."										#(5)
	bedtools genomecov -ibam ${base}.bam -bg \
									-trackline -trackopts name=${ind} -max 100 > ${ind}Cov.bg
done

multiqc ./

echo "Variant Calling with freebayes..."
freebayes -f ../universe.fasta -m 20 -C 5 -Q 10 --min-coverage 10 --targets ../exons16Padded_sorted.bed \
							${case}_child.bam ${case}_father.bam ${case}_mother.bam  > ${case}.vcf
echo "Done"
```

## Variant Prioritization Strategy

The `vcf` file obtained with the commands illustrated earlier lists all the genomic variants found in the three individuals by `freebayes`; the files for all the cases were checked to have the last three columns describing, in the order, `mother`, `father` and `child` variants. In order to select specific variants of interest for the diagnosis of "child", knowing that parents are healthy, we need to exploit our knowledge regarding the hereditary model of the case:

* For **autosomal recessive (AR)** diseases (**case1642, case1765, case1682, case1705**), we need to search variants for which the child is homozygous (*1/1 in the `vcf` file*), whereas the parents are heterozygous (*0/1 in the `vcf` file*). This is done with the `grep` command and the results are saved in an output `case****_res.vcf` file. For example:
```{.sh}
		grep "0/1.*0/1.*1/1" case1765.vcf > case1765_res.vcf
```

* For **autosomal dominant (AD)** diseases instead (**case1608**), we assume that a *de novo* mutation is the cause of the disease (*in the child, at least one allele must be different from any of the parents' alleles*), as the parents must be homozygous for the reference allele to be healthy.
We look for a couple of patterns within our `vcf` file:
	* parents are homozygous for the reference allele, whilst child has at least one different allele;
	* parents have either one of two alternative alleles (both healthy), while child has another allele different from the two of the parents.

```{.sh}
		grep "0/0.*0/0.*/1" case1608.vcf > case1608_res.vcf
		grep "[01]/[01].[01]/[01]./[23]" case1608.vcf >> case1608_res.vcf
```

### Variant Effect Predictor

The obtained variants of interest for each case were uploaded on the [Ensemble Variant Effect Predictor web tool (VEP)](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP). This tool uses gene annotations to infer the effect of the genetic variants listed in our `vcf` files.  
*RefSeq transcripts* database was used for annotations; data about frequency of co-located variants were extracted from *1000 Genomes Global* and *gnomAD*; in order to possibly find which diseases are associated to any of our variants, we look for additional annotations which relate genes to *phenotypes*.  
After running a [VEP](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP) job for each of our cases, we obtained final results which were studied to make the diagnoses, shown in Section \ref{diagnoses}.

# Results

## Quality of the Data

The quality of the data was assessed using the **MultiQC reports** which were generated *for each case*. Overall, all samples had both sequencing quality (*phred score > 28*) and alignment coverage (*mean coverage > 10X*) high enough for the analysis to be performed.  
Figure \ref{MultiQC} shows an example.
\begin{figure} 
\begin{center}
\includegraphics[width=\textwidth]{images/case1765_multiqc.png} 
\caption{MultiQC Report for Case1765} 
\label{MultiQC} 
\end{center}
\end{figure} 

## Diagnoses\label{diagnoses}

Variant Effect Predictor results provided us with a description of the phenotype effects caused by the variants identified in our analysis.
In particular, **high impact variants** are the ones which most likely cause the disease we are looking for.  
Table \ref{results_table} shows the list of disease causing variants along with the diagnosed disease for each *case*.  
These results are also discussed in Section \ref{discussion}

Table: Results.\label{results_table}

| **CASE** | **LOCATION** | **REF** | **ALT** | **CONSEQUENCE** | **GENE** | **DISEASE** |
| :---: | :---: | :--: | :--: | :------: | :-----: | :--------------: | 
| [1642](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080358154.154;tl=iD4yHPfxGwlsxHTf-9105991;value1=HIGH#Results) | 16:89857825-89857828 | ATA | A | Frameshift Variant | FANCA | **Fanconi Anemia complementation group A** |
| [1608](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080355449.449;tl=z46xa1B5gwmMy16C-9117151;value1=MODERATE#Results) | - | - | - | - | - | **HEALTHY[^1]**\label{1608}  |
| [1765](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080363149.149;tl=PohO3g5ryr6XDVwI-9105981;value1=HIGH#Results) | 16:89882954-89882954 | C | A | Stop Gained | FANCA | **Fanconi Anemia complementation group A**    |
| [1682](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080359665.665;tl=4CT23oWFu15VZ6Tw-9105990;value1=HIGH#Results) | 16:88907503-88907503 | C | G | Splice Acceptor Variant | GALNS | **Mucopolysaccharidosis IV-A**    |
| [1705](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080361422.422;tl=tOeEWOla4WreiVmE-9105988;value1=HIGH#Results) | 16:53682877-53682877 | G | T | Stop Gained, Splice Region Variant | RPGRIP1L | **Joubert Syndrome; Meckel-Gruber Syndrome** |

[^1]: For case1608, a missense variant with moderate impact was found on the **CREBBP** gene (location: 16:3820629-3820629, REF: G, ALT: T): hence, a possible cause for Rubinstein-Taybi syndrome. However, only *PolyPhen* labelled the variant as "*possibly damaging*"; other pathogenicity predictors, .i.e., *SIFT* and *CADD*, classified it as "**tolerated**", "**likely benign**"; also, the allele frequency according to gnomAD is not very low (>10^-4^). Thus, our final diagnosis  for *case1608* was: **healthy**.


## Visualizing the Variants on UCSC

The variants, along with the coverage tracks, of each case were finally visualised on the [UCSC Genome Browser](https://genome.ucsc.edu/cgi-bin/hgTracks?db=hg19&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr16%3A89882909%2D89882998&hgsid=1606865951_wNKslHExLPyBMml2QAtfgF1Gfq9r). Figure \ref{Variant on UCSC} shows, as an example, the disease causing variant for *case1765*.

\begin{figure} 
\begin{center}
\includegraphics[width=\textwidth]{images/case1765_ucsc.png} 
\caption{Case1765 disease-causing SNV on UCSC} 
\label{Variant on UCSC} 
\end{center}
\end{figure} 

# Discussion \label{discussion}

As the table of Section \ref{diagnoses} illustrates, **four out of the five studied cases were found to have a high impact variant associated to a rare mendelian disease**.  
\
For cases *1642* and *1765*, respectively a frameshift variant and a stop gained variant were found on the **FANCA** (Fanconi Anemia Complementation Group A) gene; mutations in this gene are the most common cause of **Fanconi Anemia**. It is a condition that affects many parts of the body, and causes bone marrow failure, physical abnormalities, organ defects, and an increased risk of certain cancers.  
\
For case *1682*, a splice acceptor variant was found on the **GALNS** gene, which encodes galactosamine(N-acetyl)-6-sulfatase. Sequence alterations, including those that affect splicing, result in a deficiency of this enzyme, which in turn leads to Morquio A syndrome (**Mucopolysaccharidosis IV-A**). This disorder can affect an individual's appearance, organ function and physical abilities.  
\
Then, a high impact variant for case *1705* was found on gene **RPGRIP1L**. The protein encoded by this gene is related to the Hedgehog Signaling pathway and to organelle biogenesis and maintenance. Defects in this gene are a cause of **Joubert-Meckel** syndrome, which is a lethal developmental syndrome characterized by posterior fossa abnormalities, bilateral enlarged cystic kidneys, and hepatic developmental defects.  
\
Finally, instead, for *case1608*, no variants with a **high impact** were found to be associated with any rare disease. Therefore, we looked for variants with a moderate impact: one missense variant with moderate impact was found on the **CREBBP** gene (so, a possible cause for Rubinstein-Taybi syndrome). However, the frequency of this allele according to *gnomAD* is not very low ($0.009$; but should be $\leq$ 10^-4^ to be in accordance with the rareness of the diseases we are looking for). Moreover, only *PolyPhen* showed a significant score for the pathogenicity of the variant; other pathogenicity predictors such as *SIFT* and *CADD*, classified it as “tolerated”, “likely benign”. As a consequence, *case 1608* was diagnosed as: **healthy**.  




