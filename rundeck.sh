#!/bin/bash

#To get list of jobs with TARGET project using curl
curl -H "X-Rundeck-Auth-Token:$api_token"  http://$server_ip/api/14/project/$project_name/jobs > rundeck.xml
#To get job name and job id for each project
xml_value=$(xmlstarlet sel -t -m "//job" -v "name" -o " " -v "@id" -n rundeck.xml)
echo "$xml_value"
echo $xml_value > xml.txt
#Find exact job id of the job name
awk -v "key=$job_name" -F" " 'BEGIN {IGNORECASE = 1} {if($1 == key) print($2)}' xml.txt
job_id=$(awk -v "key=$job_name" -F" " 'BEGIN {IGNORECASE = 1} {if($1 == key) print($2)}' xml.txt)
echo "$job_id"
#Execute jobs using job id with parameters
curl -H "X-Rundeck-Auth-Token:$api_token"   -X POST http://$server_ip/api/1/job/$job_id/run -d argString=-$option_name1+$value_name1
