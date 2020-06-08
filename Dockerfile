FROM centos:centos7.8.2003

RUN yum -y install gcc epel-release make\
    yum -y install curl bzip2 wget python3 cmake\
    && yum clean all

ENV LANG=C
ENV CONDA_VERSION 4.8.2
ENV CONDA_MD5 87e77f097f6ebb5127c77662dfc3165e

# Create non-root user, install dependencies, install Conda
RUN useradd -d /home/anaconda -m -u 10151 anaconda \
    # for debug
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && printf "${CONDA_MD5}  Miniconda3-latest-Linux-x86_64.sh\n" > miniconda.md5 \
    && if [ $(md5sum -c miniconda.md5 | awk '{print $2}') != 'OK' ] ; then exit 1; fi \
    && mv Miniconda3-latest-Linux-x86_64.sh miniconda.sh \
    && mkdir -p /opt \
    && bash ./miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh miniconda.md5 \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && chown -R anaconda:anaconda /opt \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete \
    && /opt/conda/bin/conda clean -afy

USER  10151

# user setting for conda
RUN printf '. /opt/conda/etc/profile.d/conda.sh\n' >> /home/anaconda/.bash_profile \
    && printf 'conda activate base\n' >> /home/anaconda/.bash_profile

# install python packages
RUN . /opt/conda/etc/profile.d/conda.sh \
    && conda activate base \
    && conda install -qy numpy==1.16.4 pytables==3.6.1 pandas==0.24.2 scipy==1.3.0 scikit-learn==0.21.2 jupyter jupyterlab 2>&1 >/dev/null \ 
    && conda install -c conda-forge -qy shap==0.35.0 2>&1 >/dev/null

# copy ml files inside the container
RUN mkdir -p /home/anaconda/dataset
COPY dataset/data_train.h5 dataset/raw_data.pickle /home/anaconda/dataset/
COPY ml_training.ipynb shap_analyses.ipynb /home/anaconda/

EXPOSE 8080

WORKDIR /home/anaconda

ENV PATH '/bin:/sbin:/usr/bin'

ENTRYPOINT /opt/conda/bin/jupyter lab --no-browser --ip=0.0.0.0 --port=8080


