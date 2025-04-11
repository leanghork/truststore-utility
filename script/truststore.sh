#!/bin/bash

split_truststore(){
    mkdir -p ${WORKDIR}
    
    # Split the cert file
    csplit -s -z -f "${WORKDIR}/individual-" "${TRUSTSTORE_PEM}" '/-----BEGIN CERTIFICATE-----/' '{*}'

    cd ${WORKDIR}
    for cert in $(ls individual*)
    do
        # Retrieve the common name of the certificates
        commonname="$(openssl x509 --noout --subject --nameopt multiline -in $cert \
            | grep -i "commonname" \
            | sed -re 's/(commonName|[[:blank:]]=[[:blank:]])//g' \
                   -e 's/(^[[:blank:]]+)|([[:blank:]]+)$//g' \
                   -e 's/[[:blank:]]+/_/g;')"
        
        # If common name not defined use the organization unit name
        if [ "$commonname" = "" ]
        then
            commonname="$(openssl x509 --noout --subject --nameopt multiline -in $cert \
            | grep -i "organizationalUnitName" \
            | sed -re 's/(organizationalUnitName|[[:blank:]]=[[:blank:]])//g' \
                   -e 's/(^[[:blank:]]+)|([[:blank:]]+)$//g' \
                   -e 's/[[:blank:]]+/_/g;').pem"
        fi

        # Retrieve the country of issuance
        country="$(openssl x509 --noout --subject --nameopt multiline -in $cert \
            | grep -i "countryName" \
            | sed -re 's/(countryName|[[:blank:]]=[[:blank:]])//g' \
                   -e 's/(^[[:blank:]]+)|([[:blank:]]+)$//g')"

        if [ "$country" = "" ]
        then
            country="OTHERS/unknown"
        elif [ "$country" != "US" ]
        then
            country="OTHERS/$country"
        fi

        mkdir -p $country
        echo "[$country] - [$commonname]"
        mv $cert $country/$commonname.pem
    done
}


print_help(){
    echo "Usage $0 <command>"
    echo "commands:"
    echo " split    - Split the truststore to individual cert files"
    echo " validate - Validate the certificates in the directory for expiry and issuance country"
    echo " merge    - Merge all the certificates in the directory to a single truststore file"
    echo " help     - Display help menu"
}


####

if [ "$1" = "" ] 
then
    print_help
    exit
elif [ "$1" = "split" ]
then
    TRUSTSTORE_PEM=$2
    WORKDIR=$3

    split_truststore
else
    print_help
fi
