# Generate SSH Keys and Set Up `authorized_keys`

This guide explains a one-line command to generate a new ECDSA SSH key pair and automatically set up the public key for authorized access on a server.

## Quick Script

**Warning:** This script will delete all existing files in the `$HOME/.ssh` directory. Use with caution.

```bash
mkdir -p $HOME/.ssh; cd $HOME/.ssh; rm -rf *; ssh-keygen -t ecdsa; mv id_ecdsa privkey; mv id_ecdsa.pub authorized_keys; chmod 600 authorized_keys; cat privkey;
```

## Command Breakdown

1.  `mkdir -p $HOME/.ssh`
    -   Ensures that the `.ssh` directory exists in the user's home directory. The `-p` flag prevents an error if the directory already exists.

2.  `cd $HOME/.ssh`
    -   Changes the current directory to `$HOME/.ssh`.

3.  `rm -rf *`
    -   **DANGER!** This command forcefully removes all files in the current directory (`$HOME/.ssh`). This is useful for a clean setup but will destroy any existing keys.

4.  `ssh-keygen -t ecdsa`
    -   Generates a new SSH key pair using the ECDSA algorithm. It will create two files: `id_ecdsa` (the private key) and `id_ecdsa.pub` (the public key).

5.  `mv id_ecdsa privkey`
    -   Renames the private key file from `id_ecdsa` to `privkey`.

6.  `mv id_ecdsa.pub authorized_keys`
    -   Renames the public key file to `authorized_keys`. This file is used by the SSH server to authenticate users.

7.  `chmod 600 authorized_keys`
    -   Sets the file permissions for `authorized_keys` to `600` (read and write for the owner only). This is a required security measure for SSH.

8.  `cat privkey`
    -   Displays the content of the private key. This is useful if you need to copy the private key to a client machine.

## Security Considerations

-   The `rm -rf *` command is destructive. If you have existing SSH keys you want to keep, do not use this part of the script.
-   This script is intended for quickly setting up a new server where you don't need to preserve old keys.
-   Always keep your private key (`privkey`) secure and do not share it with anyone.
