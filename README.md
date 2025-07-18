<h4>Aim of the pipeline</h4>

The aim of this project is to create an Nextflow pipeline for annotation of Isoseeq gene annotation of plant genomes. It takes raw raw fastq reads sequenced in PacBio platform, starting from raw isoseq subreads, the pipeline:<br/>
    - Generates the Circular Consensus Sequences (CSS) from subreads.bam<br/>
    - Clean and polish CCS to create Full Length Non Chimeric (FLNC) reads<br/>
    - Maps FLNCs on the reference genome<br/>
    - Defines and clean gene models<br/>

<h4>Pipeline summary</h4>
  1) Generate CCS consensuses from raw isoseq subreads (ccs)
  2) Remove primer sequences from consensuses (lima)
  3) Detect and remove chimeric reads (Isoseq refine)
  4) Convert bam file into fasta file (Bamtools convert)
  5) Select reads with a polyA tail and trim it (GSTAMA_POLYACLEANUP)
  6) uLTRA path: decompress FLNCs (GUNZIP)
  7) uLTRA path: index GTF file for mapping (uLTRA)
  8) ap consensuses on the reference genome (minimap or STAR)
  9) Clean gene models (tama collapse)
  10) Merge annotations by sample (tama merge)
