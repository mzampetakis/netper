import matplotlib.pyplot as plt
import numpy as np
import argparse
import os
import sys
import re
import json
import decimal
import math


def find_files_with_prefix_suffix(directory, prefix, suffix):
    matched_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.startswith(prefix) and file.endswith(suffix):
                matched_files.append(os.path.join(root, file))
    return matched_files


def parse_json_field(filepath, field):
    try:
        with open(filepath, 'r') as file:
            json_content = json.load(file)
            return json_content.get(field)
    except Exception as e:
        print(f'Error parsing file "{filepath}": {e}')
        return None


def split_prefix_suffix(value):
    match = re.match(r'(\d+(\.\d+)?)(.*)', value)
    if match:
        numeric_part = match.group(1)
        suffix = match.group(3)
        return decimal.Decimal(numeric_part), suffix
    else:
        return None, value


def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description='Plots network performance results.')
    parser.add_argument('--prefix', type=str, required=True, help='The prefix of results to measure')
    parser.add_argument('--title', type=str, default='', help='The title to process')
    parser.add_argument('--execution', nargs='+', type=str, required=True, help='Execution(s) to plot')
    parser.add_argument('--colors', nargs='+', type=str, required=True, help='Colors for each execution')

    args = parser.parse_args()

    print('Title: ', args.title)
    if not args.title:
        args.title = args.prefix.replace('_', ' ')
    print('Prefix: ', args.prefix)
    print('Executions to plot:', ', '.join(args.execution))

    if len(args.colors) != len(args.execution):
        print("The number of colors must match the number of executions.")
        sys.exit(1)

    results_suffix = "_results.json"
    total_variations = 0
    max_val = decimal.Decimal(0)
    executions = []
    variations = {}

    def add_value(key, value):
        if key in variations:
            variations[key].append(value)
        else:
            variations[key] = [value]

    def add_unique_value(number_prefix, char_suffix):
        if (number_prefix, char_suffix) not in executions:
            executions.append((number_prefix, char_suffix))

    # Traverse through execution runs
    for execution in args.execution:
        if not os.path.isdir(execution):
            print(f'Folder "{execution}" does not exist.')
            sys.exit(1)

        info_path = os.path.join(execution, 'info.json')
        if not os.path.isfile(info_path):
            print(f'File "info.json" does not exist in folder "{execution}".')
            sys.exit(1)

        execution_name = parse_json_field(info_path, 'name')
        if execution_name is None:
            print(f'No "name" field found in file "{info_path}".')
            sys.exit(1)

        matched_files = find_files_with_prefix_suffix(execution, args.prefix, results_suffix)
        if not matched_files:
            print(f'No results files with prefix "{args.prefix}" found in folder "{execution}".')
            sys.exit(1)

        if total_variations == 0:
            total_variations = len(matched_files)
        else:
            if total_variations != len(matched_files):
                print(
                    f'Variation in folder "{execution}" are "{len(matched_files)}" but expected "{total_variations}".')
                sys.exit(1)

        arg = "average_latency_ms" if args.prefix.startswith("ping") else "average_bandwidth_mbps"

        # For each file in execution that matches the given prefix
        for filepath in matched_files:
            avg = parse_json_field(filepath, arg)
            if avg is None:
                print(f'No "average" field found in file "{filepath}".')
                sys.exit(1)
            avg = decimal.Decimal(avg)
            add_value(execution_name, avg)
            if avg > max_val:
                max_val = avg

            filename = os.path.basename(filepath)
            file_variation = filename[len(args.prefix):-len(results_suffix)]
            numeric_part, suffix = split_prefix_suffix(file_variation)
            add_unique_value(numeric_part, suffix)

    # Sort executions and using the same keys sort the inner arrays in variations
    all_executions = sorted(list(set(executions)))
    execution_index = {execution: idx for idx, execution in enumerate(all_executions)}
    sorted_variations = {key: [None] * len(all_executions) for key in variations.keys()}

    for key, values in variations.items():
        for idx, value in enumerate(values):
            execution = executions[idx]
            if execution in execution_index:
                sorted_variations[key][execution_index[execution]] = value

    # Plot
    x = np.arange(len(all_executions))
    width = 1 / (len(args.execution) + 1)
    multiplier = 1

    fig, ax = plt.subplots(figsize=(16, 9))
    for i, (attribute, measurements) in enumerate(sorted_variations.items()):
        if None in measurements:
            print(f"Warning: Some measurements are missing for {attribute}")

        offset = width * multiplier
        color = args.colors[i % len(args.colors)]
        rects = ax.bar(x + offset, measurements, width, label=attribute, color=color)
        ax.bar_label(rects, padding=3)
        multiplier += 1

    ax.set_ylabel('Latency (ms)' if args.prefix.startswith("ping") else 'Bandwidth mbps')
    ax.set_title(args.title)
    ax.set_xticks(x + width, [f"{num}{char}" for num, char in all_executions])
    ax.legend(loc='upper left', ncols=2)
    ax.set_ylim(0, math.ceil(max_val * decimal.Decimal(1.2)))
    plt.show()

main()
