# `gpg-agent` Forwarding

## Setup

1. Copy your public key to the directory that contains the `Vagrantfile`.
1. Seed the `gpg-agent` with your passhprase using [`gpg-preset-passphrase`].
    + You can use the `gpg-preset-passphrase.sh` shell script for this.
1. Bring up `Vagrant` with the environment variables it needs:
    - `PACKAGE_NAME`
    - `PACKAGE_VERSION`

That's it!

For example:

```bash
$ PACKAGE_NAME=asbits PACKAGE_VERSION=1.0.0 vagrant up
```

You don't need to do anything that's discussed in the rest of this section, it's only here for context.

The `Vagrantfile` is fairly self-explanatory, and I've added some comments to make it more understandable.  It calls a `scripts/root.sh` shell script, which in turn calls another, `scripts/user.sh`.

The `conf` directly will be copied to `/home/vagrant/bash/conf/`, where `base` is the root of the `APT` repository that is created by `reprepro`.

This is the `nginx` server config that is copied to `/etc/nginx/sites-available/default`:

```nginx
server {
	root		/home/vagrant/base;
	access_log 	/var/log/nginx/repo.access.log;
	error_log 	/var/log/nginx/repo.error.log;

	## Prevent access to Reprepro's files
	location ~ /(db|conf) {
		deny 		all;
		return 		404;
	}
}
```

## Creating the Packages

To build and sign the packages remotely:

```bash
$ ssh vagrant-signing rm /run/user/1000/gnupg/S.gpg-agent
$ ssh vagrant-signing ./build.sh
```

## Logging In

If you want to log in manually rather than run the commands remotely as shown above, continue reading.

It's easiest to create a `ssh` host config that contains all the configurations that are passed on the command-line:

```config
Host vagrant-signing
        HostName                127.0.0.1
        User                    vagrant
        Port                    2222
        ForwardAgent            yes
        IdentityFile            ~/projects/vagrantfiles/debian/.vagrant/machines/default/virtualbox/private_key
        IdentitiesOnly          yes
        LogLevel                FATAL
        PasswordAuthentication  no
        RemoteForward           /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent
        StreamLocalBindUnlink   yes
        StrictHostKeyChecking   no
        UserKnownHostsFile      /dev/null
```

> Note the order of the `RemoteForward` directive:
>
> ```conf
> RemoteForward <socket_on_remote_box>  <extra_socket_on_local_box>
> ```

But, if you like to do things the hard way, here are most of the configs shown above on the command-line:

```bash
$ ssh \
    -A \
    -i ~/projects/vagrantfiles/debian/.vagrant/machines/default/virtualbox/private_key \
    -R /run/user/1000/gnupg/S.gpg-agent:/run/user/1000/gnupg/S.gpg-agent \
    -o StreamLocalBindUnlink=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -p 2222
    vagrant@127.0.0.1
```

Once logged into the virtual machine, run:

```bash
$ ./build.sh
```

If you get signing errors, see if the keys are in the `keyring` on the virtual machine:

```bash
$ gpg -K
```

If not, try logging out and back in again and re-running that `build.sh` script.

I know, I know, that's not fun, but I haven't determined yet what is going wrong.

## Debugging

If you're having trouble with the `gpg-agent` forwarding, here are some tips:

1. Make sure the public key is in the remote server's `keyring` (the `Vagrantfile` is handling this).
1. `rm /run/user/1000/gnupg/S.gpg-agent` on the remove server, logout and then login again.
    + Optionally, you can run this first 'ssh vagrant-signing rm /run/user/1000/gnupg/S.gpg-agent' and then sign in with just `ssh vagrant-signing` (if you're using the `ssh` host config, which you'd install in `$HOME/.ssh/config`).
    + The `StreamLocalBindUnlink=yes` should be handling this, but it's not.  I'm not sure why.
    + I've seen some sites saying that `StreamLocalBindUnlink` should be part of the remote server `sshd_config` file, but when I enabled that option in the virtual machine, the signing key was never available on the VM.
1. `gpg-agent` shouldn't be running on the remote machine.  You can add the following to the `gpg.conf` config on the remote machine (or, create it if it doesn't exist):
    ```bash
    $ echo no-autostart >> "$HOME./gnupg/gpg.conf"
    ```
1. Make sure the local `gpg-agent` has cached your secret key by unlocking it by running:
    `/usr/lib/gnupg/gpg-preset-passphrase --verbose --preset 24883CDCA7D5E7D9C1606552CED27A304DE8FCE4`
    + Of course, you'd need to get your `keygrip`, not use the fake one here.
    + Run this command locally **before** remoting in.
1. ~~`rm ~/.ssh/known_hosts` on the local host.~~ (`-o "UserKnownHostsFile=/dev/null"` fixes this)
1. Note that specifying a remote `bind_address` will only succeed if the server's `GatewayPorts` option is enabled (see `sshd_config(5)`).

[`gpg-preset-passphrase`]: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-gpg_002dpreset_002dpassphrase.html

