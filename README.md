# dynatrace-nagios

This simple shell script allows to get metrics from Nagios plugins and directly send them to Dynatrace using dynatrace_ingest.
# Usage
```bash
./dynatrace_nagios.sh [OPTIONS] "[nagios_command_including_parameters]"
``` 

# Options
Short option | Long Option | Parameter | Description
------------ | ----------- | --------- | -----------
-d | --dimension | DIMENSION  | The metric name from Nagios will be treated as dimension of name DIMENSION instead. This is useful e.g. when the metric name denominates a disk etc.
-a | --additional-dimension | ADDITIONAL_DIMENSION | Adds additional static dimensions in Dynatrace - e.g. if you want to assign a metric to a certain Application.
-h | --dynatrace-home | DT_HOME | This is required to set if the OneAgent is not installed in /opt/dynatrace/oneagent
-n | --prefix | PREFIX | The prefix to use for this metric before the command. The default is "nagios."
-p | --port | PORT | The port to use for sending the metrics (default 14499)
-t | --test | | Prints the generated metrics without sending it to dynatrace_ingest
-v | --verbose | | Uses dynatrace_ingest with the -v (verbose) option
-? | --help | | Prints this help page
        
        
# Examples

```bash
./dynatrace_nagios.sh "/usr/lib/nagios/plugins/check_load -r"
./dynatrace_nagios.sh -d disk "/usr/lib/nagios/plugins/check_disk -w 95 -c 98"
./dynatrace_nagios.sh "/usr/lib/nagios/plugins/check_tcp -p 22" -a protocol=ssh -v
./dynatrace_nagios.sh "/usr/lib/nagios/plugins/check_host www.amazon.com" -a dt.entity.application=APPLICATION-073FCAFAFDEAAC57 --test
```
