#!/usr/bin/perl


# Author: Tomasz Gawęda
# Date:   2008-06-01
#
# Description: 
#    eHiTS-to-VMD is an interface between eHiTS software for virtual 
#    high-throughput screening and VMD graphic software used to visualize 
#    calculation results.
# 
# Paper: 
#    eHiTS-to-VMD Interface Application. The Search for Tyrosine-tRNA Ligase Inhibitors. 
#    Krystian Eitner, Tomasz Gawęda, Marcin Hoffmann, Mirosława Jura, Leszek Rychlewski and Jan Barciszewski
#    J Chem Inf Model. 2007 Mar-Apr;47(2):695-702 ; 
#    DOI: 10.1021/ci600392r ; 
#    PMID: 17381179 (http://www.ncbi.nlm.nih.gov/pubmed/17381179) ;
# 
# License: 
#    Apache License Version 2.0, January 2004 (https://tldrlegal.com/ ; http://choosealicense.com/)

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Getopt::Long;
use Fatal qw( open close mkdir opendir closedir);
Getopt::Long::Configure(qw{no_ignore_case});

my $progname = $0;
$progname =~ s/(\S+)\..*/$1/g;
my $version = q { $Revision: 0.1 $ };
$version =~ s/^[^0-9]+([0-9\.]+).*$/$1/g;
my $date    = q { 2008.06.01 };
my $purpose = q { "" };

### Globals:
my ( $inputDirName, $help, $verbose, $outDirName, @actions, $logs );
my %adone;
my %todo;
my %files = ( 'sdf' => [], 'scores' => [] );

### Functions:

## Usage
sub usage {
	print "$0\n";
	print "Options\n\n";
	print <<USAGE
	-i, --inputDir [dir]
	-o, --outputDir [dir]
	-l, --log [file]		
	-a, --action [action1 action2 action3 ...]
		'list'  - like find .
		'clean' -  info about cleaning results

		'all'   - all actions
		'pdb'   - only convert sdf file to pdb
		'vmd'   - create vmd file
		'diff'  - calc diff

USAGE
;


	exit(1);
}

## Create directory with full path
sub mkdirp {
	my ($path) = @_;
	my @dirs = split( /\\|\//, $path );
	my $d = shift @dirs;    # due to bug in catfile
	mkdir( $d, 0755 ) unless -d $d;
	for (@dirs) {
		$d = File::Spec->catfile( $d, $_ );
		mkdir( $d, 0755 ) unless -d $d;
	}
}

## My system function
sub mySystem {
	my @args = @_;
	my $d =
	    join( ' ', @args ) 
	  . " 2>&1 " . "1>>"
	  . File::Spec->catfile( $outDirName, '_convert.log' );
	$d = qx/$d/;

	# . "\n";

	#system(@args);
	if ( $? != 0 and not( $? >> 8 ) ) {
		warn "Something went wrong - command: " . join( ' ', @args ) . "\n";
	}
}

## Do recursive directory traverse
sub processDir {
	my ( $dir, $subroutine ) = @_;
	opendir DIR, $dir or return;
	print <DIR> if 0;    # dummy
	my @contents = map File::Spec->catfile( $dir, $_ ), sort grep !/^\.\.?$/,
	readdir DIR;
	closedir DIR;
	return if scalar(@contents) == 0;
	foreach my $file (@contents) {
		if ( -f $file ) {
			$subroutine->($file);
		}
		next if ( -l $file ) || ( not -d $file );
		processDir( $file, $subroutine );
	}
}

## Actions
sub listFile {
	my ($file) = @_;
	die "list: File $file doesn't exists\n" if not -f $file;
	print $file. "\n";
	return;
}

## Do clean up
sub clean {
	print
	  "If you want to clean the file you should delete -out dir, but if your"
	  . " input and output direcotry were the same, you should run: \n\n"
	  . ' find . \( -type d -a \( -iname sdf -o -iname pdb \) \) -exec rm -fr "{}" \;'
	  . "\n"
	  . ' find . -type f -a \( -iname "_convert.log" -o -iname "_error.log" \) -exec rm "{}" \;'
	  . "\n"
	  . ' rm $vmd_file $ehit_file $diff_file $best_vmd_file' . "\n";
	exit(0);    # must be exit
}

## Generate score file
sub makePDBVMDs {
	my ($files) = @_;
	local $/ = '$$$$' . "\n";    # something like IFS - very hackish ;)

	print <VMD> . <VMDBEST> . <ALLSCORES> if 0;    # dummy

	open( ALLSCORES, '>', File::Spec->catfile( $outDirName, 'allScores.txt' ) );

	if ( exists( $todo{'vmd'} ) ) {
		open( VMD,     '>', File::Spec->catfile( $outDirName, 'allOut.vmd' ) );
		open( VMDBEST, '>', File::Spec->catfile( $outDirName, 'best.vmd' ) );
	}

	if ( scalar @{$files} == 0 ) {
		print "No files to convert\n";
		return;
	}

	for my $file ( @{$files} ) {
		my $baseDir = File::Basename::dirname($file);
		$baseDir =~ s/$inputDirName/$outDirName/;    # change root

		# without root
		my $loadDir = $baseDir;
		$loadDir =~ s/[\/\\]?$outDirName[\/\\]?//;    # del root

		my $SDFDir = File::Spec->catfile( $baseDir, 'sdf' );
		my $PDBDir = File::Spec->catfile( $baseDir, 'pdb' );

		mkdirp($SDFDir);
		mkdirp($PDBDir);

		open( BIGSDF, '<', $file );    # full sdf file (ehits generated)
		                               # output file for each sdf
		print <BIGSDF> if 0;           # dummy entry - warnings sux

		my $SDFFname;
		my $PDBFname;
		my $VMDF;
		my $i = -1;
		while ( my $molecule = <BIGSDF> ) {

			$i++;
			$SDFFname =
			  File::Spec->catfile( $SDFDir, sprintf( "%0.5d.sdf", $i ) );
			$PDBFname =
			  File::Spec->catfile( $PDBDir, sprintf( "%0.5d.pdb", $i ) );
			$VMDF = File::Spec->catfile( $loadDir, sprintf( "%0.5d.sdf", $i ) );

			open( SMALLSDF, '>', $SDFFname );
			print SMALLSDF $molecule;
			print SMALLSDF if 0;
			close(SMALLSDF);    # close file

			if ( exists $todo{'pdb'} ) {
				my @r =
				  ( 'babel', '-i', 'sdf', $SDFFname, '-o', 'pdb', $PDBFname );
				mySystem(@r);    # do babel conversion to pdb file
			}

			#best vmd
			if ( $i < 10 ) {

				#eHiTS-Pose: 1 eHiTS-Score: -2.920280 by SimBioSys Inc.
				if ( $molecule =~ m/eHiTS-Score:\s+([-+]?\d+.\d+)\s+/mg )
				{                # get score
					print ALLSCORES $VMDF . "\t" . $1 . "\n";    # and save it
				}
				if ( exists $todo{'vmd'} ) {
					print VMDBEST "mol load pdb " . $VMDF . "\n" if $i == 0;
					print VMD "mol load pdb " . $VMDF . "\n";
				}
			}

		}
		close(BIGSDF);

		print "file: " . $file . " divided into " . ( $i + 1 ) . " sdf files\n";
	}
	if ( exists( $todo{'vmd'} ) ) {
		close(VMDBEST);
		close(VMD);
	}
	close(ALLSCORES);
	return;
}

## Strip data from ehits log
sub getInfo {
	my ($line) = @_;
	my @return;

	if (
		$line =~ /Top-rank:.*?(\S+)([\/\\])\S+\.sdf.*?Score:\s+([-+]\d+\.\d+)/ )
	{
		my @tmp = split /[\/\\]/, $1;

		# if you need more directories in result change [-4 .. -1] to sth else
		push @return, join( $2, @tmp[ -4 .. -1 ] );
		push @return, $3;
	}
	return @return;
}

## calculate difference
sub diff {
	print "Searching for scores files\n";
	my @scores = @{ $_[0] };

	#processDir( $inputDirName, sub{ push @scores, $_[0] if $_[0]=~/[\/\\]scores\.txt$/ ; } );
	print "Found this score.txt files: " . join( ", ", @scores ) . "\n";
	die "Not enought or too many scores files - must be exactly 2\n"
	  if not scalar @scores == 2;
	print "Starting calculating diff ...\n";

	open( FIRST,  '<', $scores[0] );
	open( SECOND, '<', $scores[1] );

	mkdirp($outDirName) if not -d $outDirName;
	my $diffFname = File::Spec->catfile( $outDirName, 'diffScore.txt' );

	open( RESULT, '>', $diffFname );
	print <FIRST> . <SECOND> . <RESULT> if 0;    # dummy
	     # it's quite temporary solution anyone could provide me a better one?
	while ( my ( $first, $second ) = ( scalar <FIRST>, scalar <SECOND> ) ) {
		last if not defined $first or not defined $second;

		#print $first."\n";
		#print $second."\n";

		my @x = getInfo($first);
		my @y = getInfo($second);

		#print join("==", @x)."\n";
		#print join("==", @y)."\n";

		print RESULT "$x[0] - $y[0]  = " . ( $x[1] - $y[1] ) . "\n";

	}
	close(RESULT);
	close(SECOND);
	close(FIRST);
	return;
}

## Get files
sub getFiles {
	my ($file) = @_;

	if ( $file =~ /\.sdf$/ ) {
		push( @{ $files{'sdf'} }, $file );
		return;
	}
	if ( $file =~ /[\/\\]scores\.txt$/ ) {
		push( @{ $files{'scores'} }, $file );
		return;
	}

}

## Main function
sub main {

	usage() if ( scalar @ARGV < 1 );
	GetOptions(
		"i|inputDir=s"  => \$inputDirName,
		"o|outputDir=s" => \$outDirName,
		"l|log=s"       => \$logs,
		"a|action=s@"   => \@actions,
		"v|verbose"     => \$verbose,
		"h|?|help"      => \$help,
	) or usage();

	# Validate command line parsing
	usage() if ( $help or ( length($inputDirName) <= 0 ) );

	# action, pre action (get list of files to process only), provides
	my %aactions = (
		'list'  => [ \&listFile, 'nothin' ],    # like find .
		'clean' => [ \&clean,    'clean' ],     # info about cleaning results

		'all'  => [ \&getFiles, 'files' ],
		'sdf'  => [ \&getFiles, 'files' ],
		'pdb'  => [ \&getFiles, 'files' ],      # only convert sdf file to pdb
		'vmd'  => [ \&getFiles, 'files' ],      # with best vmd
		'diff' => [ \&getFiles, 'files' ],      # calc diff
	);

	if ( scalar @actions == 0 ) {
		print "No action selected: assuming all.";
		push @actions, 'all';
	}

	for my $action (@actions) {
		$action = lc $action;
		$todo{$action}++;

		die "Wrong action\n" unless exists( $aactions{$action} );

		# add dummy or phony actions here
		if ( $action eq 'all' ) {
			$todo{'vmd'}  = 1;    # depends on sdf and pdb
			$todo{'diff'} = 1;

		}

		# check if some action provided data that we need
		if ( not exists( $adone{ $aactions{$action}[0] } ) ) {
			processDir( $inputDirName, $aactions{$action}[0] );
		}
	}

	if ( ( not defined $inputDirName ) or ( not -d $inputDirName ) ) {
		die("Input direcotory $inputDirName doesn't exists!\n");
	}
	else { $inputDirName =~ s/\/?$//; }

	# if output direcotry is not specified
	if ( not defined $outDirName ) {
		$outDirName = $inputDirName . '_out';
	}
	else { $outDirName =~ s/\/?$//; }

	die("Output directory ($outDirName) exists, please delete it.")
	  if -d $outDirName;

	print "Creating output directory - $outDirName\n";
	mkdirp($outDirName);

	# run the workers on data
	if (   exists( $todo{'pdb'} )
		or exists( $todo{'vmd'} )
		or exists( $todo{'sdf'} ) )
	{

		makePDBVMDs( $files{'sdf'} );
	}
	diff( $files{'scores'} ) if exists( $todo{'diff'} );

	# echo cleanup
	print "Finish\n";
}

main();
