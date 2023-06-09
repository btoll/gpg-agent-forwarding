FROM debian:11.7-slim

RUN useradd \
	--create-home \
    --home-dir /home/noroot \
    --uid 1000 \
	noroot

RUN apt-get update && \
	apt-get install -y \
	debsigs \
	devscripts \
	dh-make \
	openssh-server

RUN echo "StreamLocalBindUnlink yes" >> /etc/ssh/sshd_config && \
	service ssh restart

USER noroot
WORKDIR /home/noroot

COPY --chown=noroot:noroot build_deb.sh pub.key ./

# Even though we'll be forwarding the gpg-agent socket when we
# create and run the container, it still needs access to the
# public key in order for the forwarding to work.
RUN gpg --import pub.key && \
    echo no-autostart >> .gnupg/gpg.conf

ENTRYPOINT ["bash", "build_deb.sh"]

