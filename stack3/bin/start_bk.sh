#!/bin/bash
# the entire point of this is the redirection
bin/bookkeeper bookie > /logs/bookkeeper3.log 2>&1
