# Network Performance

This repo hosts a shell script that will run various network performance measurements using various configuration 
options.

## Setup

### Configuration

The application uses configuration through Environment Variables. Here is a list with the details and the default
value for each one of them:

> sensible default values
> Suggested Variation values

| EnvVar                | Description                                                                              | Default Values | Suggested Variation Values          |
|-----------------------|------------------------------------------------------------------------------------------|----------------|-------------------------------------|
| * `NAME`              | A unique name that identifies the specific setup that the tests will run.                | ""             | ""                                  |
| `OUTPUT_DIR`          | A directory to store all measurements' output.                                           | "netperf"      | "netperf"                           |
| * `SERVER`            | The server address to use. Can be the IP (`-c` arg).                                     | ""             | ""                                  |
| * `ADAPTER`           | The adapter to use for traffic routing.                                                  | ""             | ""                                  |
| `IPERF_PORT`          | Port to use for the iperf connection to the server. (`-p` arg).                          | "5201"         | "5201"                              |
| `IPERF_DURATION`      | Duration of the iperf run in secs. (`-t` arg) (Multiple args delimited by `;`)           | "10"           | "10;60;300"                         |
| `IPERF_PROTOCOL`      | Protocols to test (TCP and UDP). Accepts multiple args delimited by `;`.                 | "TCP"          | "TCP;UDP"                           |
| `IPERF_DIRECTION`     | Direction of traffic to test. (Client to server, Reverse or bidirectional.               | "NORMAL"       | "NORMAL;REVERSE;BIDIRECTIONAL"      |
| `IPERF_STREAMS`       | Streams to use for iperf run. (`-P` arg) (Multiple args delimited by `;`)                | "1"            | "1;2;4;8;16"                        |
| `IPERF_BUFFER_LENGTH` | Buffer length for iperf TCP tests. (`-l` arg) (Multiple args delimited by `;`)           | "128k"         | "16k;128k;1M"                       |
| `IPERF_WINDOW_SIZE`   | Buffer length for iperf TCP tests. (`-w` arg) (Multiple args delimited by `;`)           | Depends on OS  | "64k;128k;1M"                       |
| `IPERF_MTU`           | Change the MTU size of the network. (`-M` arg). (Multiple args delimited by `;`)         | "1500"         | "576;1500;9000;1472;2000;3000;4000" |
| `IPERF_LATENCY`       | Add custom latency to network.                                                           | "0s"           | "5ms;50ms;100ms"                    |
| `IPERF_PACKET_LOSS`   | Add packet loss to network.                                                              | "0%"           | "0.5%;1%;3%"                        |
| `PING_INTERVAL`       | Time interval in seconds between ping tests. (`-i` Arg) (Multiple args delimited by `;`) | "1"            | "0.1;0.5;1;5"                       |
| `PING_PACKET_SIZE`    | Packet size of packets send by ping tests. (`-i` Arg) (Multiple args delimited by `;`)   | "56"           | "32;56;128;1024;4096"               |
| `PING_LATENCY`        | Add custom latency to network.                                                           | "0ms"          | "5ms;50ms;100ms"                    |

> EnvVars marked with a `*` are mandatory to run the tests.

The `.env.sample` file contains the suggested variation values. Renaming it to `.env` will cause it to be loaded and 
used by the script when it runs. Feel free to ignore it, if you are using another way to set EnvVars. For cases that no 
configuration is provided the script will run the iperf and ping measurements using the default values.

For the Name variable it is recommended to add a json formatted string to contain all the details of the hardware setup 
in order to allow later to identify the setup.

## Running the script

Before proceeding with executing the script, ensure that the iperf3 server is running on the other host using:
```bash
iperf3 -s -p ${IPERF_PORT} -J
```

In order to run the script we must set first any configuration through EnvVars and then execute it by running:
```bash
sudo ./netperf.sh
```

> sudo is required as the script will try to install all the required packages for the required tools.

We can also set the EnvVars and run the script at the same time using
```bash
sudo ENVKEY1=ENVVAR1 ENVKEY2=ENVVAR2 ENVKEY3=ENVVAR3 ./netperf.sh
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

### Extracting results' info

The script `extract.sh` accepts a folder as an arguments and parses iperf and ping results in order to extract the mean 
and the standard deviation of each result's file. It can be used as:
```bash
./extract.sh results/2024-07-09-12-50-21/
```

The results will be printed out and also written to files with the same name as the results' files.
The suffix of these metrics' files will be `_results.txt` 