#!/bin/bash

function check_and_install_nodejs() {
  # nvm use latest
  if [ -z "$NVM_BIN" ]; then
    echo "Failed to use latest Node version with NVM. Please check your NVM setup."
    exit 1
  fi

  npm install -g aio
  if [ $? -ne 0 ]; then
    echo "Failed to install AIO. Please check your npm setup."
    exit 1
  fi

  aio plugins:install @adobe/aio-cli-plugin-cloudmanager
  if [ $? -ne 0 ]; then
    echo "Failed to install Cloud Manager plugin. Please check your AIO setup."
    exit 1
  fi
}

function configure_aio() {
  if [ -f cm_config.json ]; then
    aio config:set ims.contexts.aio-cli-plugin-cloudmanager cm_config.json --file --json
  fi
}

function list_envs() {
  aio cloudmanager:program:list-environments
}

function list_available_log_options() {
  aio cloudmanager:environment:list-available-log-options
}

function list_available_log_options_for_env() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 list-available-log-option <env_id>"
    exit 1
  fi
  env_id="$1"
  aio cloudmanager:environment:list-available-log-options "$env_id"
}

function download_log() {
  if [ "$#" -ne 4 ]; then
    echo "Usage: $0 download-log <env_name> <service_name> <log_name> <days>"
    exit 1
  fi
  env_name="$1"
  service_name="$2"
  log_name="$3"
  days="$4"
  aio cloudmanager:environment:download-logs "$env_name" "$service_name" "$log_name" "$days"
}

function usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -s, --setup                   Setup the environment (install Node.js, AIO, and Cloud Manager plugin)"
  echo "  -c, --configure               Configure AIO with cm_config.json"
  echo "  -p, --program                 Set the Cloud Manager program ID"
  echo "  -l, --list-envs               List available environments for the current program"
  echo "  -a, --available-log-options    List available log options"
  echo "  -o, --available-log-option <env_id>  List available log options for a specific environment"
  echo "  -d, --download-log <env_name> <service_name> <log_name> <days>  Download logs"
  echo ""
  echo "Examples:"
  echo "  $0 -s -c -p"
  echo "  $0 --list-envs"
  echo "  $0 --available-log-option my-env-id"
  echo "  $0 --download-log production my-service access-log 7"
}

# check_and_install_nodejs

options=$(getopt -o scplalo:d: \
           --long setup,configure,program,list-envs,available-log-options,available-log-option:,download-log: \
           --name "$0" \
           -- "$@" )

if [ $? != 0 ]; then
  echo "Invalid options"
  usage
  exit 1
fi

eval set -- "$options"

while true; do
  case "$1" in
    -s|--setup)
      check_and_install_nodejs
      shift ;;
    -c|--configure)
      configure_aio
      shift ;;
    -p|--program)
      # ... code to set program ID
      shift ;;
    -l|--list-envs)
      list_envs
      shift ;;
    -a|--available-log-options)
      list_available_log_options
      shift ;;
    -o|--available-log-option)
      list_available_log_options_for_env "$2"
      shift 2 ;;
    -d|--download-log)
      download_log "$2" "$3" "$4" "$5"
      shift 5 ;;
    --)
      shift
      break ;;
    *)
      echo "Invalid option: $1"
      usage
      exit 1 ;;
  esac
done
