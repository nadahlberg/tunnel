# infra

The author's deployment of the tunnel: Pulumi on DigitalOcean, stack `dev` —
a droplet (cloud-init mirrors the repo root to `/opt/tunnel`), a reserved
IP, the DNS zone and a firewall. Merging a PR deploys; `pulumi preview` runs
on PRs, and a merged PR labeled `skip-deploy` (docs or `users` changes)
doesn't deploy. The only secrets are `PULUMI_ACCESS_TOKEN` and
`DIGITALOCEAN_TOKEN`; Caddy also gets the latter for the DNS challenge
(hardening TODO: scope a token to the zone). The domain is the
`TUNNEL_DOMAIN` repository variable, which the workflows pass through as an
environment variable; cloud-init writes it into the droplet's `.env`.

Locally:

```sh
export PULUMI_ACCESS_TOKEN=... DIGITALOCEAN_TOKEN=... TUNNEL_DOMAIN=my-tunnel.com
cd infra && pulumi up --stack dev
```

Changing any mirrored file replaces the droplet (a few minutes; open
tunnels reconnect and the reserved IP keeps DNS stable). Admin:
`ssh root@tunnel.my-tunnel.com`, then
`cd /opt/tunnel && docker compose logs -f`.
