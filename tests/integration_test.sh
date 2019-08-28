#!/bin/bash

cd $(dirname $(readlink -f "$0"))

ALGERNON_PORT=8080

inspect() {

  echo ""
  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk  '{print($1)}')
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    c=$(docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d})
    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    printf "%-40s - %s\n"  "${c}" "${s}"
  done
}

# wait for
#
wait_for_algernon() {

  echo -e "\nwait for algernon"

  # now wait for ssh port
  RETRY=40
  until [[ ${RETRY} -le 0 ]]
  do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${ALGERNON_PORT}" 2> /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 5s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not connect to the algernon instance"
    exit 1
  fi
  echo ""
}

send_request() {

  curl \
    --insecure \
    --location \
    --head \
    localhost:${ALGERNON_PORT}

  http_response_code=$(curl \
      --write-out %{response_code} \
      --silent \
      --output /dev/null \
      http://localhost:${ALGERNON_PORT})

  if [[ ${http_response_code} -eq 200 ]]
  then
    echo "algernon is ready to serve"
  fi
}


running_containers=$(docker ps | tail -n +2 | grep -c algernon)

if [[ ${running_containers} -eq 1 ]]
then
  inspect
  wait_for_algernon

  send_request

  exit 0
else
  echo "please run "
  echo " make start"
  echo "before"

  exit 1
fi


