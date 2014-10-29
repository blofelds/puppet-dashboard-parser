#!/bin/bash
#
# GS 9/9/2014
#
# Script to assist querying and displaying pending nodes from puppet dashboard in a format
# friendly for use with Mcollective.

if [ ! -f ~/.domain ] || [ ! -f ~/.pdbint ] || [ ! -f ~/.pdbstg ] || [ ! -f ~/.pdbprd ] ; then
  printf "\n$(tput setaf 1)Error:$(tput sgr0) Config file not found. Ensure the following files exist;\n\n"
  printf "~/.domain   # Domain name of your managed servers\n"
  printf "~/.pdbprd   # Puppet Dashboard address, including port number\n"
  printf "~/.pdbstg   # Puppet Dashboard address, including port number\n"
  printf "~/.pdbint   # Puppet Dashboard address, including port number\n\n"
exit
fi

DOMAIN=$(<~/.domain)
INT_PDB=$(<~/.pdbint)
STG_PDB=$(<~/.pdbstg)
PRD_PDB=$(<~/.pdbprd)
TMP1=/var/tmp/$(basename $0).tmp1
TMP2=/var/tmp/$(basename $0).tmp2
TMP3=/var/tmp/$(basename $0).tmp3
FILTER=$1

function curl_nodes {
curl -s $INT_PDB/nodes/pending?per_page=all >  $TMP3
curl -s $STG_PDB/nodes/pending?per_page=all >  $TMP1
curl -s $PRD_PDB/nodes/pending?per_page=all >  $TMP2
}

function cut_n_sort {
cut -f2 -d'>' |cut -f1 -d'<' |sort
}

# for each node in the int env, grep for the nodename, print the nodename only,
# and the following 9 lines, then delete the intermediate lines with sed.
function grep_for_int {
for node in $(grep int < $TMP3 |grep $DOMAIN |cut_n_sort)
do
printf "%-37s %s \n" $(grep -oA 9 $node  $TMP3 |sed -e 2,9d)
done
}

# for each node in the queried stg env, grep for the nodename, print the nodename only,
# and the following 9 lines, then delete the intermediate lines with sed.
function grep_for_stg {
for node in $(grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort)
do
printf "%-37s %s \n" $(grep -oA 9 $node  $TMP1 |sed -e 2,9d)
done
}

# for each node in the prd env, grep for the nodename, print the nodename only,
# and the following 9 lines, then delete the intermediate lines with sed. printf formats
# red output and pads the fist string to 37 characters.
function grep_for_prd {
for node in $(grep prd < $TMP2 |grep $DOMAIN |cut_n_sort)
do
printf "$(tput setaf 1)%-37s %s $(tput sgr0)\n" $(grep -oA 9 $node  $TMP2 |sed -e 2,9d)
done
}

# for each int node, find the most recent report url, curl it, then lift the pending items
function curl_reports_int {
for node in $(grep int < $TMP3 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP3 |cut -f2 -d'"')
printf "\n$node\n"
curl -s  $INT_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |awk -F '[><]' '{print "  " $3}'
done
}

# for each stg node, find the most recent report url, curl it, then lift the pending items
function curl_reports_stg {
for node in $(grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP1 |cut -f2 -d'"')
printf "\n$node\n"
curl -s  $STG_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |awk -F '[><]' '{print "  " $3}'
done
}

# for each prd node, find the most recent report url, curl it, then lift the pending items
function curl_reports_prd {
for node in $(grep prd < $TMP2 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP2 |cut -f2 -d'"')
printf "\n$(tput setaf 1)$node$(tput sgr0)\n"
curl -s  $PRD_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |awk -F '[><]' '{print "  " $3}'
done
}

function print_prompt {
printf "\n Display pending nodes in Int, Stg1, Stg2 or Prd?\n"
printf " Or report pending changes in Int, Stg1, Stg2 or Prd?\n"
printf "\n Enter $(tput setaf 4)$(tput bold)   int  1   2 $(tput sgr0)  or$(tput setaf 4)$(tput bold) p$(tput sgr0)\n"
printf " Or enter $(tput setaf 4)$(tput bold)rint rs1 rs2$(tput sgr0) or $(tput setaf 4)$(tput bold)rp$(tput sgr0): "
read FILTER
printf "\n =================\n\n"
}

curl_nodes

# print header containing pending vs total nodes in int, stg & prd
printf  "\n Pending Int nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP3 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP3 |cut -f2 -d'>' |cut -f1 -d'<'

printf  " Pending Stg nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP1 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP1 |cut -f2 -d'>' |cut -f1 -d'<'

printf  " Pending Prd nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP2 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP2 |cut -f2 -d'>' |cut -f1 -d'<'

# if filter was not supplied as a command line argument, print prompt and read input
if [ ! $FILTER ] ; then
  printf "\n Display pending nodes in Int, Stg1, Stg2 or Prd?\n"
  printf " Or report pending changes in Int, Stg1, Stg2 or Prd?\n"
  printf "\n Enter $(tput setaf 4)$(tput bold)   int  1   2 $(tput sgr0)  or $(tput setaf 4)$(tput bold)p$(tput sgr0)\n"
  printf " Or enter $(tput setaf 4)$(tput bold)rint rs1 rs2$(tput sgr0) or $(tput setaf 4)$(tput bold)rp$(tput sgr0): "
  read FILTER
fi
printf "\n =================\n\n"

until [ $FILTER = "q" ]
do

  if [ $FILTER = "int" ] ; then
  grep_for_int
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "1" ] ; then
  grep_for_stg 1
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "2" ] ; then
  grep_for_stg 2
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "p" ] ; then
  grep_for_prd
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "rint" ] ; then
  curl_reports_int
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "rs1" ] ; then
  curl_reports_stg 1
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "rs2" ] ; then
  curl_reports_stg 2
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "rp" ] ; then
  curl_reports_prd
  printf "\n =================\n"
  print_prompt

  else
  echo "Invalid input"
  print_prompt
  fi

done

rm $TMP1 $TMP2 $TMP3
