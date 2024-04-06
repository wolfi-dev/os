#!/usr/bin/env bash
if [[ ! -f ~/.conda-initialized ]]; then
  conda init
  source ~/.bashrc
  # Create base env if it doesn't exist
  if [[ ! -d ~/conda ]]; then
    conda config --set root_prefix ~/conda
    conda create -n base
  fi
  touch ~/.conda-initialized
fi
