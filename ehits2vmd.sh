#!/bin/sh

##########################################################################
# Shellscript:  Converts some files to vmd, ehit, compute diffs
# Author     :  Tomasz Gawęda <tomasz.gaweda(at)batnet.pl>
# Date       :  2005-03-03
# Version    :  0.6.5rc5
# Category   :  Scientific Script
##########################################################################
# Description:
#
##########################################################################
#Globals:
where_am_i=`pwd`
dir_4_sdf_files="sdf"
dir_4_pdb_files="pdb"
vmd_file="plik_1.vmd"
best_vmd_file="best.vmd"
ehit_file="plik_2.ehit"
diff_file="plik3.diff"
IFS=$'\n'
##########################################################################
# Functions:
#   make_pdb_files
#   make_vmd_files
#   clean
#   make_best_vmd
#   calculate_diffs



#
# Split one big sdf file, into many smaller, and creates pdb files from it using
# babel
make_pdb_files()
{
for directory in `find . -type d` ; do
	cd $directory
	echo -n "Parsing $directory "
	#creating dirs for output
	names_of_sdf_files=`find . -maxdepth 1 -type f -iname "*.sdf"`
	#if in directory is at least one sdf file.
	if [ `echo $names_of_sdf_files | wc -l | cut -f1 -d" "` -gt 0 ] ; then
		if [ -d $dir_4_sdf_files -o -d $dir_4_pdb_files ] ; then
			echo "Run clean before! runnig script again"
			exit 1
		fi
		mkdir $dir_4_sdf_files
		mkdir $dir_4_pdb_files
	fi
	number_of_items=0
	i=0
	for file in $names_of_sdf_files ; do
		echo -n " . "
		#debug

		items_in_curr=`grep '$$$$' $file | wc -l | cut -f1 -d" "`
		#echo -e "\n\n::: $file - items: $items_in_curr \n\n"
		number_of_items=$(($number_of_items + $items_in_curr))
		#if file is empty or is not an sdf ...
		if [ $items_in_curr -eq 0 ] ; then
			continue;
		fi

		#open the source file
		exec 3<$file
		out_filename="$dir_4_sdf_files/`printf "%.5d" $i`.sdf"
		exec 4<>$out_filename
		while [ $i -lt $number_of_items ]; do
			read <&3 temp1
			echo "$temp1" >&4
			# replace the if statement  (now not)
			if [ "${temp1:0:10}" == 'eHiTS-Pose' ] ; then
				echo -e "`pwd`/$dir_4_sdf_files/`printf "%.5d" $i`.sdf\t"`echo "$temp1" | cut --delimiter=":" --fields=3` >> "$where_am_i"/m_scores.txt
			fi
			if [ "$temp1" == '$$$$' ] ; then
				#closing file
				exec 4>&-

				#mv to dirs and convert
				echo -en "`printf '%.5d' $i`.sdf\t" >>_convert.log
				babel -i "sdf" "$out_filename" -o "pdb" "$dir_4_pdb_files/`printf "%.5d" $i`.pdb" 2>>_convert.log

				#opening new file
				i=$((i+1))
				#echo $i
				out_filename="$dir_4_sdf_files/`printf "%.5d" $i`.sdf"
				exec 4<>$out_filename
			fi
		done
		#closing file descriptors
	       	exec 3<&-
       		exec 4<&-
	done
	cd $where_am_i
	echo "$number_of_items"
done
}

#
# Create vmd files from 10 first pdb and sdf files, also generates $vmd_file and
# $ehit_file
make_vmd_files()
{
for file_pdb in `find . -iname "*000[0-9].pdb"`; do
       	echo "mol load pdb $file_pdb" >> $vmd_file
       	file_sdf=`echo $file_pdb | sed s/pdb/sdf/g`
       	echo "$file_pdb eHiTS-Score:`grep "^eHiTS" $file_sdf | cut --delimiter=":" --fields=3`" >> $ehit_file
done
}

#
# Create file $best_vmd_file with patch to 000.pdb files
make_best_vmd()
{
if [ ! -f "$vmd_file" ]; then
	echo -e "You have to create vmd file first\n"
	exit 1
else
	grep -e "00000.pdb" "$vmd_file" > "$best_vmd_file"
fi
}

#
# Clean all data produced by script
clean()
{
	#Data -> sdf files, and pdb files
	#find .  \( -type d -a \( -iname "$dir_4_sdf_files" -o -iname "$dir_4_pdb_files" \) \) -print | xargs -I {} rm -fr "{}"
	# Produced some errors, but it should be uncommented
        find . \( -type d -a \( -iname "$dir_4_sdf_files" -o -iname "$dir_4_pdb_files" \) \) -exec rm -fr "{}" ";"

	#Logs
	#find . -type f -a \( -iname "_convert.log" -o -iname "_error.log" \) -print | xargs -I {} rm "{}"
	# Also produced some errors, bu it should be uncommented
	find . -type f -a \( -iname "_convert.log" -o -iname "_error.log" \) -exec rm "{}" ";"


	#Files in main directory - &> redirects stderr and stdout to a file
	rm "$vmd_file" "$ehit_file" "$diff_file" "$best_vmd_file" "minus" "minus.c" &>/dev/null
}

minus_c='
'

#
# Calculate difference between some/path/scores.txt and some/other_path/scores.txt
calculate_diffs()
{
	#create minus.c
	if [ ! -f "./minus" ]; then
		if [ ! -f "./minus.c" ]; then
cat >minus.c <<eof
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

int main (int argc , char **argv)
{
	double a=0.0,b=0.0;
  	if (argc < 3) return 1;
	a=strtod(argv[1],NULL);
	b=strtod(argv[2],NULL);
	printf("%.3f - %.3f = ",a,b);
	a-=b;
	printf("%.3f\n",a);
	return 0;
}
eof

		fi
		gcc -pedantic -Wall -lm minus.c -o minus
	fi
	#Find files ;)
	echo -n "Making diff ... "
	i=0
	scores=`find -type f -name "scores.txt"`
	if [ `echo $scores | wc -l | cut -f1 -d" "` -lt 2 ] ; then
		echo "No scores.txt (at least 2) files provided, exiting."
		exit 1
	fi
	for filename in  $scores ; do
		filenames[$i]=$filename
		i=$((i+1))
	done
	echo -e "${filenames[@]}\n"

	lines=`wc -l ${filenames[0]} | cut -f1 -d" "`
	if [ ! $lines -eq `wc -l ${filenames[1]} | cut -f1 -d" "` ]; then
		echo "File hasn't got the same size! - exiting - line 147"
		exit 1
	fi

	#creating file descriptors
	exec 3<${filenames[0]}
	exec 4<${filenames[1]}
	
	echo -e "Diff for ${filenames[0]} ${filenames[1]}" > $diff_file
	i=0
	while [ $i -lt $lines ]; do
		read <&3 temp1
		read <&4 temp2
		what1=`echo "$temp1" | sed -e 's:.*\(/.*/.*/.*/.*/\).*:\1:' -e 's:^.\(.*\).$:\1:'`
		what2=`echo "$temp2" | sed -e 's:.*\(/.*/.*/.*/.*/\).*:\1:' -e 's:^.\(.*\).$:\1:'`
		i=$(($i+1))
		echo -ne "$what1 - $what2\t" >> $diff_file
		temp1=`echo "$temp1" | cut --delimiter=: --fields 3`
		temp2=`echo "$temp2" | cut --delimiter=: --fields 3`
		echo `./minus $temp1 $temp2` >>$diff_file
	done
	# closing file descriptors
	exec 3<&-
	exec 4<&-
	echo ""
}

##########################################################################
# main:

echo -e "\nStarting $0 in $where_am_i\n"

case $1 in 
	all )  make_pdb_files
               make_vmd_files
               make_best_vmd
               #calculate_diffs
	       ;;
	       
	pdb )  make_pdb_files;;
	
	vmd )  make_vmd_files
	       make_best_vmd;;
	       
	clean ) clean;;
	
	calc_diff ) calculate_diffs;;
	
	* ) echo -e "\n\tUsage: $0 [ all | pdb | vmd | clean | calc_diff ]\n\n";;
esac
