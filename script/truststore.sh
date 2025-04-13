#!/bin/bash

split_truststore(){
    OUTPUT_DIR=${WORKDIR}/certificates
    mkdir -p ${OUTPUT_DIR}
 
    # Split the cert file
    csplit -s -z -f "${OUTPUT_DIR}/individual-" "${TRUSTSTORE_PEM}" '/-----BEGIN CERTIFICATE-----/' '{*}'

    cd ${OUTPUT_DIR}

    for cert in $(ls individual*)
    do
        if ! openssl x509 -in $cert
        then 
            rm $cert
            continue
        fi

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
                   -e 's/[[:blank:]]+/_/g;')"
        fi

        if [ -f $commonname.pem ]; 
        then
            # TODO: Select the latest cert
            existing_subject="$(openssl x509 --noout --subject -in $commonname.pem | sed -re 's/(subject=)//g')"
            existing_issuer="$(openssl x509 --noout --issuer -in $commonname.pem | sed -re 's/(issuer=)//g')"
            existing_startdate=$(openssl x509 --noout --startdate -in $commonname.pem | sed -re 's/(notBefore=)//g')
            
            existing=$(date -d "$existing_startdate" +"%b %d %H:%M:%S %Y %Z")


            subject="$(openssl x509 --noout --subject -in $cert | sed -re 's/(subject=)//g')"
            issuer="$(openssl x509 --noout --issuer -in $cert | sed -re 's/(issuer=)//g')"
            startdate=$(openssl x509 --noout --startdate -in $cert | sed -re 's/(notBefore=)//g')
            
            current=$(date -d "$startdate" +"%b %d %H:%M:%S %Y %Z")

            if [ $existing -ge $current ]
            then
                continue
            fi

            echo "################################################################"
            echo " Replacing $commonname"
            echo " Subject    : $existing_subject"
            echo " Issuer     : $existing_issuer"
            echo " Start Date : $existing"
            echo "################################################################"
        fi
        
        openssl x509 -in $cert > $commonname.pem

        rm $cert
    done

    cd $WORKDIR
}


diff_country(){
    for cert in $(ls *.pem)
    do
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
        mv $cert $country/
    done
}


diff_type(){
    for cert in $(ls *.pem)
    do

        subject="$(openssl x509 --noout --subject -in $cert | sed -re 's/(subject=)//g')"
        issuer="$(openssl x509 --noout --issuer -in $cert | sed -re 's/(issuer=)//g')"
 
        echo $subject
        echo $issuer
        echo ""

        if [ "$subject" = "$issuer" ]
        then
            type=root
        else
            type=intermediate
        fi

        mkdir -p $type

        mv $cert $type/
    done
}


merge_truststore(){
    OUTPUT=/tmp/$MERGE_TRUSTSTORE_PEM
    mkdir -p $WORKDIR/merged

    echo "# Generated on $(date)" > $OUTPUT
    echo "" >> $OUTPUT

    for cert in $(ls *.pem)
    do
        subject="$(openssl x509 --noout --subject -in $cert | sed -re 's/(subject=)//g')"
        issuer="$(openssl x509 --noout --issuer -in $cert | sed -re 's/(issuer=)//g')"

        echo "################################################################" >> $OUTPUT
        echo "# Subject : ${subject}" >> $OUTPUT
        echo "# Issuer  : ${issuer}" >> $OUTPUT
        echo "################################################################" >> $OUTPUT 
        echo "$(openssl x509 -in $cert)" >> $OUTPUT
        echo "" >> $OUTPUT
        echo "" >> $OUTPUT

        mv $cert $WORKDIR/merged
    done

    echo "Moving $OUTPUT to $WORKDIR"
    mv $OUTPUT $WORKDIR
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
WORKDIR=/app/workspace

if [ "$1" = "" ] 
then
    print_help
    exit
elif [ "$1" = "split" ]
then
    TRUSTSTORE_PEM=$2

    split_truststore
elif [ "$1" = "diff" ]
then
    if [ "$2" = "country" ]
    then
        diff_country
    elif [ "$2" = "type" ]
    then
        diff_type
    else
        print_help
    fi
elif [ "$1" = "merge" ]
then
    MERGE_TRUSTSTORE_PEM=$2

    merge_truststore
else
    print_help
fi
