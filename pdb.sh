#!/bin/bash
#
# GS 9/9/2014
#
# Script to assist querying and displaying pending nodes from puppet dashboard in a format
# friendly for use with Mcollective.

STG_PDB=$(<~/.pdbstg)

curl -s $STG_PDB/nodes/pending?per_page=all |cut -f2 -d'>' |cut -f1 -d'<' |\grep $DOMAIN |sort
