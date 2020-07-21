#!/bin/bash
#To get list of jobs with TARGET project using curl
#Input passing
SLEEP_TIME=10
URL_JOB_ID="http://$1/api/14/project/$3/jobs"
URL_JOB_CHECK="http://$1/api/14/project/$3/executions/running"
URL_JOB_STATUS="http://$1/api/1/execution"
#Input Passing

#To get job name of job id in rundeck
JOB_ID=$(curl -s -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_ID  | xmlstarlet sel -t -c "string(/jobs/job[name='$4']/@id)"  | sed 's/%//')
URL_RUN="http://$1/api/1/job/$JOB_ID/run"
echo  -e "\n************Rundeck Project Name : $3"
echo  -e "************Rundeck Job Name : $4"
echo  -e "************Rundeck Job ID : $JOB_ID"

#passing multiple arg to cmd using for loop
for value in $(echo $7 | tr "," "\n")
do
	   echo -e "\n************Argument Input: $value *************"
          CURRENT_JOB_ID=$(curl  -s -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
	  
	  #Checking same job id is running in rundeck or not	
	   if [ -z  "$CURRENT_JOB_ID" ]  
	   then
   		echo  -e "************ Job id $JOB_ID is not running"
 	   	 #Tiggered rundeck api with arguments using curl method		
		  curl  -s -H "X-Rundeck-Auth-Token:$2"   -X POST   $URL_RUN  -d argString=-$5+$value%20-$6+$8
               declare  "$value"=$(curl -s -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/@id)" | sed 's/%//')
		  
	
	   else
      	  	echo  -e "************ Job id $JOB_ID is running"
		
		     #Repeat check for current job status     
			 while true;  do
	    	   		if [ -z $CURRENT_JOB_ID  ]
	    	   		then
					#If current job id status is empty then break the loop
	      				break
	     		 	fi
					#display date & time for every checking status
			  	  	current_date_time=$(date '+%d/%m/%Y %H:%M:%S');
		 	  	  	echo  -e "************$current_date_time : Waiting for new resources"  
			  		
					#waiting period for perious job execution status
				   	sleep $SLEEP_TIME;
					
			  #getting job status of perious rundeck job id	   
		 	   CURRENT_JOB_ID=$(curl -s -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_CHECK | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
	  	        done
				
	    	   	 #Tiggered rundeck api with arguments using curl method		
	   		  curl  -s -H "X-Rundeck-Auth-Token:$2"   -X POST   $URL_RUN  -d argString=-$5+$value%20-$6+$8
               declare "$value"=$(curl -s -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/@id)" | sed 's/%//')
		  
	   fi		   
done
echo -e "\n********* Rundeck Job Completed ***********"

for value in $(echo $7 | tr "," "\n")
do
	curl  -s -H "X-Rundeck-Auth-Token:$2"  $URL_JOB_STATUS/"${!value}"  | xmlstarlet sel -t -o ' BUILD_ID:'  -c "string(/result/executions/execution/@id)"   -o '  BUILD_STATUS:' -c "string(/result/executions/execution/@status)"  | sed 's/%//'
echo -e "\n"
done
