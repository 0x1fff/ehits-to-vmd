ehits-to-vmd
============

![DOI FROM zenodo.org](https://zenodo.org/badge/4195/0x1fff/ehits-to-vmd.png)

eHiTS-to-VMD is an interface between eHiTS software for virtual high-throughput screening and VMD graphic software used to visualize calculation results.

Application has been developed to automate the processing of computational data produced by virtual high-throughput screening (vHTS).
This simple application automates required steps for the analysis and visualization of research results. 


Paper describing application
---------------------------------------------

Version 1.0 of this application was decribed in paper

> eHiTS-to-VMD Interface Application. The Search for Tyrosine-tRNA Ligase Inhibitors.
> Krystian Eitner, Tomasz Gawęda, Marcin Hoffmann, Mirosława Jura, Leszek Rychlewski and Jan Barciszewski
>
> J Chem Inf Model. 2007 Mar-Apr;47(2):695-702 ;
> DOI: 10.1021/ci600392r ;
> PMID: 17381179 (http://www.ncbi.nlm.nih.gov/pubmed/17381179) ;
>
>link:  http://pubs.acs.org/doi/abs/10.1021/ci600392r


Paper presents an application that is an interface between the eHiTS docking program and the VMD graphic software. 
Thanks to the interface, molecules docked to a receptor using eHiTS can easily be visualized in VMD. 
The operation of the eHiTS-to-VMD application is illustrated by the analysis of results of searching for bacterial tyrosine-tRNA ligase (TyrRS) inhibitors that meanwhile are expected not to bind strongly to human TyrRS.


Motivation to create ehits-to-vmd interface application
------------------------------------------------------------

The search for ligands that bind strongly to specific proteins has been an arduous and challenging task. 
High-throughput screening (HTS) is a standard method for the analysis of extensive chemical compound libraries in search of active substances that bind to specific protein receptors.
That said, HTS is still extremely costly and time-consuming because of the sheer volumes of libraries that contain thousands of potentially biologically active compounds.
Therefore, there has been a need to apply computational methods so as to screen out at the outset the compounds that, because of their geometric or electrostatic properties, will not effectively bind a specific receptor.

An increase in computer processing power, together with the development of computational methods for protein structure prediction and the description of intermolecular interactions, has already led to various promising results in drug design. 
In particular, the need to optimize costs and the time required to find compounds with requisite activity has led to the development of varied virtual high-throughput screening methods (vHTS).


Electronic high-throughput screening (eHiTS) software is a flexible docking tool that systematically fills the space with fragments of a divided inhibitor while ensuring that they do not overlap. 
A customizable scoring functionality of the eHiTS software has empirical and statistical components and those that factor in local interactions between points of contact of the ligand and the receptor. 

In practice, eHiTS and similar programs generate vast volumes of output data. 
Output files generated during docking are saved in separate folders for each molecule, which results in a large number of (sub)folders being created.

Although the eHiTS vendors provide the CheVi program to visualize eHiTS results, 14 other visualization packages offer
additional flexibility. For example, Visual Molecular Dynamics (VMD) is such a program that can be customized to a great extent. 
In this case, further processing of the output data stored in hundreds or thousands of folders is necessary.

The widely available VMD software was selected for the purpose of our study. It offers a host of useful functionalities with no restriction on the number of opened structure files other than the available RAM. 
VMD offers a range of rendering and coloring methods: from straight lines and points to cylindrical structures and advanced ribbon imaging and drawings.
Furthermore, the program provides a possibility of creating animations and molecular dynamics imaging based on trajectory analysis. Hence, VMD is a useful tool for the visualization of results of computational experiments, realizable on a computer of choice. 



Program functions
----------------------

Application conducts recursive parsing of folders created by eHiTS, divides SDF output files with the geometries of docked molecules into individual files, and arranges them in an order dependent on the value of the scoring function. 
Subsequently, the application converts the SDF files that eHiTS generated into PDB files, interpretable by most molecule visualization programs. 

VMD can be used to visualize and analyze biological systems, such as proteins, nucleic acids, double lipid layers with bound inhibitors, and other small molecules. It may be utilized to visualize any molecule whose structure is available in a format compatible with the PDB standard, among others. 


The eHiTS-to-VMD interface generates a VMD script which automatically and quickly visualizes docking results yielded by vHTS experiments. 
Error-free operation of the eHiTS-to-VMD interface requires that the -out file.sdf option be used when running eHiTS. 
It should be noted that the -out file.sdf option instructs eHiTS to collect all the best scoring poses into the given file sorted
by the score. Moreover, along with eHiTS and VMD, our application uses OpenBabel software to interconvert various formats that code molecule geometries.


Usage
-------------

The eHiTS-to-VMD application has to be copied into folder created by eHiTS. The default folder where the results generated by eHiTS are saved is $HOME/ehits_work/results/receptor_input_filename/. The OpenBabel software used to convert formats refers by default to folder /usr/bin. 

* -i --inputDir

	Input direcotry

* -o --outputDir

 	Output direcotry

* -l --log

	Logs

* -a --action

	eHiTS-to-VMD runs with one of the following actions:

	* all: This option divides output files, converts files from the SDF to the PDB format, creates a script file for VMD which loads geometries of molecules with the best values of the scoring function, and generates a script file for VMD which loads geometries of 10 molecules with the best values of the scoring function. If the application is used to analyze the docking of a library of molecules to two proteins, the all option will calculate differences between the scoring function values for a given ligand docked to each of the molecules.

	* pdb: This option divides output files and converts the output file format from SDF to PDB.

	* vmd: This option creates files for two scripts for VMD. One loads geometries of molecules with the best values of the scoring function, and the other creates a VMD script file which loads geometries of 10 molecules with the best values of the scoring function. For this option to run, PDB files have to be created first (manually or automatically through the use of the PDB option).

	* clean: This option removes all files generated by eHiTS-to-VMD.

	* calc_diff: This option is useful when the interface analyzes the docking of a library of molecules to two proteins. This option calculates differences between the values of the scoring function for the results obtained for both proteins.

	* list: prints recurversly contents of directories

* -v --verbose

	Be verbose

* -h --? --help

	Display help and exit

Additional requirements
--------------------------

The eHiTS-to-VMD interface application was tested on Fedora Core, Debian, and Ubuntu distributions of the Linux operation system with 
this packages installed.

Direct dependencies (used in appplication):

 * perl with standard modules
    * File::Basename
    * File::Spec
    * Getopt::Long
    * Fatal
    * File::Find

Indirect dependencies (create and visualize data):

 * eHiTS version 5.3 - used only for vHTS;
 * VMD version 1.8.4 - used only to visualize results; 

License:
-------------

Apache License Version 2.0, January 2004 (https://tldrlegal.com/ ; http://choosealicense.com/)

