#!/bin/bash
#
# GS 9/9/2014
#
# Script to assist querying and displaying pending nodes from puppet dashboard in a format
# friendly for use with Mcollective.

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

curl_nodes

printf  "\n Pending Stg nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP1 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP1 |cut -f2 -d'>' |cut -f1 -d'<'

printf  " Pending Prd nodes: $(awk 'c&&!--c;/pending active/{c=2}' $TMP2 |cut_n_sort)"
printf " / "
awk 'c&&!--c;/class=.all/{c=2}' $TMP2 |cut -f2 -d'>' |cut -f1 -d'<'

printf "\n Display pending nodes in Stg1, Stg2 or Prd?\n"
read -p $' Enter  1  2 or p: ' FILTER
printf "\n =================\n\n"

if [ $FILTER = "1" ] ; then
grep stg1 < $TMP1 |grep $DOMAIN |cut_n_sort

elif [ $FILTER = "2" ] ; then
grep stg2 < $TMP1 |grep $DOMAIN |cut_n_sort

elif [ $FILTER = "p" ] ; then
red_output $(grep prd < $TMP2 |grep $DOMAIN |cut_n_sort)

else
echo "Invalid input"
exit
fi
