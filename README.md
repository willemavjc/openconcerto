# OpenConcerto database

Build and set up a Docker[ized] PostgreSQL database OpenConcerto ready.

This installation is intended for multi-user environments but can be convenient for single-user environments as a much more flexible alternative to Java H2 database.

Did you find it useful? Give it a star!

## Prerequisites

For Windows users:

- Windows 10 Professional (or Enterprise)
- Docker Desktop for Windows 2.x

For macOS and Linux users:

`server.ps1` can be easily derived into a native shell script. I have no time (and no need) for it now but if one really needs it, I may consider doing it. Feel free to contribute if you have time and skills for that, you will be welcomed.

## Installation

Download `server.ps1` and run it from any (Windows) PowerShell command interface.

Example:
```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\me\Desktop> ls
...
-a----       12/18/2019  10:02 AM           4678 server.ps1
...

PS C:\Users\me\Desktop> ./server.ps1
```

As of Dec. 2019, `server.ps1` will install an OpenConcerto 1.6.3 over a PostgreSQL 12.1. Both releases can be modified from the upper section of the script.

## Execution policy restriction

Depending on your Windows' current and active execution policy, you may encounter an error like the following one:
```
PS C:\Users\me\Desktop> ./server.ps1
.\server.ps1 : File cannot be loaded because running scripts is disabled on this system. For more
information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ ./server.ps1
+ ~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```

For security (and safety) reasons, Windows now limits scripts capabilities thus preventing itself from being harmed.

To momentarily get around this limitation, change the execution policy, run the script, and finally change it back.

Here is a complete demonstration:
```
PS C:\Users\me\Desktop> Get-ExecutionPolicy
Restricted

PS C:\Users\me\Desktop> Set-ExecutionPolicy -Scope CurrentUser Unrestricted

PS C:\Users\me\Desktop> Get-ExecutionPolicy
Unrestricted

PS C:\Users\me\Desktop> ./server.ps1
...

PS C:\Users\me\Desktop> Set-ExecutionPolicy -Scope CurrentUser Restricted

PS C:\Users\me\Desktop> Get-ExecutionPolicy
Restricted
```

Please refer to [Microsoft's documentation](https:/go.microsoft.com/fwlink/?LinkID=135170) for further details.

## Useful commands

```
docker container ls -a
docker container start opendb
docker container stop  opendb
docker container exec -it -u postgres opendb sh
docker container exec -it -u postgres opendb psql OpenConcerto
```

## Visual Studio Code configuration (and others IDE)

To gain access to the freshly created database from your favorite IDE, you mainly need to point to the correct DNS name or IP address of the host OS running Docker, not the container's one. Traffic will be routed to the container via port mapping.

For Visual Studio Code:

- Install Microsoft's `PostgreSQL` extension
- Press `CTRL` + `SHIFT` + `P`
- Select `PostgreSQL: New Query`
- Select `Create Connection profile` and then enter the following values:
  - Server name: `127.0.0.1`
  - Database name: `OpenConcerto`
  - User name: `openconcerto`
  - Password: `openconcerto`
  - Port: `5432`
  - Profile name: `OpenConcerto`

From there, you now only need to type any query in any new SQL file, do a right click and select `Execute Query`.

# OpenConcerto desktop

**Please note that OpenConcerto's client (called "multiposte") support is experimental.**

This installation is intended for environments where:

- Java is not welcomed and is prefered isolated from Windows (e.g. security concerns)
- Multiple Java versions coexistence are not wanted

## Prerequisites

See OpenConcerto database section.

## Installation

Download `client.ps1` and run it from any (Windows) PowerShell command interface.

Example:
```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\me\Desktop> ls
...
-a----       12/18/2019  11:34 AM           5401 client.ps1
...

PS C:\Users\me\Desktop> ./client.ps1
```

As of Dec. 2019, `client.ps1` will install an OpenConcerto 1.6.3 over a OpenJDK 14. Both releases can be modified from the upper section of the script.

## Execution policy restriction

See OpenConcerto database section.

## Launch XDisplay

```
#!/bin/bash

nohup /usr/bin/Xvfb ${DISPLAY} -screen 0 ${RESOLUTION} -ac +extension GLX +render -noreset >/dev/null 2>&1 &
nohup startxfce4 >/dev/null 2>&1 &
nohup x11vnc -xkb -noxrecord -noxfixes -noxdamage -display ${DISPLAY} -forever -bg -rfbauth /home/alpine/.vnc/passwd -users alpine -rfbport ${PORT} >/dev/null 2>&1 &
```

## Access via VNC Viewer

```
docker inspect opencc | Select-String -Pattern "IPAddress"

route -p add 172.16.0.0 mask 255.240.0.0 10.0.75.2
route -p delete 172.16.0.0
route print -4
```

## Useful commands

```
docker container ls -a
docker container start opencc
docker container stop  opencc
docker container exec -it -u alpine opencc sh
```

# Licence

MIT
