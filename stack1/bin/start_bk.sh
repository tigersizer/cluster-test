#!/bin/bash
# the entire purpose of this is the redirection
bin/bookkeeper bookie > /logs/bookkeeper1.log 2>&1
