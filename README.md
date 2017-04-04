# VVV Import site template
For when you just need a simple dev site to import

## Overview
This template will allow you to create a WordPress dev environment using only `vvv-config.yml`. It imports `database/backups/{mysite}.sql` into the database. You need to drop your WordPress files in `www/{mysite}/public_html/`

# Configuration

### The minimum required configuration:

```
my-site:
  repo: https://github.com/erikjoling/vvv-import-site-template
  hosts:
    - my-site.dev
```
| Setting    | Value       |
|------------|-------------|
| Domain     | my-site.dev |
| Site Title | my-site.dev |
| DB Name    | my-site     |

## Configuration Options

```
hosts:
    - foo.dev
    - bar.dev
    - baz.dev
```
Defines the domains and hosts for VVV to listen on. 
The first domain in this list is your sites primary domain.

```
custom:
    db_name: super_secet_db_name
```
Defines the DB name for the installation.


