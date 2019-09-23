#!/bin/bash

CAP_DROP=ALL
CAP_ADD=chown,setuid,setgid

buildah_db0()
{
  echo -e "\nBUILDING THE DATABASE CONTAINER"
  container=$(buildah from docker.io/mongo:bionic)
  echo -e "Container name: $container \n"
  mountpoint=$(buildah mount $container)
  echo -e "Copying init file\n"
  buildah copy $container "./files/init-mongodb0.sh" "/docker-entrypoint-initdb.d/init-mongodb.sh"
  buildah copy $container "./files/init-mongodb0-post.sh" "/etc/mongo/init-mongodb0-post.sh"
  buildah copy --chown mongodb:mongodb $container "/tmp/keyfile.txt" "/etc/mongo/keyfile.txt"
  echo -e "Configuring exposed ports\n"
  buildah config --port 27017 $container
  echo -e "Adding Metadata\n"
  buildah config --label "Container"="MongoDB database Container" $container
  echo -e "Configuring\n"
  buildah run $container chmod 400 /etc/mongo/keyfile.txt
  echo -e "Commit and squash the container\n"
  buildah commit --squash $container mongodb-primary
  echo -e "Removing the container"
  buildah unmount $container
  buildah rm $container
}

buildah_dbX()
{
  echo -e "\nBUILDING THE DATABASE CONTAINER"
  container=$(buildah from docker.io/mongo:bionic)
  echo -e "Container name: $container \n"
  mountpoint=$(buildah mount $container)
  echo -e "Coping config file\n"
  buildah copy --chown mongodb:mongodb $container "/tmp/keyfile.txt" "/etc/mongo/keyfile.txt"
  echo -e "Configuring exposed ports\n"
  buildah config --port 27017 $container
  echo -e "Adding Metadata\n"
  buildah config --label "Container"="MongoDB database Container" $container
  echo -e "Configuring\n"
  buildah run $container chmod 400 /etc/mongo/keyfile.txt
  echo -e "Commit and squash the container\n"
  buildah commit --squash $container mongodb-secondary
  echo -e "Removing the container"
  buildah unmount $container
  buildah rm $container
}

buildah_delete_all()
{
  buildah rmi localhost/mongodb-primary localhost/mongodb-secondary
}

buildah_save_all()
{
  rm /tmp/mongodb*.tar
  buildah push localhost/mongodb-primary docker-archive:/tmp/mongodb-primary.tar:localhost/mongodb-primary:latest
  buildah push localhost/mongodb-secondary docker-archive:/tmp/mongodb-secondary.tar:localhost/mongodb-secondary:latest
}

create_keyfiles()
{
  openssl rand -base64 756 > /tmp/keyfile.txt
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    --build-images|--create-images)
      BUILD_C_IMAGES=$1
      shift
      ;;
    --create-keyfile)
      CREATE_KEYFILE=$1
      shift
      ;;
    --delete-images)
      DEL_ALL_I=$1
      shift
      ;;
    --save-images)
      SAVE_ALL_I=$1
      shift
      ;;
    --help)
      HELP=$1
      shift
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ "$BUILD_C_IMAGES" ]
then
  create_keyfiles
  buildah_db0
  buildah_dbX
fi
if [ "$DEL_ALL_I" ]
then
  buildah_delete_all
fi
if [ "$SAVE_ALL_I" ]
then
  buildah_save_all
fi
if [ "$HELP" ]
then
  echo -e "\nBuild MongoDB Container Images for testing a Replica Set configuration"
  echo -e "\nRequirements"
  echo -e "   Buildah Version 1.10.1"
  echo -e "\nOptions"
  echo -e "   --build-images|--create-images      builds container images using buildah"
  echo -e "   --delete-images                     deletes container images"
  echo -e "   --save-images                       saves the images as docker-archive files in /tmp"
fi