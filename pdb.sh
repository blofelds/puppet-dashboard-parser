#!/bin/bash
#
# GS 9/9/2014
#
# Script to assist querying and displaying pending nodes from puppet dashboard in a format
# friendly for use with Mcollective.

DOMAIN=$(<~/.domain)
STG_PDB=$(<~/.pdbstg)
PRD_PDB=$(<~/.pdbprd)
TMP1=/var/tmp/$(basename $0).tmp1
TMP2=/var/tmp/$(basename $0).tmp2

function curl_nodes {
curl -s $STG_PDB/nodes/pending?per_page=all >  $TMP1
curl -s $PRD_PDB/nodes/pending?per_page=all >  $TMP2
}

function cut_n_sort {
cut -f2 -d'>' |cut -f1 -d'<' |sort
}

function red_output {
printf " $(tput setaf 1)$1$(tput sgr0)\n"
}

# for each node in the queried env, grep for the nodename, print the nodename only,
# and the following 9 lines, then delete the intermediate lines with sed.
function grep_for_stg {
for node in $(grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort)
do
printf "%-37s %s \n" $(grep -oA 9 $node  $TMP1 |sed -e 2,9d)
done
}

function grep_for_prd {
for node in $(grep prd < $TMP2 |grep $DOMAIN |cut_n_sort)
do
printf "%-37s %s \n" $(grep -oA 9 $node  $TMP2 |sed -e 2,9d)
done
}

function curl_reports_stg {
for node in $(grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP1 |cut -f2 -d'"')
printf "\n  $node\n"
curl -s  $STG_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |cut_n_sort
done
}

function curl_reports_prd {
for node in $(grep prd < $TMP2 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP2 |cut -f2 -d'"')
printf "\n  $node\n"
curl -s  $PRD_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |cut_n_sort
done
}

function print_prompt {
printf "\n Display pending nodes in Stg1, Stg2 or Prd?\n"
printf " Or report pending changes in Stg1, Stg2 or Prd?\n"
printf "\n Enter $(tput setaf 4)$(tput bold)     1   2 $(tput sgr0)or $(tput setaf 4)$(tput bold) p$(tput sgr0)\n"
printf " Or enter $(tput setaf 4)$(tput bold)rs1 rs2$(tput sgr0) or $(tput setaf 4)$(tput bold)rp$(tput sgr0): "
read FILTER
printf "\n =================\n\n"
}

#curl_nodes

# print header containing pending vs total nodes in stg & prd
printf  "\n Pending Stg nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP1 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP1 |cut -f2 -d'>' |cut -f1 -d'<'

printf  " Pending Prd nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP2 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP2 |cut -f2 -d'>' |cut -f1 -d'<'

# print prompt and read input
printf "\n Display pending nodes in Stg1, Stg2 or Prd?\n"
printf " Or report pending changes in Stg1, Stg2 or Prd?\n"
printf "\n Enter $(tput setaf 4)$(tput bold)     1   2 $(tput sgr0)or $(tput setaf 4)$(tput bold) p$(tput sgr0)\n"
printf " Or enter $(tput setaf 4)$(tput bold)rs1 rs2$(tput sgr0) or $(tput setaf 4)$(tput bold)rp$(tput sgr0): "
read FILTER
printf "\n =================\n\n"

until [ $FILTER = "q" ]
do

  if [ $FILTER = "1" ] ; then
  grep_for_stg 1
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "2" ] ; then
  grep_for_stg 2
  printf "\n =================\n"
  print_prompt

  elif [ $FILTER = "p" ] ; then
  #red_output $(grep_for_prd)
  for h in $(grep_for_prd); do red_output $h ; done
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

rm $TMP1 $TMP2
