#!/bin/bash

# User-configurable parameters
nvidia_smi_lgc_min=      # Minimum Graphics Clock frequency
nvidia_smi_lgc_max=      # Maximum Graphics Clock frequency
frequency_min=           # Minimum frequency limit for offset calculations
frequency_max=           # Maximum frequency limit for offset calculations
freq_offset_max=          # Maximum frequency offset
freq_offset_min=          # Minimum frequency offset
refresh_interval=           # Refresh interval in seconds

# Check if frequency_min is higher than nvidia_smi_lgc_max
if [ $frequency_min -gt $nvidia_smi_lgc_max ]; then
    echo "Error: frequency_min is higher than nvidia_smi_lgc_max. Please adjust the parameters."
    exit 1
fi

    sudo nvidia-smi -i 0 -lgc $nvidia_smi_lgc_min,$nvidia_smi_lgc_max

# Calculate freq_offset linearly from frequency_min to frequency_max and round to nearest multiple of 5
calculate_freq_offset() {
    local freq=$1
    local freq_offset=$((freq_offset_max - ((freq_offset_max - freq_offset_min) * (freq - frequency_min)) / (frequency_max - frequency_min)))
    local rounded_offset=$(( (freq_offset + 2) / 5 * 5 ))  # Round to nearest multiple of 5
    echo $rounded_offset
}

while true; do
    current_gpu_frequency=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader | cut -c 1-4)

    freq_offset=$(calculate_freq_offset $current_gpu_frequency)

    echo "Setting GPU frequency offset to $freq_offset"
    nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=$freq_offset"

    sleep $refresh_interval
done
