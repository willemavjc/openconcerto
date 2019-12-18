# Customize below your environment configuration:
$IMAGE="openjdk:14-alpine"
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

docker container run --name opencc -d -p 5900:5900 -it --network=opennw -e DISPLAY=:99 -e RESOLUTION=1920x1080x24 -e PORT=5900 $IMAGE sh

if ( !$? )
{
    Write-Host "[FATAL] Cannot start an instance."
    Write-Host "[HELP.] Is port number (5900) already taken?"
    Exit
}

Write-Host "Done"
Write-Host ""

Write-Host "Docker: Set up env."

docker container exec opencc sh -c "apk --update --no-cache add curl" *> $NULL
docker container exec opencc sh -c "cd /tmp && curl -s -O https://www.openconcerto.org/fr/telechargement/`$(echo ${OPENCONCERTO} | sed -nE 's/^(\d+\.\d+)\.\d+$/\1/p')/OpenConcerto-${OPENCONCERTO}-multiposte.zip"

if ( !$? )
{
    Write-Host "[FATAL] Cannot download OpenConcerto installer."
    Write-Host "[HELP.] Is remote resource (URL) still valid and reachable?"
    Exit
}

docker container exec opencc sh -c "cd /tmp && curl -s -O https://www.openconcerto.org/fr/telechargement/`$(echo ${OPENCONCERTO} | sed -nE 's/^(\d+\.\d+)\.\d+$/\1/p')/org.openconcerto.modules.customerrelationship.lead-1.1.jar"
docker container exec opencc sh -c "cd /tmp && curl -s -O https://www.openconcerto.org/fr/telechargement/`$(echo ${OPENCONCERTO} | sed -nE 's/^(\d+\.\d+)\.\d+$/\1/p')/org.openconcerto.modules.tva-1.0.jar"

if ( !$? )
{
    Write-Host "[WARN.] Cannot download OpenConcerto modules."
    Write-Host "[HELP.] Is remote resource (URL) still valid and reachable?"
}

docker container exec opencc sh -c "cd /tmp && unzip OpenConcerto-${OPENCONCERTO}-multiposte.zip" *> $NULL
docker container exec opencc sh -c "cd /tmp && cd OpenConcerto-${OPENCONCERTO}-multiposte && mkdir Modules && mv ../org.openconcerto.modules.*.jar ./Modules" *> $NULL

docker container exec opencc sh -c "apk --update --no-cache add bash sudo xvfb x11vnc xfce4" *> $NULL

docker container exec opencc sh -c "addgroup alpine && adduser -G alpine -s /bin/bash -D alpine && echo ""alpine:alpine"" | chpasswd" *> $NULL
docker container exec opencc sh -c "echo ""alpine ALL=(ALL:ALL) NOPASSWD: ALL"" >> /etc/sudoers" *> $NULL # "sudoers" syntax: user hostname=(runas-user:runas-group) command

docker container exec opencc sh -c "cd /tmp && mv OpenConcerto-${OPENCONCERTO}-multiposte /home/alpine && chown -R alpine:alpine /home/alpine/OpenConcerto-${OPENCONCERTO}-multiposte" *> $NULL

docker container exec -u alpine opencc sh -l -c "cd ~ && mkdir .vnc && x11vnc -storepasswd alpine .vnc/passwd" *> $NULL

docker container exec opencc sh -c "cd /tmp && rm -rf OpenConcerto*" *> $NULL

Write-Host "Done"
Write-Host ""

Write-Host "Your Docker environment is now set up."
Write-Host ""
Write-Host "| What to do from now?"
Write-Host "|  o  List your containers: ""docker container ls -a"""
Write-Host "|  o  Connect to server:    ""docker container exec -u alpine -it opencc sh"""
Write-Host ""
Write-Host "The End."

#route -p add 172.16.0.0 mask 255.240.0.0 10.0.75.2
#route -p delete 172.16.0.0
#route print -4
