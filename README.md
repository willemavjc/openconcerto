# OpenConcerto database

Build and set up a Docker[ized] PostgreSQL database OpenConcerto ready.

This installation is intended for multi-user environments but can be convenient for single-user environments as a much more flexible alternative to Java H2 database.

Did you find it useful? Give it a star!

## Prerequisites

For Windows users:

- Windows 10 Professional (or Enterprise)
- Docker Desktop for Windows 2.x

For macOS and Linux users:

`make.ps1` can be easily derived into a native shell script. I have no time (and no need) for it now but if one really needs it, I may consider doing it. Feel free to contribute if you have time and skills for that, you will be welcomed.

## Installation

Download `make.ps1` and run it from any (Windows) PowerShell command interface.

Example:
```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Users\me\Desktop> ls
...
-a----       12/14/2019   6:02 PM           4166 make.ps1
...

PS C:\Users\me\Desktop> ./make.ps1
```

As of Dec. 2019, `make.ps1` will install an OpenConcerto 1.6.3 over a PostgreSQL 12.1. Both releases can be changed from the upper section of the script.

## Execution policy restriction

Depending on your Windows' current and active execution policy, you may encounter an error like the following one:
```
PS C:\Users\me\Desktop> ./make.ps1
.\make.ps1 : File C:\...\make.ps1 cannot be loaded because running scripts is disabled on this system. For more
information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ ./make.ps1
+ ~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```

For safety and security reasons, Windows now limits scripts capabilities and thus prevents itself from being harmed.

To momentarily get around this limitation, change the execution policy, run the script, and finally change it back.

Here is a complete demonstration:
```
PS C:\Users\me\Desktop> Get-ExecutionPolicy
Restricted

PS C:\Users\me\Desktop> Set-ExecutionPolicy -Scope CurrentUser Unrestricted

PS C:\Users\me\Desktop> Get-ExecutionPolicy
Unrestricted

PS C:\Users\me\Desktop> ./make.ps1
...

PS C:\Users\me\Desktop> Set-ExecutionPolicy -Scope CurrentUser Restricted

PS C:\Users\me\Desktop> Get-ExecutionPolicy
Restricted
```

Please refer to [Microsoft's documentation](https:/go.microsoft.com/fwlink/?LinkID=135170) for further details.
