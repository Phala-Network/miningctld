# miningctld

## Overview
The daemon `miningctld` runs on a `worker`, a `controller`, or a `bridge`.

A daemon running in `controller` mode:
- handles stateful tunnels via WebSocket to provisioned daemons;
- should be able to provision a daemon by:
    - exchanging keys,
    - distributing configuration;
- establishes an RSA-entrypted tunnel within WebSocket for message exchanging after provisioned (if it be provisioned);
- exposes a set of API for management;
- manages lifecycles of provisioned daemons;
- manages `bridge` sessions;
- exposes `pruntime` of `workers` through HTTP.

A daemon running in `bridge` mode:
- should run in an environment with `pruntimes` reachable via TCP.
- establishes an RSA-entrypted tunnel within WebSocket for message exchanging after provisioned;
- manages lifecycles of `phost`;

A daemon running in `worker` mode:
- should run in an environment with a single reachable `pruntime` via TCP.
- should be provisioned by a `controller`;
- establishes an RSA-entrypted tunnel within WebSocket for message exchanging after provisioned;
- reports status to an `worker`;
- forwards messages from `pruntime` through the tunnel.

## To initialize as a controller daemon
Run `rake daemon:init_controller`.

The daemon will be configured as a `controller`, a UUID(as identity) and a RSA keypair will be generated.


## To initialize as a controlled daemon
Run `rake daemon:init ENDPOINT=https://controller.path/`.

A UUID(as identity) and a RSA keypair will be generated. The daemon will keep trying to request provisioning from the endpoint.

The daemon can also be provisioned as a `controller`.