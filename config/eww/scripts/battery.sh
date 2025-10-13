#!/bin/bash
acpi -b | awk '{print $4}' | tr -d ','
