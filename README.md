# Mattermost Test Server with LDAP and NginX

This sets up a Mattermost server with MySQL, NginX reverse proxy, and connects it to [OpenLDAP](https://github.com/rroemhild/docker-test-openldap).

## Server Setup

1. Create your a file in this directory called `.secrets`. This file will contain your usernames and passwords and is listed in `.gitignore` so they are not published to your git repository. The file should contain the following:
    - MYSQL_ROOT_PASSWORD="<mysql root password>"
    - MYSQL_DATABASE="<Mattermost database name>"
    - MYSQL_USER="<Mattermost database user>"
    - MYSQL_PASSWORD="<Mattermost database user password>"
    - MATTERMOST_VERSION="<version of Mattermost to install>"
    - MM_ADMIN="<Mattermost admin username>"
    - MM_ADMIN_PASSWORD="<Mattermost admin user password>"

2. Add your license file to this directory, called `mattermost.license`
3. Run `vagrant up`
4. Go to `http://127.0.0.1` and log in with the credentials provided in your `.secrets` file.
5. Configure the Planet Express Team to Open Invite by going to `Main Menu` > `Team Settings` > `Allow any user with an account on this server to join`. This is required because there is no way to add all Mattermost users to a default team.
6. You can now log in using the following LDAP usernames (passwords are identical):

 - `fry`
 - `hermes`
 - `bender`
 - `zoidberg`

## Managing the Deployment

### SSH to Vagrant VM

 - `vagrant ssh`

### Connecting to MySQL Database

The MySQL database runs in the [MySQL Docker container](https://hub.docker.com/_/mysql), so you will have to connect to that prior to connecting to the database:
1. Run `docker exec -it database bash`
2. Once inside the container connect to the database with `mysql -u <Mattermost database user> -p <Mattermost database>` using the Mattermost database password.

### Useful LDAP Commands

```
# List all details of all users
ldapsearch -H ldap://localhost:10389 -x -b "ou=people,dc=planetexpress,dc=com" -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone "(objectClass=inetOrgPerson)"
# List relevent details of all users
ldapsearch -H ldap://localhost:10389 -x -b "ou=people,dc=planetexpress,dc=com" -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone "(objectClass=inetOrgPerson)" sn mail displayName uid employeeType
# List specific user
ldapsearch -H ldap://localhost:10389 -x -b "ou=people,dc=planetexpress,dc=com" -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone "(cn=John A. Zoidberg)"
```

### TODO

 - Migrate Mattermost CLI commands to use [MMCTL](https://docs.mattermost.com/manage/mmctl-command-line-tool.html)
 - Add HTTPS capability
