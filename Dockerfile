FROM alpine:latest

ARG CLOUD_SDK_VERSION=302.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV CLOUDSDK_PYTHON=python3

RUN apk add --no-cache \
  openssh-server \
  bash \
  zsh \
  gawk \
  grep \
  bind-tools \
  bc \
  coreutils \
  sudo \
  python3 \
  py3-pip \
  git \
  gnupg \
  wget \
  curl \
  py3-crcmod \
  openrc \
  terraform\
  gcc \
  libffi-dev \
  python3-dev \
  openssl-dev \
  musl-dev \
  make \
  file 

# Set root password
RUN echo 'root:changeme' | chpasswd

# Setup sshd
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
RUN ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
RUN ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521
#RUN rc-update add sshd
#RUN /etc/init.d/sshd start

# Add a user
# TODO: can this be a loop for multiple users?
RUN echo "bob ALL=(ALL) ALL" >> /etc/sudoers.d/bob
RUN mkdir -p /home
RUN adduser -D bob
RUN ssh-keygen -t ed25519 -N "" -f /home/bob/.ssh/shell
cat << _E_O_F_ >> /home/bob/,ssh/authorized_key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOHjbbamg/z+ElxbO0V9jxz4xlol1Yb0vIaTLFEYSby ed25519-key-20200326
_E_O_F_
#RUN echo 'bob:changeme' | chpasswd

# Install gcloud SDK
RUN curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz -o /tmp/gcloud.tar.gz
#RUN tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz 
RUN tar -C / -xzf /tmp/gcloud.tar.gz
#RUN rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz 
RUN rm /tmp/gcloud.tar.gz
RUN echo "export PATH=$PATH:/google-cloud-sdk/bin" >> /etc/profile
RUN export PATH=$PATH:/google-cloud-sdk/bin
RUN source /etc/profile
RUN echo $PATH
RUN cat /etc/profile
RUN /google-cloud-sdk/bin/gcloud config set core/disable_usage_reporting true 
RUN /google-cloud-sdk/bin/gcloud config set component_manager/disable_update_check true 
RUN /google-cloud-sdk/bin/gcloud config set metrics/environment github_docker_image
RUN /google-cloud-sdk/bin/gcloud --version

# Install awscli
RUN pip3 install awscli

# install azure shell
RUN pip3 install azure-cli

# Setup motd
RUN echo "Welcome to the shell" > /etc/motd

# SSH login fix. Otherwise user is kicked off after login
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
