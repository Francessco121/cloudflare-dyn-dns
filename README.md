# cloudflare_dyn_dns
Dart CLI program for dynamically updating Cloudflare DNS records with a machine's current public IP(s).

## Example
```sh
cloudflare_dyn_dns -c config.yaml
```

config.yaml:
```yaml
# User API token must have permissions:
# All zones - Zone:Read, DNS:Edit
token: '<cloudflare token goes here>'
# Zone ID (not name), get this from the dashboard of your zone
zoneId: '<cloudflare zone ID goes here>'

# Both ipv4Url and ipv6Url are optional
#
# If you don't have an IPv6 address, you can omit ipv6Url
# and vice versa for ipv4Url.
#
# These can be substituted with any URL that returns a 200 response
# with just the IP as the response body.
ipv4Url: 'https://ipinfo.io/ip'
ipv6Url: 'https://v6.ipinfo.io/ip'

# Only A and AAAA records are supported
records:
  - type: A
    name: <domain goes here>
  - type: AAAA
    name: <domain goes here>
```
