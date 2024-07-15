# Network Performance

This repo hosts a shell script that will run various network performance measurements using variable configurations.

## Setup

### Configuration

The application uses configuration through Environment Variables. Here is a list with the details and the default
value for each one of them:


| EnvVar                   | Description                                                                              | Default Values | Suggested Variation Values          |
|--------------------------|------------------------------------------------------------------------------------------|----------------|-------------------------------------|
| * `NAME`                 | A unique name that identifies the specific setup that the tests will run.                | ""             | ""                                  |
| `OUTPUT_DIR`             | A directory to store all measurements' output.                                           | "netperf"      | "netperf"                           |
| * `SERVER`               | The server address to use. Can be the IP (`-c` arg).                                     | ""             | ""                                  |
| * `ADAPTER`              | The adapter to use for traffic routing.                                                  | ""             | ""                                  |
| `IPERF_PORT`             | Port to use for the iperf connection to the server. (`-p` arg).                          | "5201"         | "5201"                              |
| `IPERF_DEFAULT_DURATION` | Default Duration of the iperf run in secs. (`-t` arg)                                    | "20"           | "20"                                |
| `IPERF_DURATION`         | Duration of the iperf run in secs. (`-t` arg) (Multiple args delimited by `;`)           | "10"           | "10;30;60;300"                      |
| `IPERF_PROTOCOL`         | Protocols to test (TCP and UDP). Accepts multiple args delimited by `;`.                 | "TCP"          | "TCP;UDP"                           |
| `IPERF_DIRECTION`        | Direction of traffic to test. (Client to server, Reverse or bidirectional.               | "NORMAL"       | "NORMAL;REVERSE;BIDIRECTIONAL"      |
| `IPERF_STREAMS`          | Streams to use for iperf run. (`-P` arg) (Multiple args delimited by `;`)                | "1"            | "1;2;4;8;16"                        |
| `IPERF_BUFFER_LENGTH`    | Buffer length for iperf TCP tests. (`-l` arg) (Multiple args delimited by `;`)           | "128k"         | "16k;128k;1M"                       |
| `IPERF_WINDOW_SIZE`      | Buffer length for iperf TCP tests. (`-w` arg) (Multiple args delimited by `;`)           | Depends on OS  | "64k;128k;1M"                       |
| `IPERF_MTU`              | Change the MTU size of the network. (`-M` arg). (Multiple args delimited by `;`)         | "1500"         | "576;1500;9000;1472;2000;3000;4000" |
| `IPERF_LATENCY`          | Add custom latency to network.                                                           | "0s"           | "5ms;50ms;100ms"                    |
| `IPERF_PACKET_LOSS`      | Add packet loss to network.                                                              | "0%"           | "0.5%;1%;3%"                        |
| `PING_DEFAULT_COUNT`     | Count of pings to perform. (`-c` Arg)                                                    | "60"           | "60"                                |
| `PING_INTERVAL`          | Time interval in seconds between ping tests. (`-i` Arg) (Multiple args delimited by `;`) | "1"            | "0.1;0.5;1;5"                       |
| `PING_PACKET_SIZE`       | Packet size of packets send by ping tests. (`-s` Arg) (Multiple args delimited by `;`)   | "56"           | "32;56;128;1024;4096"               |
| `PING_LATENCY`           | Add custom latency to network.                                                           | "0ms"          | "5ms;50ms;100ms"                    |

> EnvVars marked with a `*` are mandatory to run the tests.

The `.env.sample` file contains the suggested variation values. Renaming it to `.env` will cause it to be loaded and 
used by the script when it runs. Feel free to ignore it, if you are using another way to set EnvVars. For cases that no 
configuration is provided the script will run the iperf and ping measurements using the default values.

For the Name variable it is recommended to add a json formatted string to contain all the details of the hardware setup 
in order to allow later to identify the setup. A meaningful name could be like this:
```
NAME={"name":"Bare metal client to Bare Metal server with Ubuntu v22.04","client":{"host":"Ubuntu Server v22.04","vm_type":"Bare Metal","network":"10G Bare Metal"},"server":{"host":"Ubuntu Server v22.04","vm_type":"Bare Metal","network":"10G Bare Metal"}}
```

## Running the script

Before proceeding with executing the script, ensure that the iperf3 server is running on the server host using:
```bash
iperf3 -s -p ${IPERF_PORT} -J
```

In order to run the script we must set first any configuration through EnvVars and then execute it at the client side 
by running:
```bash
sudo ./netperf.sh
```

> sudo is required as the script will try to install all the required packages for the required tools.

We can also set the EnvVars and run the script at the same time using
```bash
sudo NAME="Test run" ADAPTER=eth0 SERVER=192.168.1.44 ./netperf.sh
```

In order to store execution's output to a file and print to the console output we can run the script with:
```bash
sudo ./netperf.sh 2>&1 | tee netperf.out
```

## Results

All results are located under the give `${OUTPUT}` directory (of `netperf` if none provided) and then a directory with 
the start date and time that contains all the results. All iperf results are prefixed with `iperf` and all ping test 
results are prefixed with `ping`. The name of each file contains all the arguments given to the command. A file with 
the same name but with a `.cmd` extension will be also stored in the same directory and will contain the actual 
command(s) that were executed. 

A file named `info.txt` contains the given `${NAME}` during the script execution. Output of the script will be stored 
at the `netperf.out` file in the same directory with the script.

The final contents of the results will contain files like the listed ones bellow:
```
├── 2024-07-09-12-50-21
│   ├── iperf_buffer_length_128k.cmd
│   ├── iperf_buffer_length_128k.json
│   ├── iperf_buffer_length_128k_results.txt
│   ├── iperf_buffer_length_16k.cmd
│   ├── iperf_buffer_length_16k.json
│   ├── iperf_buffer_length_16k_results.txt
│   ├── iperf_streams_2.cmd
│   ├── iperf_streams_2.json
│   ├── iperf_streams_2_results.txt
│   ├── iperf_streams_4.cmd
│   ├── iperf_streams_4.json
│   ├── iperf_streams_4_results.txt
│   ├── ping_latency_50ms.cmd
│   ├── ping_latency_50ms.json
│   ├── ping_latency_50ms_results.txt
│   ├── ping_latency_5ms.cmd
│   ├── ping_latency_5ms.json
│   ├── ping_latency_5ms_results.txt
│   ├── ping_packet_size_1024.cmd
│   ├── ping_packet_size_1024.json
│   ├── ping_packet_size_1024_results.txt
│   ├── ping_packet_size_56.cmd
│   ├── ping_packet_size_56.json
│   └── ping_packet_size_56_results.txt
│   └── ...
└── info.txt
```

### Extracting results' info

The script `extract.sh` accepts a folder as an arguments and parses iperf and ping results in order to extract the mean 
and the standard deviation of each result's file. It can be used as:
```bash
./extract.sh results/2024-07-09-12-50-21/
```

The results will be printed out and also written to files with the same name as the results' files in a json format.
The suffix of these metrics' files will be `_results.json`


### Plotting results

Using the provided python script `bar_chart.py` we can plot various setups in order to compare result for different 
variations and setups.

the usage of the script is:
```bash
python3 bar_chart.py -h
usage: bar_chart.py [-h] --prefix PREFIX [--title TITLE] --execution EXECUTION [EXECUTION ...]

Plots network performance results.

optional arguments:
  -h, --help            show this help message and exit
  --prefix PREFIX       The prefix of results to measure
  --title TITLE         The title to process
  --execution EXECUTION [EXECUTION ...]
                        Execution(s) to plot
```

An example command for plotting the results for 4 different executions (provided by `--execution` argument), for all 
variations that are prefixed with `ping_packet_size_` and add a custom title `Latency - Packet size`:

```bash
python3 bar_chart.py --title "Latency - Packet size" --prefix ping_packet_size_  --execution ./results/2024-07-12-10-53-21 ./results/2024-07-12-11-32-13 ./results/2024-07-12-12-12-03 ./results/2024-07-12-12-52-43
```
