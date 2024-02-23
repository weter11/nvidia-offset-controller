#!/bin/bash

# User configurable variables
nvidia_smi_lgc_min=1005
nvidia_smi_lgc_max=1800
frequency_min=1000
frequency_max=1800
temperature_min=20
temperature_max=80
power_min=20
power_max=120
freq_offset_max=330
freq_offset_min=150
low_freq_min=1000
low_freq_max=1400
high_freq_min=1500
high_freq_max=1800
power_offset_max=60
enable_drain_offset=false
enable_power_offset=false
critical_range_offset=false
show_info=false
refresh_interval=5

# Set users sudo permission for nvidia-smi lgc
sudo nvidia-smi -i 0 -lgc $nvidia_smi_lgc_min,$nvidia_smi_lgc_max

# Calculate freq offset based on frequency
calculate_freq_offset() {
    local frequency=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader | cut -c 1-4)
    local freq_offset=$(( freq_offset_max - ($freq_offset_max - $freq_offset_min) * ($frequency - $frequency_min) / ($frequency_max - $frequency_min) ))
    
    echo $freq_offset
}

# Calculate drain offset based on temperature and frequency range
calculate_drain_offset() {
    local temperature=$1
    local frequency=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader | cut -c 1-4)
    local drain_offset=0
    
    if [ $enable_drain_offset = true ]; then
        if [ $frequency -ge $low_freq_min ] && [ $frequency -le $low_freq_max ] && [ $temperature -gt $temperature_min ] && [ $temperature -lt $temperature_max ]; then
            drain_offset=$(( (($temperature - $temperature_min) * 30) / ($temperature_max - $temperature_min) ))
        elif [ $frequency -ge $high_freq_min ] && [ $frequency -le $high_freq_max ] && [ $temperature -gt $temperature_min ] && [ $temperature -lt $temperature_max ]; then
            drain_offset=$(( 30 - (($temperature - $temperature_min) * 30) / ($temperature_max - $temperature_min) ))
        fi
    fi
    
    echo $drain_offset
}

# Calculate power offset based on power draw
calculate_power_offset() {
    local power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader | awk '{ print int($1  + 0.5) }')
    local power_offset=0
    
    if [ $enable_power_offset = true ]; then
        if [ $power -le $power_min ]; then
            power_offset=$(( power_offset_max * ( power - power_min ) / ( power_min - power_max ) ))
        fi
    fi
    
    echo $power_offset
}

# Calculate total offset
calculate_total_offset() {
    local temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
    local freq_offset=$(calculate_freq_offset)
    local drain_offset=$(calculate_drain_offset $temperature)
    local power_offset=$(calculate_power_offset)
    
    if [ $critical_range_offset = false ] || [ $temperature -lt 48 ] || [ $temperature -gt 61 ]; then
        drain_offset=0
    fi
    
    total_offset=$(( (freq_offset + drain_offset + power_offset) / 15 * 15 ))
    
    echo $total_offset
}

while true; do
    if [ $show_info = true ]; then
        echo "Current GPU statistics:"
        echo "Frequency: $(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader)"
        echo "Temperature: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)"
        echo "Power draw: $(nvidia-smi --query-gpu=power.draw --format=csv,noheader | awk '{ print int($1  + 0.5) }')"
        echo "Offset: $(nvidia-settings -q [gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels)"
        echo "Voltage: $(nvidia-smi -q -d VOLTAGE | grep 'Graphics' | mawk '{print $3,$4}')"
    fi
    
    total_offset=$(calculate_total_offset)
    
    nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=$total_offset"
    
    sleep $refresh_interval
done
