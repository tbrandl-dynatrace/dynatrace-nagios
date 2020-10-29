#!/bin/bash

usage () {
	echo "USAGE: $0 [OPTIONS] \"[nagios_command_including_parameters]\""
	echo "OPTIONS can be one of:"
	echo -e "\t-d|--dimension DIMENSION The metric name from Nagios will be treated as dimension of name DIMENSION instead. This is useful e.g. when the metric name denominates a disk etc."
        echo -e "\t-a|--additional-dimension ADDITIONAL_DIMENSION Adds additional static dimensions in Dynatrace - e.g. if you want to assign a metric to a certain Application."
	echo -e "\t-e|--endpoint ENDPOINT Allows to send metrics through ActiveGate/Dynatrace server instead of dynatrace_ingest for hosts without OneAgent"
	echo -e "\t-k|--key API_TOKEN Sets the API token to use when sending metrics through ActiveGate/Dynatrace server"
        echo -e "\t-h|--dynatrace-home DT_HOME This is required to set if the OneAgent is not installed in /opt/dynatrace/oneagent"
        echo -e "\t-n|--prefix PREFIX The prefix to use for this metric before the command. The default is \"nagios.\""
	echo -e "\t-p|--port PORT The port to use for sending the metrics (default 14499)"
        echo -e "\t-t|--test Prints the generated metrics without sending it to dynatrace_ingest"
	echo -e "\t-v|--verbose Uses dynatrace_ingest with the -v (verbose) option"
	echo -e "\t-?|--help Prints this help page"

        echo "Examples:"
       	echo -e "\t$0 \"/usr/lib/nagios/plugins/check_load -r\""
	echo -e "\t$0 -d disk \"/usr/lib/nagios/plugins/check_disk -w 95 -c 98\""
	echo -e "\t$0 \"/usr/lib/nagios/plugins/check_tcp -p 22\" -a protocol=ssh -v"
	echo -e "\t$0 \"/usr/lib/nagios/plugins/check_host www.amazon.com\" -a dt.entity.application=APPLICATION-073FCAFAFDEAAC57 --test"
	echo -e "\t$0 "/usr/lib/nagios/plugins/check_swap -w 90" -e https://xxxxxxxx.live.dynatrace.com/api/v2/metrics/ingest -k xxxxxxxxxxxxxxx"
	exit 1	
}

while [[ "$#" -gt 0 ]]; do
	case $1 in
		-d|--dimension) DIMENSION="$2"; shift ;;
		-a|--additional-dimension) ADDITIONAL_DIMENSION="$2"; shift;;
		-e|--endpoint) DT_ENDPOINT="$2"; shift;;
		-k|--key) API_TOKEN="$2"; shift;;
		-h|--dynatrace-home) DT_HOME="$2"; shift;;
		-n|--prefix) DT_NAGIOS_PREFIX="$2"; shift;;
		-p|--port) DT_PORT="-p $2 "; shift;;
		-t|--test) TEST_ONLY=1;;
		-v|--verbose) VERBOSE="-v ";;
		-?|--help) usage;;
		*) NAGIOS_COMMAND="$1" ;;
	esac
	shift
done

if [ "$NAGIOS_COMMAND" == "" ]; then
	usage
fi

if [ -z "$DT_HOME" ]; then
	DT_HOME=/opt/dynatrace/oneagent
fi

DYNATRACE_INGEST="$DT_HOME"/agent/tools/dynatrace_ingest

if [ -n "$DT_ENDPOINT" -a -z "$API_TOKEN" ]; then
                echo "Sending metrics via the API requires a valid API-Token (-k|--key)."
                exit 3
elif [ ! -f "$DYNATRACE_INGEST" ]; then
	echo "dynatrace_ingest not found. Check whether the Dynatrace OneAgent is installed, and if it is installed in a non-standard directory, use -h [DT_HOME]."
	echo "Alternatively, you can send metrics using the API-this requires to set the endpoint (-e|--endpoint) and API Token (-k|--key)."
	exit 2
fi

if [ -z "$DT_NAGIOS_PREFIX" ]; then
	DT_NAGIOS_PREFIX=nagios.
fi

if [ -z "$DIMENSION"  ]; then
	DIMENSION="."
else
	DIMENSION=",$DIMENSION="
fi

if [ -n "$ADDITIONAL_DIMENSION" ]; then
	ADDITIONAL_DIMENSION=",$ADDITIONAL_DIMENSION"
fi

NAGIOS_RESULT=`$NAGIOS_COMMAND`

NAGIOS_COMMAND=`echo "$NAGIOS_COMMAND"|cut -d" " -f1`

NAGIOS_COMMAND=`basename $NAGIOS_COMMAND`

NAGIOS_PERFDATA=`echo "$NAGIOS_RESULT"|grep \||cut -d\| -f2`

if [ -z "$NAGIOS_PERFDATA" ]; then
	if [ -n "$VERBOSE" ]; then
		echo "No performance data from plugin: $NAGIOS_RESULT"
	fi
	exit 4
fi

DYNATRACE_METRICS=`echo $NAGIOS_PERFDATA|awk 'BEGIN { RS = " " } {split($0,metric,"="); gsub(/[^\.0-9]++.*/, "", metric[2]); print '\"$DT_NAGIOS_PREFIX$NAGIOS_COMMAND$DIMENSION\"'metric[1]"'$ADDITIONAL_DIMENSION' "metric[2]}'`

if [ "$TEST_ONLY" == "1" ]; then
	echo $DYNATRACE_METRICS
else
	if [ -z "$DT_ENDPOINT" ]; then
		$DYNATRACE_INGEST $VERBOSE$DT_PORT"$DYNATRACE_METRICS"
	else
		CURL_OUTPUT=$(curl -H "Content-Type: text/plain; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -d "$DYNATRACE_METRICS" "$DT_ENDPOINT" 2>/dev/null)
		if [ -n "$VERBOSE" ]; then
			echo $CURL_OUTPUT
		fi
	fi
fi
