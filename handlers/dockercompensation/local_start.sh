#!/bin/sh

# rackup --host 0.0.0.0
export SB_CVEHUB=128.130.172.213:8020
export SB_C_STRAT=image
export SB_DBURL=128.130.172.213:8080


bundle exec ruby docker_compensation.rb