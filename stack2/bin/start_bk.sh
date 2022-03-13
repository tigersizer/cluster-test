#!/bin/bash
# the entire purpose of this is the redirection
bin/bookkeeper bookie > /logs/bookkeeper2.log 2>&1
