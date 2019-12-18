# Customize below your environment configuration:
$IMAGE="postgres:12.1-alpine"
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

Write-Host "Docker: Download base image"

docker image pull $IMAGE *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Cannot reach Docker Hub."
    Write-Host "[HELP.] Are you offline? Are your proxy settings properly set if any?"
    Exit
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Remove previous containers(s)"

foreach ( $ID in (docker container ls -a | Select-String -Pattern "$IMAGE") | ForEach-Object{($_ -Split " ")[0]} )
{
    docker container rm -f $ID *> $NULL

    if ( !$? )
    {
        Write-Host "[WARN.] Cannot remove an older instance."
        Write-Host "[HELP.] Does some application or network hold some resources on container?"
        Write-Host "[HELP.] Container identifier: $ID"
    }
    else {
        Write-Host $ID
    }
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Build network and volume"

if ( !(docker network ls | Select-String -Pattern "opennw") )
{
    docker network create opennw *> $NULL

    if ( !$? )
    {
        Write-Host "[FATAL] Cannot create network ""opennw""."
        Write-Host "[HELP.] Does some container hold some resources on destination network?"
        Exit
    }
}

if ( !(docker volume  ls | Select-String -Pattern "openfs") )
{
    docker volume  create openfs *> $NULL

    if ( !$? )
    {
        Write-Host "[FATAL] Cannot create volume ""openfs""."
        Write-Host "[HELP.] Does some container hold some resources on destination volume?"
        Exit
    }
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Build new container"

docker container run --name opendb -d -p 5432:5432 --network=opennw -v openfs:/var/lib/postgresql/data -e POSTGRES_PASSWORD=p455w0rd $IMAGE

if ( !$? )
{
    Write-Host "[FATAL] Cannot start an instance."
    Write-Host "[HELP.] Is port number (5432) already taken?"
    Exit
}

Start-Sleep -s 10 # Fix an issue with NVMe SSDs. (Container's init.d async services may not be ready.)

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Set up env."

docker container exec opendb sh -c "apk --update --no-cache add curl" *> $NULL
docker container exec opendb sh -c "cd /tmp && curl -s -O https://www.openconcerto.org/fr/telechargement/`$(echo ${OPENCONCERTO} | sed -nE 's/^(\d+\.\d+)\.\d+$/\1/p')/OpenConcerto-${OPENCONCERTO}.sql.zip"

if ( !$? )
{
    Write-Host "[FATAL] Cannot download OpenConcerto installer."
    Write-Host "[HELP.] Is remote resource (URL) still valid and reachable?"
    Exit
}

docker container exec opendb sh -c "cd /tmp && unzip OpenConcerto-${OPENCONCERTO}.sql.zip" *> $NULL

docker container exec -u postgres opendb sh -l -c "psql -c 'CREATE USER openconcerto WITH PASSWORD '\''openconcerto'\'';'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql -c 'CREATE DATABASE \""OpenConcerto\"" OWNER openconcerto;'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql -c 'GRANT ALL PRIVILEGES ON DATABASE \""OpenConcerto\"" to openconcerto;'" *> $NULL
docker container exec -u postgres opendb sh -l -c "psql OpenConcerto -f /tmp/OpenConcerto-${OPENCONCERTO}.sql" *> $NULL

if ( !$? )
{
    Write-Host "[FATAL] Cannot build OpenConcerto database."
    Write-Host "[HELP.] Is installer (.sql) readable?"
    Exit
}

docker container exec opendb sh -c "cd /tmp && rm -rf OpenConcerto*" *> $NULL

Write-Host "Done"
Write-Host ""

Write-Host "Your Docker environment is now set up."
Write-Host ""
Write-Host "| What to do from now?"
Write-Host "|  o  List your containers: ""docker container ls -a"""
Write-Host "|  o  Connect to server:    ""docker container exec -u postgres -it opendb sh"""
Write-Host "|  o  Connect to database:  ""docker container exec -u postgres -it opendb psql OpenConcerto"""
Write-Host ""
Write-Host "The End."
