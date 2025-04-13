# Truststore Utility

## Feature

### split
**Usage:** ```truststore.sh split <truststore pem file>```

### diff
- Certificate type <br>
**Usage:**
```truststore.sh diff type```
- Country of Issuance <br> 
**Usage:**
```truststore.sh diff country```
- Expired <br>
**Usage:**
```TODO```

### Merge
**Usage:** ```truststore.sh merge <truststore pem file>```


## Execution using Docker

### Build the docker image
```docker build -t truststore-util:latest .```


### Run using docker


#### Split the truststore file to individual certificates
> [!NOTE]
> **Pre-requisite**
> - Mount the directory where the truststore file is located
> - Use the truststore file name as the script argument
```
docker run --rm \
--mount type=bind,src=$(pwd),dst=/app/workspace \
truststore-util:latest split truststore.pem
```

#### Differentiate the certificates by Certificate Type
> [!NOTE]
> **Pre-requisite**
> - Mount the directory containing the certificates to be differentiated
```
docker run --rm \
--mount type=bind,src=$(pwd)/certificates,dst=/app/workspace \
truststore-util:latest diff type
```

#### Differentiate the certificates by Country of Issuance
> [!NOTE]
> **Pre-requisite**
> - Mount the directory containing the certificates to be differentiated
```
docker run --rm \
--mount type=bind,src=$(pwd)/certificates,dst=/app/workspace \
truststore-util:latest diff country
```

#### Merge certificate to a single truststore file

> [!NOTE]
> **Pre-requisite**
> - Mount the directory containing the certificates to be merged
> - Define the merged truststore file name
```
docker run --rm \
--mount type=bind,src=$(pwd)/certificates,dst=/app/workspace \
truststore-util:latest merge truststore.pem
```