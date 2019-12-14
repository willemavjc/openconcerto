# Customize below your environment configuration:
$DATABASE="postgres:12.1-alpine"
$OPENCONCERTO="1.6.3"

# [!] WARNING: DO NOT EDIT BELOW. [!] WARNING: DO NOT EDIT BELOW. [!] WARNING: DO NOT EDIT BELOW. [!]

Clear-Host

Write-Host "| INSTALLATION NOTES (PLEASE READ):"
Write-Host ""
Write-Host "| You are about to set a complete Docker environment for ""OpenConcerto."""
Write-Host "| Your ""Docker Desktop for Windows"" must be configured and running."
Write-Host "| The installation time will depend on your machine and network capabilities."
Write-Host ""

Start-Sleep -s 5

Write-Host "INSTALLATION WILL BEGIN IN 30 SECONDS."
Write-Host "Press CTRL^C to abort now."
Write-Host ""

Start-Sleep -s 30

Write-Host "Go."
Write-Host ""

docker version *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Either ""Docker Desktop for Windows"" is not running or is not included in your PATH."
    Write-Host "[HELP.] Diagnosed from PS command: ""docker version"""
    Exit
}

Write-Host "Docker: Download database engine."

docker image pull $DATABASE *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Unexpected error."
    Write-Host "[HELP.] Are you properly logged in? Are your proxy settings properly set if any?"
    Exit
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Remove any previous installation."

docker container rm -f opendb *> $NULL
docker volume    rm    openfs *> $NULL
docker network   rm    opennw *> $NULL

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Create network and volume for database storage"

docker network create opennw *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Unexpected error."
    Write-Host "[HELP.] Does some container hold some resources on destination network?"
    Exit
}

docker volume  create openfs *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Unexpected error."
    Write-Host "[HELP.] Does some container hold some resources on destination volume?"
    Exit
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Set up database"

docker container run --name opendb -d -p 5432:5432 --network=opennw -v openfs:/var/lib/postgresql/data -e POSTGRES_PASSWORD=p455w0rd $DATABASE

if ( !$? )
{
    Write-Host "[FATAL] Unexpected error."
    Write-Host "[HELP.] Is port number (5432) already taken?"
    Exit
}

Start-Sleep -s 10 # Fix an issue with NVMe SSDs. (Container's initd async services may not be ready.)

docker container exec opendb sh -c "apk update && apk add --no-cache curl" *> $NULL
docker container exec opendb sh -c "curl -O https://www.openconcerto.org/fr/telechargement/`$(echo ${OPENCONCERTO} | sed -nE 's/^(\d+\.\d+)\.\d+$/\1/p')/OpenConcerto-${OPENCONCERTO}.sql.zip && mv OpenConcerto-${OPENCONCERTO}.sql.zip /tmp" *> $NULL
docker container exec opendb sh -c "unzip -d /tmp /tmp/OpenConcerto-${OPENCONCERTO}.sql.zip" *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Could not download OpenConcerto database installer (.sql)."
    Write-Host "[HELP.] Is resource (URL) still correct and reachable?"
    Exit
}

docker container exec -u postgres opendb sh -l -c "psql -c 'CREATE USER openconcerto WITH PASSWORD '\''openconcerto'\'';'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql -c 'CREATE DATABASE \""OpenConcerto\"" OWNER openconcerto;'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE \""OpenConcerto\"" to openconcerto;'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql OpenConcerto -f /tmp/OpenConcerto-${OPENCONCERTO}.sql" *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Could not build OpenConcerto database."
    Write-Host "[HELP.] Is database installer (.sql) readable?"
    Exit
}

Write-Host "Done"
Write-Host ""

docker container exec opendb sh -c "rm /tmp/OpenConcerto*" *> $NULL

Write-Host "Your Docker environment is now set up."
Write-Host ""
Write-Host "| What to do from now?"
Write-Host "|  o  List your containers: ""docker container ls -a"""
Write-Host "|  o  Connect to server:    ""docker container exec -u postgres -it opendb sh"""
Write-Host "|  o  Connect to database:  ""docker container exec -u postgres -it opendb psql OpenConcerto"""
Write-Host ""
Write-Host "The End."
