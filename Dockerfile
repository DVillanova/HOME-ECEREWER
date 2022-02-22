FROM vbosch/htr-machine:latest
RUN apt update
RUN apt install -y --fix-missing bc python-pip
RUN pip2 install scipy
WORKDIR /pidocs-soft/PyLaia/
RUN . /root/.bashrc && conda init bash && conda activate pylaia && pip install -r requirements.txt
COPY build-resource/* /pidocs-soft/PyLaia/
RUN mkdir -p /root/directorioTrabajo
VOLUME  /root/directorioTrabajo/
RUN . /root/.bashrc && conda init bash && pip install -r /pidocs-soft/PyLaia/requirements.txt
RUN apt-get install -y locales && locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
#INSTALL SRILM
RUN mkdir /opt/srilm
WORKDIR /opt/srilm
COPY srilm-1.7.3.tar.gz .
RUN tar xzvf srilm-1.7.3.tar.gz && sed -i '1iSRILM = /opt/srilm' Makefile && \
make && make World
#Incluide additional scripts and srilm
ENV PATH="/root/directorioTrabajo/TFM-NER/scripts/:/opt/srilm/lm/bin/i686-m64/:${PATH}"
WORKDIR /root/directorioTrabajo/TFM-NER/ 
CMD . /root/.bashrc && conda init bash && bash
