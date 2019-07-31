#!/bin/sh -e

currHostName=`hostname`
SCRIPT=$(readlink -f "$0")
currDirName=$(dirname "$SCRIPT")
currFilename=$(basename "$SCRIPT")

echo "${currHostName}:${currFilename} Deploying war for Tomcat in ${TOMCAT_HOME}..."

echo "${currHostName}:${currFilename} ${WAR_URL} War's context path ${CONTEXT_PATH}"

if [ -f /usr/bin/wget ]; then
	DOWNLOADER="wget"
elif [ -f /usr/bin/curl ]; then
	DOWNLOADER="curl"
fi
# args:
# $1 download description.
# $2 download link.
# $3 output file.
download () {
	echo "${currHostName}:${currFilename} Downloading $1 from $2 ..."
	if [ "$DOWNLOADER" = "wget" ];then
		Q_FLAG="--no-check-certificate"
		O_FLAG="-O"
		LINK_FLAG=""
	elif [ "$DOWNLOADER" = "curl" ];then
		Q_FLAG=""
		O_FLAG="-o"
		LINK_FLAG="-O"
	fi
	echo "${currHostName}:${currFilename} $DOWNLOADER $4 $Q_FLAG $O_FLAG $3 $LINK_FLAG $2"
	sudo $DOWNLOADER $Q_FLAG $O_FLAG $3 $LINK_FLAG $2 || error_exit $? "Failed downloading $1"
}

if [ -z "${WAR_URL}" ];then
	# The war_file MUST have the .war extension otherwise it won't work
	mv ${war_file} ${war_file}.war
	war_file=${war_file}.war

    echo "Use deployment artifact from ${war_file}"
else
    echo "Override deployment artifact ${war_file} with war from ${WAR_URL}"
    war_file_folder=$currDirName/../downloads
    war_file=$war_file_folder/war_file.war
    sudo mkdir -p $war_file_folder
    download "War" $WAR_URL $war_file
fi
# The war_file is the artifact path defined in the deployment
# artifacts of the SOURCE which is injected here automatically
# (implement the get_artifact function for a proper solution).
# It can also be specified by an URL, in this case the war at the url overrides
echo "${currHostName}:${currFilename} War file path is at ${war_file}"

tomcatConfFolder=$TOMCAT_HOME/conf
tomcatContextPathFolder=$tomcatConfFolder/Catalina/localhost
tomcatContextFile=$tomcatContextPathFolder/$CONTEXT_PATH.xml

sudo mkdir -p $tomcatContextPathFolder

# Write the context configuration
sudo rm -f $tomcatContextFile
echo "<Context docBase=\"${war_file}\" path=\"${CONTEXT_PATH}\" />" | sudo tee $tomcatContextFile > /dev/null
echo "${currHostName}:${currFilename} Sucessfully installed war on Tomcat in ${TOMCAT_HOME}"
