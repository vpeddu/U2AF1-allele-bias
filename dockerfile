FROM ubuntu:18.04

# install dependencies from pip

RUN apt update && \
  apt-get install -y nginx git python-setuptools python-dev && \
  apt install -y python-pip && \
  pip install pysam==0.10.0 biopython pandas


#RUN apt update && \
    #apt install -y python pip #&& \
    #pip install biopython \
    #             pysam==0.10.0 \
    #             pandas 

# Install dependencies from conda 
