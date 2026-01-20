# AK6EU's Wavelog scripts

Setting up and maintaining a Wavelog instance isn't always as straightforward as I'd like. That's why these scripts exist.

## How to use

1. Clone the repo by running `git clone https://github.com/posimagi/wavelog-scripts.git`
2. Run `sudo ./scripts/step-1-configure-environment.sh` from the repo root
3. Go to `http://localhost:8086` in your browser and follow the instructions on screen
4. Run `sudo ./scripts/step-2-extract-configuration-files.sh` from the repo root
5. Make any configuration changes you want in `config/config.php` and/or `config/wavelog.php`
6. Run `./scripts/apply-configuration-changes.sh`
7. When you want to update Wavelog, run `./scripts/update-wavelog.sh`

### Wavelog Ping Healthcheck

To setup health check monitoring, [create a project with healthchecks.io](https://healthchecks.io/docs/), then:
1. modify `scripts/monitor_health.sh` with the appropriate `HCURL` and `WAVELOG_URL`
2. Run `sudo cp systemd /etc/systemd/system -r` to move systemd config. If you are not going to use the borgmatic config, leave out those .service and .timer files.
3. Run `systemctl start wavelog-ping.timer`

This should check over-the-internet that your wavelog instance is available and returning a `200 OK` status code. If it is, it'll ping with a success; if it isn't, it'll ping with a failure and tell healthchecks.io what status code it received in the body.

### Setup backups

1. Install borgbackup and borgmatic; on Debian-based OSes, this can be done by running `sudo apt install borgbackup borgmatic`
2. Open `backup/backups-config.yaml`
3. Under constants, set wavelog_script_path to the directory path for `/wavelog-scripts/`
4. Change `repositories` to an actual remote or local
5. Change `encryption_passphrase` to the actual passphrase you'll use for your repositories.
6. Change `ssh_command` to use the path of the actual ssh key you'll use for ssh to remote repositories.
7. Change the time intervals you'd like to keep (see `keep_daily`, `keep_monthly`, `keep_yearly`, etc.)
8. Change `healthchecks: ping_url` to use the actual healthchecks ping url if you use healthchecks, or comment it out.
9. Run `cp backup/backups-config.yaml /etc/borgmatic.d/backups-config.yaml`. You may need to make the `borgmatic.d` directory if it doesn't already exist.
10. Run `borgmatic config validate` to confirm files are valid.

This sets up borgmatic config. Now, you need to setup system.d timers to run borgmatic:

1. Configure `systemd/wavelog-ping.timer` as desired to set the frequency and time of backups. By default, it backs up once-per-day at 0420z.
2. Run `sudo cp systemd /etc/systemd/system -r`. If you are not going to use the ping healthcheck config, leave out those .service and .timer files.
3. Run `sudo systemctl enable --now borgmatic-wavelog.timer`.

Borgmatic should now automatically run.

#### Troubleshooting Borgmatic
* Error: `borg.locking.LockFailed: Failed to create/acquire the lock /mnt/backups/repository/lock.exclusive ([Errno 13]`
  * Fix: Verify that the user account borg is running under has access to the directory. For instance, if borg is running as root, then root needs access to the directory to lock it.

* Error: `Remote: Host key verification failed.
Connection closed by remote host. Is borg working on the server?`
  * Fix: ssh is running in BatchMode, so there is no prompting to accept the Host fingerprint. Verify that the host fingerprint is in `~/.ssh/known_hosts`. If it's not, connect manually and accept it.
      * Borg could also be running under `root`; if this happens, then root must also have the remote as a known host. Check `/root/.ssh/known_hosts`. If it's missing, connect manually as root and accept the fingerprint, then try again.

* Error: `borg.remote.ConnectionClosedWithHint: Connection closed by remote host. Is borg working on the server?`
  * Fix: Verify that both the host and the remote have the same version of borg. Run `borg --version` on both machines.
