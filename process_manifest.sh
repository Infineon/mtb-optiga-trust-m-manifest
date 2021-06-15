#! /bin/bash

set -$-ue${DEBUG+xv}

DEVOPS_BRANCH=${DEVOPS_BRANCH:-'master'}

# Download/update devops_scripts
if [[ -d devops_scripts/.git ]]; then
    cd devops_scripts
    git fetch origin && git merge --ff-only origin/master || true
    cd - >/dev/null
else
    rm -rf devops_scripts
    git clone git@git-ore.aus.cypress.com:devops/devops_scripts.git -b $DEVOPS_BRANCH
fi

# Load manifest processing environment
source devops_scripts/manifest/validate_manifest.sh

# Increase verbosity
set -x

# Validate internal manifest
validate_manifest super      mtb-optiga-trust-m-super-manifest.xml
validate_manifest middleware mtb-optiga-trust-m-mw-manifest.xml
validate_manifest app        mtb-optiga-trust-m-ce-manifest.xml

# Create public manifest from internal manifest
process_manifest super       mtb-optiga-trust-m-super-manifest.xml deploy/mtb-optiga-trust-m-super-manifest.xml
process_manifest middleware  mtb-optiga-trust-m-mw-manifest.xml    deploy/mtb-optiga-trust-m-mw-manifest.xml
process_manifest app         mtb-optiga-trust-m-ce-manifest.xml    deploy/mtb-optiga-trust-m-ce-manifest.xml

# Validate public manifest
validate_manifest super      deploy/mtb-optiga-trust-m-super-manifest.xml
validate_manifest middleware deploy/mtb-optiga-trust-m-mw-manifest.xml
validate_manifest app        deploy/mtb-optiga-trust-m-ce-manifest.xml

# Decrease verbosity
set +x

# Report diffs
for xml_output in $(find deploy  -name "*.xml"); do
    xml_input=$(basename $xml_output)
    echo "+ diff -u ${xml_input} ${xml_output}"
            diff -u ${xml_input} ${xml_output} || :
done
