## this wrapper script constructs a personal genome and Bowtie indices for the parental genomes using Alex's vcf2diploid
## do this in the directory you keep this personal genome
## for multiple genomes, write a shell script to create personal genome folders and copy this script individually into each folder and run them
## USAGE: alleleWrap_vcf2diploid <1> <2> <3> <4> <5>
## <1> = path for vcf2diploid script
## <2> = individual's ID, e.g. NA12878
## <3> = path for reference genome FASTAs; make sure the fasta files are named by chromosomes and prefixed "chr": chr1.fa chr2.fa etc.
## <4> = path for VCF variant file (NOT zipped)
## <5> = <sequencer>_<genotypeCaller>_<date> e.g. hiseq_pcrfree_hc_130506
## e.g. ./alleleWrap_vcf2diploid.sh ~/vcf2diploid.jar NA12878 /here/fasta/ /here/CEU.vcf miseq_pcr_free_131313

java -Xmx10000m -jar $1 \
-id $2 \
-chr $3/chr[1-9].fa $3/chr1[0-9].fa $3/chr2[0-9].fa $3/chr[XY].fa \
-vcf $4 \
-pass >& out_vcf2diploid_$2_$5.log || exit 1

## these are personal genome checks
echo "check_chain.pl" >> out_check_chrom_$2_$5.log
check_chain.pl *.chain >> out_check_chrom_$2_$5.log
echo "check_chrom_chain.pl" >> out_check_chrom_$2_$5.log
check_chrom_chain.pl *.chain *.fa >> out_check_chrom_$2_$5.log
echo "check_map_file.pl" >> out_check_chrom_$2_$5.log
check_map_file.pl *_$2.map >> out_check_chrom_$2_$5.log
echo "check_chromosomes.pl" >> out_check_chrom_$2_$5.log
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22; do check_chromosomes.pl "$3"/chr"$i".fa "$i"_$2_paternal.fa "$i"_$2_maternal.fa "$i"_$2.map ; done >> out_check_chrom_"$2"_"$5".log

###### create parental genomes and indices for Bowtie
function qsub_bowtie_parent
## arg_1 = param 1 passed in to create-script-and-qsub.sh script
{
        echo "#!/bin/sh" > myscript-$1.sh
        echo "#PBS -N bowtie-$1" >> myscript-$1.sh
        echo "#PBS -l ncpus=4" >> myscript-$1.sh
        echo "#PBS -V" >> myscript-$1.sh
        echo "#PBS -o bowtie-$1.log" >> myscript-$1.sh
        echo "#PBS -e bowtie-$1.err" >> myscript-$1.sh

        echo date >> myscript-$1.sh
        echo  >> myscript-$1.sh
        echo cd $(pwd)  >> myscript-$1.sh
        echo bowtie-build 1_$3_$1.fa,2_$3_$1.fa,3_$3_$1.fa,4_$3_$1.fa,5_$3_$1.fa,6_$3_$1.fa,7_$3_$1.fa,8_$3_$1.fa,9_$3_$1.fa,10_$3_$1.fa,11_$3_$1.fa,12_$3_$1.fa,13_$3_$1.fa,14_$3_$1.fa,15_$3_$1.fa,16_$3_$1.fa,17_$3_$1.fa,18_$3_$1.fa,19_$3_$1.fa,20_$3_$1.fa,21_$3_$1.fa,22_$3_$1.fa,X_$3_$1.fa $2 >> myscript-$1.sh
        echo date >> myscript-$1.sh
}

## main
## creates Bowtie indices for paternal and maternal genomes
mkdir AltRefFather AltRefMother
CURR=$(pwd) ## no space near equal signs!!
cd AltRefFather 
for i in $CURR/*_paternal.fa; do ln -s $i; done;
qsub_bowtie_parent "paternal" "AltRefFather" $2;
#qsub -l walltime=24:00:00 myscript-paternal.sh -q fas_high;
cd ..;
ln -s AltRefFather/myscript-paternal.sh

cd AltRefMother
for i in $CURR/*_maternal.fa; do ln -s $i; done;
qsub_bowtie_parent "maternal" "AltRefMother" $2;
#qsub -l walltime=24:00:00 myscript-maternal.sh -q fas_high;
cd ..;
ln -s AltRefMother/myscript-maternal.sh
