#!/bin/bash
n_gpus=$(nvidia-smi -L | grep -c 'GPU' | tr -d '\n' | awk '{print $1}')  # Get number of GPUs
total_vram=0

# Loop over the GPUs
for (( i=0; i<n_gpus; i++ ))
do
   vram_usage=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader | awk 'NR=='$((i+1))' { print $1 }')  # Get used VRAM for current GPU
   vram_usage=$((vram_usage/1024))  # Convert from MiB to GiB
   total_vram=$((total_vram + vram_usage))  # Add the current GPU's used VRAM to the total
done

echo "Total Used VRAM Usage: $total_vram GiB"