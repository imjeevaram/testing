#!/bin/bash
#To get list of jobs with TARGET project using curl
#Input passing
SERVICE_NAME=Service
SLEEP_TIME=10
URL_TIME_OUT=30
OUTPUT_FILE=import_output.txt
echo  -e "\nRundeck Project Name:- $3"
echo  -e "Rundeck Job Name:- $4"
URL_JOB_ID="https://$1/api/14/project/$3/jobs"
URL_JOB_CHECK="https://$1/api/14/project/$3/executions/running"
URL_JOB_STATUS="https://$1/api/1/execution"
#Input Passing
#To get job name of job id in rundeck
JOB_ID=$(curl  -s -S  -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_ID  | xmlstarlet sel -t -c "string(/jobs/job[name='$4']/@id)"  | sed 's/%//' ) 
URL_RUN="https://$1/api/1/job/$JOB_ID/run"
JOB_URL="https://$1/project/$3/job/show/$JOB_ID"
if [ -z  "$JOB_ID" ]
then
	echo "***Unable to get Rundeck Job URL.Please check rundeck server***"
else	
	echo  -e "Import Job ID:- $JOB_ID"
	count=0
#passing multiple arg to cmd using for loop
for value in $(echo $5 | tr "," "\n")
do
	   echo -e "Service name:- $value"
          CURRENT_JOB_ID=$(curl   -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
         	  
	  #Checking same job id is running in rundeck or not	
	   if [ -z  "$CURRENT_JOB_ID" ]  
	   then
 	   	 #Tiggered rundeck api with arguments using curl method		
                build_id[$count]=$(curl -s -S  -k  -H "X-Rundeck-Auth-Token:$2"   -X POST   $URL_RUN  -d argString=-$SERVICE_NAME+$value | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')
			   ((count+=1));	
	   else
		#waiting period for perious job execution status
	   	sleep $SLEEP_TIME;
	  #getting job status of perious rundeck job id	   
 	   CURRENT_JOB_ID=$(curl  -s -S -k  -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
		     #Repeat check for current job status     
			
	    	   		if [ -z $CURRENT_JOB_ID  ]
	    	   		then
			    	   	 #Tiggered rundeck api with arguments using curl method		
				build_id[$count]=$(curl -s -S  -k  -H "X-Rundeck-Auth-Token:$2"   -X POST   $URL_RUN  -d argString=-$SERVICE_NAME+$value | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')
							 ((count+=1));					  	
				else
					sleep $SLEEP_TIME;
					for id in "${build_id[@]}"
					do
						IMPORT_JOB_STATUS=$(curl  -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_STATUS/$id  | xmlstarlet sel -t   -c "string(/result/executions/execution/@status)"    | sed 's/%//'  )
					done
					echo -e "Import Job Build Status:- $IMPORT_JOB_STATUS"
					#Rundeck Job checking 
					echo -e "\n\nRundeck import deployment job service( $value ) is running more than threshold.So,please check import job configuration in Rundeck server\nJob url link as, $JOB_URL  \n" 
					exit 
			       fi		
	   fi		   
done
sleep $SLEEP_TIME;
for id in "${build_id[@]}"
do
	
	IMPORT_JOB_STATUS=$(curl  -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_STATUS/$id  | xmlstarlet sel -t    -c "string(/result/executions/execution/@status)"    | sed 's/%//'  )
done
fi
echo -e "Import Job Build Status:- $IMPORT_JOB_STATUS"
