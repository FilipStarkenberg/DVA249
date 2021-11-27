#!/bin/bash
mypath=$PATH
echo "mypath: "$mypath
echo "Separated:"
echo $mypath | sed "y/:/\n/"
