#!/bin/bash

dir=`pwd`
core=$1

if [ "$1" == "-h" ]; then
    echo
    echo "Usage: load_core.sh [corename]"
    echo "Corename defaults to the name of the current directory"
    echo "Solr url comes from either SOLR_URL (to a core) or SOLR_BASE"
    echo "(e.g., 'http://localhost:9000/solr')."
    echo
    exit 1
fi


if [ -z $core ]; then
    core=`basename $(pwd)`
fi

if [ -z $SOLR_ROOT ]; then
    if [ ! -z $SOLR_URL ]; then
		components=(${SOLR_URL//\// });

	SOLR_ROOT="${components[0]}/${components[1]}/${components[2]}"
    else
	SOLR_ROOT="http://localhost:8025/solr"
    fi
fi

echo -e "\n\nTargeting ${SOLR_ROOT}"
echo -e "Loading config at $dir as core $core"

curl "${SOLR_ROOT}/admin/cores?action=CREATE&name=$core&config=solrconfig.xml&dataDir=data&instanceDir=$dir&wt=json"
