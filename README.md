# VVV Import site template
For when you just need a simple dev site to import

- Version: 0.1
- Author: Erik Joling <erik@joling.me>

## Overview
This template will allow you to create an imported WordPress website using `vvv-custom.yml`. 

But first:
1. Put the imported WordPress files in `www/{mysite}/public_html/`
2. Store the database copy in `database/backups/` as `{mysite}.sql`. 

Afterwards:
1. Manually check if the newly generated `wp-config.php` has 

## Todo
- Create more automatisation based on wp-cli
  - `wp db prefix` instead of manually setting table prefix in config
  - `wp option get siteurl` instead of manually setting source_url in config

# Configuration

```
my-site:
  repo: location_of_custom_provisioner
  hosts:
    - host_1 (primary)
    - host_2
    [...]
  custom:
    source_url: url_of_live_website (for search-replace database)
    db_tabel_prefix: wp_ (default)

```

### Example: The minimum required configuration:

```
my-site:
  repo: https://github.com/erikjoling/custom-site-template.git
  hosts:
    - my-site.test
  custom:
    source_url: http://my-site-online.com
```

