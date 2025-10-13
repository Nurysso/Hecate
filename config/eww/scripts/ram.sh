#!/bin/bash
free | awk '/Mem/ {print int($3/$2 * 100)}'
