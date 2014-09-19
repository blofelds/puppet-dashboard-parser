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

function get_stg {
grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort
}

function get_prd {
grep prd < $TMP2 |grep $DOMAIN |cut_n_sort
}

function curl_reports_stg {
for node in $(grep stg$1 < $TMP1 |grep $DOMAIN |cut_n_sort)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP1 |cut -f2 -d'"')
printf "\n  $node\n"
curl -s  $STG_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |cut_n_sort
done
}

function curl_reports_prd {
for node in $(get_prd)
do  URL=$(awk -v n=$node  'c&&!--c ; $0 ~n {c=3}' $TMP2 |cut -f2 -d'"')
printf "\n  $node\n"
curl -s  $PRD_PDB$URL | awk '/Pending \(/{bob=1;next}/<h3>/{bob=0}bob' |grep href |cut_n_sort
done
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
get_stg 1

elif [ $FILTER = "2" ] ; then
get_stg 2

elif [ $FILTER = "p" ] ; then
red_output $(get_prd)

elif [ $FILTER = "rs1" ] ; then
curl_reports_stg 1

elif [ $FILTER = "rs2" ] ; then
curl_reports_stg 2

elif [ $FILTER = "rp" ] ; then
curl_reports_prd

else
echo "Invalid input"
exit
fi
