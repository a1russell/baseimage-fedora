ARG yadm_version=3.5.0
ARG git_plus_version=v0.4.10
ARG k8s_version=v1.32.3
ARG k0s_version=$k8s_version+k0s.0
ARG skaffold_version=v2.15.0
ARG kustomize_version=v5.6.0
ARG k9s_version=v0.50.3

FROM fedora:41 AS updated_fedora

RUN <<EOF
set -o errexit
dnf upgrade  --assumeyes --setopt=install_weak_deps=False
dnf --quiet --assumeyes autoremove
dnf clean all
EOF

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
  python3
ENV PATH=/root/.cargo/bin:$PATH

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
  unzip \
  xclip \
  xz \
  zsh

ENV UV_TOOL_DIR=/usr/local/share/uv
ENV UV_TOOL_BIN_DIR=/usr/local/bin
RUN \
  curl --silent --show-error --fail --location https://astral.sh/uv/install.sh \
  | env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh

RUN <<EOF
/usr/sbin/install_clean dnf-plugins-core
dnf copr enable atim/starship
/usr/sbin/install_clean starship
dnf --quiet --assumeyes remove dnf-plugins-core
EOF

RUN ln --force /bin/sh /bin/dash

RUN mkdir --parents /sbin/entrypoint.d

RUN usermod --shell /usr/bin/zsh root

RUN mkdir --mode=700 --parents /root/.ssh

COPY files/opt/git-subrepo /opt/git-subrepo
ENV GIT_SUBREPO_ROOT=/opt/git-subrepo
RUN <<EOF
cp --recursive --symbolic /opt/git-subrepo/lib/* /usr/local/bin
ln --symbolic /opt/git-subrepo/share/enable-completion.sh /etc/profile.d/git-subrepo-completion.sh
mkdir --parents /usr/local/share/man/man1
ln --symbolic /opt/git-subrepo/man/man1/git-subrepo.1 /usr/local/share/man/man1/git-subrepo.1
EOF

ARG git_plus_version
RUN uv tool install --no-managed-python --no-cache git-plus@$git_plus_version

ARG yadm_version
RUN <<EOF
curl --silent --show-error --location --fail \
  --output /usr/local/bin/yadm \
  https://raw.githubusercontent.com/TheLocehiliosan/yadm/$yadm_version/yadm
chmod 755 /usr/local/bin/yadm
EOF

ARG k0s_version
RUN <<EOF
enc_ver=$(jq --raw-output --null-input --arg _ "$k0s_version" '$_ | @uri')
curl --silent --show-error --location --fail \
  --output /usr/local/bin/k0s \
  https://github.com/k0sproject/k0s/releases/download/$enc_ver/k0s-$enc_ver-amd64
chmod 755 /usr/local/bin/k0s
mkdir --parents /etc/k0s
/usr/local/bin/k0s config create > /etc/k0s/k0s.yaml
EOF
COPY --chmod=755 files/sbin/entrypoint.d/k0s.sh /sbin/entrypoint.d/

ARG skaffold_version
RUN <<EOF
curl --silent --show-error --location --fail \
  --output /usr/local/bin/skaffold \
  https://storage.googleapis.com/skaffold/releases/$skaffold_version/skaffold-linux-amd64
chmod 755 /usr/local/bin/skaffold
EOF

ARG k8s_version
RUN <<EOF
curl --silent --show-error --location --fail \
  --output /usr/local/bin/kubectl \
  https://dl.k8s.io/release/$k8s_version/bin/linux/amd64/kubectl
chmod 755 /usr/local/bin/kubectl
EOF

##region(collapsed) kustomize
ARG kustomize_version
RUN <<EOF
mkdir --parents /tmp/kustomize_$kustomize_version
curl --silent --show-error --location --fail \
  --output /tmp/kustomize_$kustomize_version/kustomize.tar.gz \
  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$kustomize_version/kustomize_${kustomize_version}_linux_amd64.tar.gz
tar --extract --gzip --file=/tmp/kustomize_$kustomize_version/kustomize.tar.gz --directory=/tmp/kustomize_$kustomize_version
cp /tmp/kustomize_$kustomize_version/kustomize /usr/local/bin/kustomize
chmod 755 /usr/local/bin/kustomize
rm --recursive --force /tmp/kustomize_$kustomize_version
EOF
##endregion

ARG k9s_version
RUN <<EOF
mkdir --parents /tmp/k9s_$k9s_version
curl --silent --show-error --location --fail \
  --output /tmp/k9s_$k9s_version/k9s.tar.gz \
  https://github.com/derailed/k9s/releases/download/$k9s_version/k9s_Linux_x86_64.tar.gz
tar --extract --gzip --file=/tmp/k9s_$k9s_version/k9s.tar.gz --directory=/tmp/k9s_$k9s_version
cp /tmp/k9s_$k9s_version/k9s /usr/local/bin/k9s
chmod 755 /usr/local/bin/k9s
rm --recursive --force /tmp/k9s_$k9s_version
EOF

RUN mkdir --parents /etc/zshrc.d
COPY files/etc/zshrc.d/80--aliases.zsh /etc/zshrc.d/
COPY files/etc/zshrc /tmp/
RUN <<EOF
echo >> /etc/zshrc
cat /tmp/zshrc >> /etc/zshrc
rm /tmp/zshrc
EOF

ENV ZNAP_HOME=/opt/zsh-snap
COPY files/opt/zsh-snap/ /opt/zsh-snap
COPY files/etc/zshrc.d/01--znap-repos.zsh /etc/zshrc.d/

COPY --chmod=755 files/sbin/entrypoint.sh /sbin/
ENTRYPOINT ["/usr/bin/tini", "--", "/sbin/entrypoint.sh"]
CMD ["/bin/zsh"]
