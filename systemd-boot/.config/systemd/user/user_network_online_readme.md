# User wait network online kinks

Basically, There's no good bridge between systemd system services and user services, so we have taken the dummy service from podman to wait until the network is up.
We also need to define a system service that waits on network-online.service to make sure it launches.


[Systemd issue explaing the need for user service](https://github.com/systemd/systemd/issues/3312)
[Podman issue explaining the need for user service](https://github.com/containers/podman/issues/22197)
[Podman systemd user service for network online](https://github.com/containers/podman/blob/main/contrib/systemd/user/podman-user-wait-network-online.service)
[Podman issue explaining the need for dummy system service](https://github.com/containers/podman/issues/24796)
