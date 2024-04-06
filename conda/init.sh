#!/usr/bin/env bash
if [[ ! -f ~/.conda-initialized ]]; then
  conda init
  source ~/.bashrc
  touch ~/.conda-initialized
fi
