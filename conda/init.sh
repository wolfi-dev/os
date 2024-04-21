#!/usr/bin/env bash
if [[ ! -f ~/.conda-initialized ]]; then
  conda init 1>/dev/null
  source ~/.bashrc 1>/dev/null
  # Create base env if it doesn't exist
  if [[ ! -d ~/conda ]]; then
    conda config --set root_prefix ~/conda 1>/dev/null
    conda create -n base 1>/dev/null
  fi
  touch ~/.conda-initialized 1>/dev/null
fi
