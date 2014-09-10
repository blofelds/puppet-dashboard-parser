#!/bin/bash
#
# GS 9/9/2014
#
# Script to assist querying and displaying pending nodes from puppet dashboard in a format
# friendly for use with Mcollective.

STG_PDB=$(<~/.pdbstg)
PRD_PDB=$(<~/.pdbprd)

read FILTER

if [ $FILTER = "p" ] ; then
curl -s $PRD_PDB/nodes/pending?per_page=all |cut -f2 -d'>' |cut -f1 -d'<' |\grep $DOMAIN |sort |grep prd

elif [ $FILTER = "1" ] ; then
curl -s $STG_PDB/nodes/pending?per_page=all |cut -f2 -d'>' |cut -f1 -d'<' |\grep $DOMAIN |sort |grep stg1

elif [ $FILTER = "2" ] ; then
curl -s $STG_PDB/nodes/pending?per_page=all |cut -f2 -d'>' |cut -f1 -d'<' |\grep $DOMAIN |sort |grep stg2

else
echo "Invalid input"
exit
fi
