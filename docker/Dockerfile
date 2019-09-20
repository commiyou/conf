# https://github.com/JAremko/alpine-vim/blob/master/alpine-vim-base/Dockerfile
ARG CENTOS_VERSION=latest
FROM centos:${CENTOS_VERSION} AS mycentos
WORKDIR /tmp

COPY . /tmp/

RUN sh -x /tmp/build.sh


ARG USER
ARG USER_ID
ARG GROUP
ARG GROUP_ID

#userdel -f ${USER} &&\
#if getent group ${GROUP} ; then groupdel ${GROUP}; fi &&\
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    groupadd -g ${GROUP_ID} ${GROUP} &&\
    useradd -l -u ${USER_ID} -g ${GROUP} ${USER} &&\
    install -d -m 0755 -o ${USER} -g ${GROUP} /home/${USER} &&\
    chown --changes --silent --no-dereference --recursive \
          ${USER_ID}:${GROUP_ID} \
        /home/${USER} \
	&&  \
	echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
;fi
USER ${USER}
WORKDIR /home/${USER}
