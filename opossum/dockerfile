FROM ubuntu:18.04

# Install dependencies

RUN apt update && \
  apt-get install -y nginx git python-setuptools python-dev && \
  apt install -y python-pip wget unzip && \
  pip install pysam==0.10.0 

# Get Opossum python files

RUN wget https://github.com/BSGOxford/Opossum/archive/master.zip -O Opossum.zip && \
  unzip Opossum.zip

CMD ["/bin/bash"]
#RUN apt update && \
    #apt install -y python pip #&& \
    #pip install biopython \
    #             pysam==0.10.0 \
    #             pandas 

# Install dependencies from conda 
