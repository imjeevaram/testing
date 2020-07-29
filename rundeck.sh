#!/bin/bash
#To get list of jobs with TARGET project using curl
# $1 --> SERVER_IP
# $2 --> API_TOKEN
# $3 --> PROJECT_NAME
# $4 --> RUNDECK_JOB_NAME
# $5 --> JOB_OPTION1
# $6 --> JOB_OPTION2
# $7 --> JOB_OPTION1_VALUE
# $8 --> JOB_OPTION2_VALUE
#Input passing
SLEEP_TIME=10
URL_TIME_OUT=30
OUTPUT_FILE=output.txt
rm -rvf $OUTPUT_FILE
URL_JOB_ID="https://$1/api/14/project/$3/jobs"
URL_JOB_CHECK="https://$1/api/14/project/$3/executions/running"
URL_JOB_STATUS="https://$1/api/1/execution"
#Input Passing
echo  -e "\n************Rundeck Project Name : $3"
echo  -e "************Rundeck Job Name : $4"
#To get job name of job id in rundeck
JOB_ID=$(curl -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_ID  | xmlstarlet sel -t -c "string(/jobs/job[name='$4']/@id)"  | sed 's/%//' )
URL_RUN="https://$1/api/1/job/$JOB_ID/run"
JOB_URL="https://$1/project/$3/job/show/$JOB_ID"

if [ -z  "$JOB_ID" ]
then
	echo "******Unable to get Rundeck Job URL.Please check rundeck server******"
else	
	echo  -e "************Rundeck Job ID : $JOB_ID"
	count=0
#passing multiple arg to cmd using for loop
for value in $(echo $7 | tr "," "\n")
do
	   echo -e "\n************Argument Input: $value *************"
          CURRENT_JOB_ID=$(curl  -s  -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
         	  
	  #Checking same job id is running in rundeck or not	
	   if [ -z  "$CURRENT_JOB_ID" ]  
	   then
   		#  echo  -e "************ Job $CURRENT_JOB_ID is not running
 	   	 #Tiggered rundeck api with arguments using curl method		
		  curl  -s -k -H "X-Rundeck-Auth-Token:$2"   -X POST   $URL_RUN  -d argString=-$5+$value%20-$6+$8
		  #sleep 5;
		  curl  -k -m $URL_TIME_OUT  -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//'
               build_id[$count]=$(curl -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"    $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')
			   ((count+=1));	
	   else
		#display date & time for  waiting period
  	  	current_date_time=$(date '+%d/%m/%Y %H:%M:%S');
	  	  	echo  -e "************$current_date_time : Waiting for new resources"  
  		
		#waiting period for perious job execution status
	   	sleep $SLEEP_TIME;
	  #getting job status of perious rundeck job id	   
 	   CURRENT_JOB_ID=$(curl -s -k  -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK | xmlstarlet sel -t -c "string(/executions/execution/job[name='$4']/@id)" | sed 's/%//')
		     #Repeat check for current job status     
			
	    	   		if [ -z $CURRENT_JOB_ID  ]
	    	   		then
			    	   	 #Tiggered rundeck api with arguments using curl method		
			   		  curl  -s -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   -X POST    $URL_RUN  -d argString=-$5+$value%20-$6+$8
			                 build_id[$count]=$(curl  -k -m $URL_TIME_OUT  -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_CHECK  | xmlstarlet sel -t -c "string(/result/executions/execution/@id)" | sed 's/%//')	 
							 ((count+=1));					  	
				else
					sleep $SLEEP_TIME;
					echo -e "\n***Build status of rundeck job***\nProject_Name: $3 \nJob_Name: $4\n"  >> $OUTPUT_FILE
					for id in "${build_id[@]}"
					do
					echo $id
						curl    -k -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"   $URL_JOB_STATUS/$id  | xmlstarlet sel -t   -o 'REGION:-' -c "string(/result/executions/execution/job/options/option[1]/@value)"  -o '   BUILD_ID:-'  -c "string(/result/executions/execution/@href)"   -o '    BUILD_STATUS:-' -c "string(/result/executions/execution/@status)"  | sed 's/%//'  >> $OUTPUT_FILE
					done
					#Rundeck Job checking 
					echo -e "\nRundeck PROJECT_NAME:$3 \n JOB_URL:$JOB_URL \n REGION:$value  \n Rundeck Job is running more than threshold.So please check rundeck server*******" >> $OUTPUT_FILE
					cat  $OUTPUT_FILE
					exit 
			       fi		
	   fi		   
done
echo -e "\n*********Job has been executed with all regions***********"
sleep $SLEEP_TIME;
echo -e "\n***Build status of rundeck job***\nProject_Name: $3 \nJob_Name: $4\n"  >> $OUTPUT_FILE
for id in "${build_id[@]}"
do
	echo $id
	curl   -k  -m $URL_TIME_OUT -H "X-Rundeck-Auth-Token:$2"    $URL_JOB_STATUS/$id  | xmlstarlet sel -t  -o "REGION:-" -c "string(/result/executions/execution/job/options/option[1]/@value)"  -o '   BUILD_ID:-'  -c "string(/result/executions/execution/@href)"   -o '    BUILD_STATUS:-' -c "string(/result/executions/execution/@status)"  | sed 's/%//'  >>  $OUTPUT_FILE
done
cat $OUTPUT_FILE
fi
