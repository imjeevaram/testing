#!/bin/bash
#To get list of jobs with TARGET project using curl
SERVER_IP=rundeck.corp.theplatform.com:4443
API_TOKEN=Z0U3nkS6ryPO6kumtr9ZXVOXowjkwoHO
PROJECT_NAME=Automation_Testing
RUNDECK_JOB_NAME=import_jobs
SERVICE_VALUE=chkt

#Input passing
SERVICE_NAME=Service
SLEEP_TIME=10
URL_TIME_OUT=30
OUTPUT_FILE=import_output.txt
echo  -e "\nRundeck Project Name:- $PROJECT_NAME"
echo  -e "Rundeck Job Name:- $RUNDECK_JOB_NAME"
URL_JOB_ID="https://$SERVER_IP/api/14/project/$PROJECT_NAME/jobs"
URL_JOB_CHECK="https://$SERVER_IP/api/14/project/$PROJECT_NAME/executions/running"
URL_JOB_STATUS="https://$SERVER_IP/api/1/execution"
#Input Passing
#To get job name of job id in rundeck
JOB_ID=$(curl  -s -S  -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$API_TOKEN"  $URL_JOB_ID  | xmlstarlet sel -t -c "string(/jobs/job[name='$RUNDECK_JOB_NAME']/@id)"  | sed 's/%//' ) 
URL_RUN="https://$SERVER_IP/api/1/job/$JOB_ID/run"
JOB_URL="https://$SERVER_IP/project/$PROJECT_NAME/job/show/$JOB_ID"
if [ -z  "$JOB_ID" ]
then
	echo "***Unable to get Rundeck Job URL.Please check rundeck server***"
else	
	echo  -e "Import Job ID:- $JOB_ID"
	count=0
#passing multiple arg to cmd using for loop
for value in $(echo $SERVICE_VALUE | tr "," "\n")
do
	   echo -e "Service name:- $value"
          CURRENT_JOB_ID=$(curl   -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$API_TOKEN"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/job[name='$RUNDECK_JOB_NAME']/@id)" | sed 's/%//')
         	  
	  #Checking same job id is running in rundeck or not	
	   if [ -z  "$CURRENT_JOB_ID" ]  
	   then
 	   	 #Tiggered rundeck api with arguments using curl method		
                build_id[$count]=$(curl -s -S  -k  -H "X-Rundeck-Auth-Token:$API_TOKEN"   -X POST   $URL_RUN  -d argString=-$SERVICE_NAME+$value | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')
			   ((count+=1));	
	   else
		#waiting period for perious job execution status
	   	sleep $SLEEP_TIME;
	  #getting job status of perious rundeck job id	   
 	   CURRENT_JOB_ID=$(curl  -s -S -k  -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$API_TOKEN"   $URL_JOB_CHECK | xmlstarlet sel -t -c "string(/executions/execution/job[name='$RUNDECK_JOB_NAME']/@id)" | sed 's/%//')
		     #Repeat check for current job status     
			
	    	   		if [ -z $CURRENT_JOB_ID  ]
	    	   		then
			    	   	 #Tiggered rundeck api with arguments using curl method		
				build_id[$count]=$(curl -s -S  -k  -H "X-Rundeck-Auth-Token:$API_TOKEN"   -X POST   $URL_RUN  -d argString=-$SERVICE_NAME+$value | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')
							 ((count+=1));					  	
				else
					sleep $SLEEP_TIME;
					for id in "${build_id[@]}"
					do
						IMPORT_JOB_STATUS=$(curl  -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$API_TOKEN"  $URL_JOB_STATUS/$id  | xmlstarlet sel -t   -c "string(/result/executions/execution/@status)"    | sed 's/%//'  )
					done
					echo -e "Import Job Build Status:- $import_status"
					#Rundeck Job checking 
					echo -e "\n\nRundeck import deployment job service( $value ) is running more than threshold.So,please check import job configuration in Rundeck server\nJob url link as, $JOB_URL  \n" 
					exit 
			       fi		
	   fi		   
done
sleep $SLEEP_TIME;
for id in "${build_id[@]}"
do
	
	IMPORT_JOB_STATUS=$(curl  -s -S -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$API_TOKEN"  $URL_JOB_STATUS/$id  | xmlstarlet sel -t    -c "string(/result/executions/execution/@status)"    | sed 's/%//'  )
done
fi
echo -e "Import Job Build Status:- $import_status"
