#!/bin/bash 

rsync -avz --remove-source-files ~/raw /media/admin/T7
rsync -avz --remove-source-files ~/hourly /media/admin/T7
