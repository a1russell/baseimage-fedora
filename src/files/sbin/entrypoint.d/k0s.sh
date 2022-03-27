#!/bin/sh

# Adapted from: https://github.com/k0sproject/k0s/blob/4484d96b2459fa72539e1ca2e726cbe1edcca076/docker-entrypoint.sh

# Ensure we have some semi-random machine-id.
if [ ! -f  /etc/machine-id ]; then
  dd if=/dev/urandom status=none bs=16 count=1 | md5sum | cut -d' ' -f1 > /etc/machine-id
fi

docker_embedded_dns_ip='127.0.0.11'
# First, we need to detect an IP to use for reaching the docker host.
docker_host_ip="$(ip -4 route show default | cut -d' ' -f3)"

# Patch docker's iptables rules to switch out the DNS IP.
iptables-save \
  | sed \
    `# Switch docker DNS DNAT rules to our chosen IP.` \
    -e "s/-d ${docker_embedded_dns_ip}/-d ${docker_host_ip}/g" \
    `# We need to also apply these rules to non-local traffic (from pods).` \
    -e 's/-A OUTPUT \(.*\) -j DOCKER_OUTPUT/\0\n-A PREROUTING \1 -j DOCKER_OUTPUT/' \
    `# Switch docker DNS SNAT rules rules to our chosen IP.` \
    -e "s/--to-source :53/--to-source ${docker_host_ip}:53/g"\
  | iptables-restore

# Now we can ensure that DNS is configured to use our IP.
cp /etc/resolv.conf /etc/resolv.conf.original
sed -e "s/${docker_embedded_dns_ip}/${docker_host_ip}/g" /etc/resolv.conf.original > /etc/resolv.conf

# Write config from environment variable.
if [ ! -z "$K0S_CONFIG" ]; then
  mkdir -p /etc/k0s
  echo -n "$K0S_CONFIG" > /etc/k0s/config.yaml
fi
