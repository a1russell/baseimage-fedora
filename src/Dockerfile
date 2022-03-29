ARG yadm_version=3.2.1
ARG git_plus_version=v0.4.7
ARG k0s_version=v1.23.5+k0s.0
ARG skaffold_version=v1.37.0
ARG kubectl_version=v1.23.5
ARG kustomize_version=v4.5.4
ARG k9s_version=v0.25.18

FROM fedora:36 AS updated_fedora

RUN \
  dnf upgrade \
    --assumeyes --setopt=install_weak_deps=False \
  && dnf --quiet --assumeyes autoremove \
  && dnf clean all

FROM updated_fedora AS updated_os_with_helper

COPY --chmod=700 files/usr/sbin/install_clean /usr/sbin/

FROM updated_os_with_helper AS minimal_base_image

RUN /usr/sbin/install_clean tini

FROM minimal_base_image AS dev_base_image

ENV LC_ALL=C.UTF-8

# Alternative installers and dependencies for tools installed
#  without dnf, e.g. git-plus and k0s.
RUN /usr/sbin/install_clean \
  cargo \
  iproute \
  iptables-legacy \
  python3 \
  python3-pip \
  python3-setuptools

RUN /usr/sbin/install_clean \
  cargo-doc

RUN /usr/sbin/install_clean \
  bzip2 \
  curl \
  dash \
  fzf \
  git \
  git-annex \
  git-lfs \
  gzip \
  jo \
  jq \
  just \
  less \
  man-db \
  micro \
  neovim \
  openssh-clients \
  ripgrep \
  socat \
  starship \
  xclip \
  xz \
  zsh

RUN ln --force /bin/sh /bin/dash

RUN mkdir --parents /sbin/entrypoint.d

RUN usermod --shell /usr/bin/zsh root

RUN mkdir --mode=700 --parents /root/.ssh

COPY files/opt/git-subrepo /opt/git-subrepo
ENV GIT_SUBREPO_ROOT=/opt/git-subrepo
env PATH=$GIT_SUBREPO_ROOT/lib:$PATH
env MANPATH=$GIT_SUBREPO_ROOT/man:$MANPATH
RUN \
  ln --symbolic /opt/git-subrepo/share/enable-completion.sh /etc/profile.d/git-subrepo-completion.sh; \
  mkdir --parents /usr/local/share/man/man1; \
  ln --symbolic /opt/git-subrepo/man/man1/git-subrepo.1 /usr/local/share/man/man1/git-subrepo.1

ARG git_plus_version
RUN pip install --no-cache-dir git-plus==$git_plus_version

ARG yadm_version
RUN \
  curl --silent --show-error --location --fail \
    --output /usr/local/bin/yadm \
    https://raw.githubusercontent.com/TheLocehiliosan/yadm/$yadm_version/yadm; \
  chmod 755 /usr/local/bin/yadm

ARG k0s_version
RUN \
  enc_ver=$(jq --raw-output --null-input --arg _ "$k0s_version" '$_ | @uri'); \
  curl --silent --show-error --location --fail \
    --output /usr/local/bin/k0s \
    https://github.com/k0sproject/k0s/releases/download/$enc_ver/k0s-$enc_ver-amd64; \
  chmod 755 /usr/local/bin/k0s; \
  mkdir --parents /etc/k0s; \
  /usr/local/bin/k0s config create > /etc/k0s/k0s.yaml
COPY --chmod=755 files/sbin/entrypoint.d/k0s.sh /sbin/entrypoint.d/

ARG skaffold_version
RUN \
  curl --silent --show-error --location --fail \
    --output /usr/local/bin/skaffold \
    https://storage.googleapis.com/skaffold/releases/$skaffold_version/skaffold-linux-amd64; \
  chmod 755 /usr/local/bin/skaffold

ARG kubectl_version
RUN \
  curl --silent --show-error --location --fail \
    --output /usr/local/bin/kubectl \
    https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl; \
  chmod 755 /usr/local/bin/kubectl

##region(collapsed) kustomize
ARG kustomize_version
RUN \
  mkdir --parents /tmp/kustomize_$kustomize_version; \
  curl --silent --show-error --location --fail \
    --output /tmp/kustomize_$kustomize_version/kustomize.tar.gz \
    https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$kustomize_version/kustomize_${kustomize_version}_linux_amd64.tar.gz; \
  tar --extract --gzip --file=/tmp/kustomize_$kustomize_version/kustomize.tar.gz --directory=/tmp/kustomize_$kustomize_version; \
  cp /tmp/kustomize_$kustomize_version/kustomize /usr/local/bin/kustomize; \
  chmod 755 /usr/local/bin/kustomize; \
  rm --recursive --force /tmp/kustomize_$kustomize_version
##endregion

ARG k9s_version
RUN \
  mkdir --parents /tmp/k9s_$k9s_version; \
  curl --silent --show-error --location --fail \
    --output /tmp/k9s_$k9s_version/k9s.tar.gz \
    https://github.com/derailed/k9s/releases/download/$k9s_version/k9s_Linux_x86_64.tar.gz; \
  tar --extract --gzip --file=/tmp/k9s_$k9s_version/k9s.tar.gz --directory=/tmp/k9s_$k9s_version; \
  cp /tmp/k9s_$k9s_version/k9s /usr/local/bin/k9s; \
  chmod 755 /usr/local/bin/k9s; \
  rm --recursive --force /tmp/k9s_$k9s_version

RUN mkdir --parents /etc/zshrc.d
COPY files/etc/zshrc.d/80--aliases /etc/zshrc.d/
COPY files/etc/zshrc /tmp/
RUN \
  echo >> /etc/zshrc; \
  cat /tmp/zshrc >> /etc/zshrc; \
  rm /tmp/zshrc

ENV ZNAP_HOME=/opt/zsh-snap
COPY files/opt/zsh-snap/ /opt/zsh-snap
COPY files/etc/zshrc.d/01--znap-repos /etc/zshrc.d/

COPY --chmod=755 files/sbin/entrypoint.sh /sbin/
ENTRYPOINT ["/usr/bin/tini", "--", "/sbin/entrypoint.sh"]
CMD ["/bin/zsh"]
