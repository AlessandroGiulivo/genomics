## Overview
In this final assessment project for the Genomics course at University of Milan, we applied experimental approaches studied during the course for the analysis and interpretation of human genomic data. 
In particular, we worked with **exome sequencing of chromosome 16** of five *TRIOs* of individuals (*mother, father, child*) where parents are known to be healthy, whilst the child is possibly affected by a **rare mendelian disease**.  
\
**The aim of the project was *to make a correct diagnosis for each child (out of the five TRIOs)*.**

## The Data

The TRIOs studied in this project were:

* case 1642;
* case 1608;
* case 1765;
* case 1682;
* case 1705.

The majority of the workflow was performed on the *unix server* of the course, within the `BCG2023_agiulivo/finalProj` folder; a subfolder for each *case* was created with the `mkdir` command.  
The data consists of:

* three `fastq` files for each case (raw DNA-sequencing reads of chr16 of the three individuals);
* a `universe.fasta` file along with its index files (our hg19 reference genome for chr16);
* an `exons16Padded_sorted.bed` file (which specifies the target regions).

The data were retrieved from the folder `BCG2023_genomics_exam`.

# Results

| **CASE** | **LOCATION** | **REF** | **ALT** | **CONSEQUENCE** | **GENE** | **DISEASE** |
| :---: | :---: | :--: | :--: | :------: | :-----: | :--------------: | 
| [1642](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080358154.154;tl=iD4yHPfxGwlsxHTf-9105991;value1=HIGH#Results) | 16:89857825-89857828 | ATA | A | Frameshift Variant | FANCA | **Fanconi Anemia complementation group A** |
| [1608](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080355449.449;tl=z46xa1B5gwmMy16C-9117151;value1=MODERATE#Results) | - | - | - | - | - | **HEALTHY**  |
| [1765](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080363149.149;tl=PohO3g5ryr6XDVwI-9105981;value1=HIGH#Results) | 16:89882954-89882954 | C | A | Stop Gained | FANCA | **Fanconi Anemia complementation group A**    |
| [1682](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080359665.665;tl=4CT23oWFu15VZ6Tw-9105990;value1=HIGH#Results) | 16:88907503-88907503 | C | G | Splice Acceptor Variant | GALNS | **Mucopolysaccharidosis IV-A**    |
| [1705](http://grch37.ensembl.org/Homo_sapiens/Tools/VEP/Results?field1=IMPACT;operator1=is;time=1682080361422.422;tl=tOeEWOla4WreiVmE-9105988;value1=HIGH#Results) | 16:53682877-53682877 | G | T | Stop Gained, Splice Region Variant | RPGRIP1L | **Joubert Syndrome; Meckel-Gruber Syndrome** |

As illustrated in the table above, **four out of the five studied cases were found to have a high impact variant associated to a rare mendelian disease**.  
\
For cases *1642* and *1765*, respectively a frameshift variant and a stop gained variant were found on the **FANCA** (Fanconi Anemia Complementation Group A) gene; mutations in this gene are the most common cause of **Fanconi Anemia**. It is a condition that affects many parts of the body, and causes bone marrow failure, physical abnormalities, organ defects, and an increased risk of certain cancers.  
\
For case *1682*, a splice acceptor variant was found on the **GALNS** gene, which encodes galactosamine(N-acetyl)-6-sulfatase. Sequence alterations, including those that affect splicing, result in a deficiency of this enzyme, which in turn leads to Morquio A syndrome (**Mucopolysaccharidosis IV-A**). This disorder can affect an individual's appearance, organ function and physical abilities.  
\
Then, a high impact variant for case *1705* was found on gene **RPGRIP1L**. The protein encoded by this gene is related to the Hedgehog Signaling pathway and to organelle biogenesis and maintenance. Defects in this gene are a cause of **Joubert-Meckel** syndrome, which is a lethal developmental syndrome characterized by posterior fossa abnormalities, bilateral enlarged cystic kidneys, and hepatic developmental defects.  
\
Finally, instead, for *case1608*, no variants with a **high impact** were found to be associated with any rare disease. Therefore, we looked for variants with a moderate impact: one missense variant with moderate impact was found on the **CREBBP** gene (so, a possible cause for Rubinstein-Taybi syndrome). However, the frequency of this allele according to *gnomAD* is not very low ($0.009$; but should be $\leq$ $10^-4$ to be in accordance with the rareness of the diseases we are looking for). Moreover, only *PolyPhen* showed a significant score for the pathogenicity of the variant; other pathogenicity predictors such as *SIFT* and *CADD*, classified it as “tolerated”, “likely benign”. As a consequence, *case 1608* was diagnosed as: **healthy**.  




