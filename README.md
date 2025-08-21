<h2>Aim of the pipeline</h2>

The aim of this project is to create an Nextflow pipeline for annotation of Isoseeq gene annotation of plant genomes. It takes raw raw fastq reads sequenced in PacBio platform, starting from raw isoseq subreads, the pipeline:<br>
    - Generates the Circular Consensus Sequences (CSS) from subreads.bam<br/>
    - Clean and polish CCS to create Full Length Non Chimeric (FLNC) reads<br/>
    - Maps FLNCs on the reference genome<br/>
    - Defines and clean gene models<br/>

<h3>Pipeline summary</h3>

  1) Generate CCS consensuses from raw isoseq subreads (ccs)<br/>
  2) Remove primers and Demultiplexing (lima)<br/>
  3) Trim poly(A) Tails and concatemer removal (Isoseq3 refine)<br/>
  4) Hig quality Isoforms (Isoseq3 cluster)<br/>
  5) Convert bam file into fastq file (Bamtools convert)<br/>
  6) Map consensuses on the reference genome (minimap/STAR)<br/>
  7) Clean gene models (Isoseq3/tama collapse)<br/>
  8) Merge annotations by sample (tama merge)<br/>
  9) Post Analysis:<br/>
    ISOPHASE: Isoform phasing using Iso-Seq data<br/>
    CUPCAKE & TAMA <br/>
    SQANTI: Quality control, evaulation and visualization<br/>
    COGENT: Reconstruct coding region<br/>
    

<h3>Resources</h3>
    https://github.com/PacificBiosciences/IsoSeq<br/>
    https://github.com/Magdoll/cDNA_Cupcake<br/>
    https://github.com/Magdoll/SQANTI3<br/>
    https://github.com/Magdoll/Cogent
    

