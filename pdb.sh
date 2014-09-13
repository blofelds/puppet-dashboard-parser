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
curl_nodes
printf  "\n Total Stg nodes: "
awk 'c&&!--c;/class=.all/{c=2}' $TMP1 |cut -f2 -d'>' |cut -f1 -d'<'
printf  " Total Prd nodes: "
awk 'c&&!--c;/class=.all/{c=2}' $TMP2 |cut -f2 -d'>' |cut -f1 -d'<'

printf "\n Display pending nodes in Stg1, Stg2 or Prd\n"
read -p $' Enter  1  2 or p: ' FILTER
printf "\n =================\n\n"

if [ $FILTER = "1" ] ; then
cut -f2 -d'>' < $TMP1 |cut -f1 -d'<' |\grep $DOMAIN |sort |grep stg1

elif [ $FILTER = "2" ] ; then
cut -f2 -d'>' < $TMP1 |cut -f1 -d'<' |\grep $DOMAIN |sort |grep stg2

elif [ $FILTER = "p" ] ; then
cut -f2 -d'>' < $TMP2 |cut -f1 -d'<' |\grep $DOMAIN |sort |grep prd

else
echo "Invalid input"
exit
fi
