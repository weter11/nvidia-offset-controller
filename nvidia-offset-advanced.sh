#!/bin/bash

# User-configurable parameters
gpu_memory_offset=
nvidia_smi_lgc_min=
nvidia_smi_lgc_max=
temperature_min=
temperature_max=
plimit_min=
plimit_max=
frequency_min=
frequency_max=
freq_offset_max=
freq_offset_min=
low_freq_min=
low_freq_max=
drain_offset_lmin=
drain_offset_lmax=
high_freq_min=
high_freq_max=
drain_offset_hmin=
drain_offset_hmax=
critical_temp_min=
critical_temp_max=
power_offset_max=
power_offset_min=
refresh_interval=

show_info=false
drain_offset_control=true
power_offset_control=true
critical_temp_range_control=true

help_message="Usage: $0 [options]\n\
Options:\n\
  -o, options       Show configurable parameters\n\
  -c, config        Show configured values\n\""

# Function to display the help message
function display_help {
    echo -e "$help_message"
}

    # Help section
if [[ $1 == "options" || $1 == "-o" ]]; then
    echo ""
    echo "  This tool designed for advanced control of Nvidia GPU offsets with this configurable parameters:"
    echo ""
    echo " --gpu_memory_offset: VRAM offset to overclock/underclock memory speed"
    echo " --nvidia_smi_lgc_min: Minimum value for nvidia-smi lgc"
    echo " --nvidia_smi_lgc_max: Maximum value for nvidia-smi lgc"
    echo " --temperature_min: Minimum temperature limit"
    echo " --temperature_max: Maximum temperature limit"
    echo " --plimit_min: Minimum power limit"
    echo " --plimit_max: Maximum power limit"
    echo " --frequency_min: Minimum frequency limit"
    echo " --frequency_max: Maximum frequency limit"
    echo " --freq_offset_max: Maximum frequency offset value"
    echo " --freq_offset_min: Minimum frequency offset value"
    echo " --low_freq_min: Low frequency range min"
    echo " --low_freq_max: Low frequency range max"
    echo " --drain_offset_lmin: Low frequency drain offset min"
    echo " --drain_offset_lmax: Low frequency drain offset max"
    echo " --high_freq_min: High frequency range min"
    echo " --high_freq_max: High frequency range max"
    echo " --drain_offset_hmin: High frequency drain offset min"
    echo " --drain_offset_hmax: High frequency drain offset max"
    echo " --critical_temp_min: Critical temperature min"
    echo " --critical_temp_max: Critical temperature max"
    echo " --power_offset_max: Maximum power offset"
    echo " --power_offset_min: Minimum power offset"
    echo " --critical_temp_range_control: Set critical temperature range offset (default: true)"
    echo " --drain-offset-control Set drain offset control mode (default: true)"
    echo " --power-offset-control Set power offset control mode (default: true)"
    echo " --refresh_interval    Set refresh rate in seconds (default: 2)"
    exit
fi

    # Help section for showing configured values
if [[ $1 == "config" || $1 == "-c" ]]; then
    echo "Configured values:"
    echo "gpu_memory_offset: $gpu_memory_offset"
    echo "nvidia_smi_lgc_min: $nvidia_smi_lgc_min, nvidia_smi_lgc_max: $nvidia_smi_lgc_max"
    echo "temperature_min: $temperature_min, temperature_max: $temperature_max"
    echo "plimit_min: $plimit_min, plimit_max: $plimit_max"
    echo "frequency_min: $frequency_min, frequency_max: $frequency_max"
    echo "freq_offset_max: $freq_offset_max, freq_offset_min: $freq_offset_min"
    echo "low_freq_min: $low_freq_min, low_freq_max: $low_freq_max"
    echo "drain_offset_lmin: $drain_offset_lmin, drain_offset_lmax: $drain_offset_lmax"
    echo "high_freq_min: $high_freq_min, high_freq_max: $high_freq_max"
    echo "drain_offset_hmin: $drain_offset_hmin, drain_offset_hmax: $drain_offset_hmax"
    echo "critical_temp_min: $critical_temp_min, critical_temp_max: $critical_temp_max"
    echo "power_offset_max: $power_offset_max, power_offset_min: $power_offset_min"
    exit
fi

    # Help section for displaying the help message with configurable parameters
if [[ "$1" == "help" || $1 == "-h" ]]; then
    display_help
    exit
fi

    # Apply nvidia-smi lgc
    sudo nvidia-smi -i 0 -lgc $nvidia_smi_lgc_min,$nvidia_smi_lgc_max
    
    # Apply VRAM oveclock/underclock offset
    nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$gpu_memory_offset"
    
while true; do
    # Get current time
    current_time=$(date +"%T")
    
    # Get GPU statistics
    frequency=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader | cut -c 1-4)
    temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
    power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader | awk '{ print int($1 + 0.5) }')
    voltage=$(nvidia-smi -q -d VOLTAGE | grep 'Graphics' | awk '{print $3,$4}')

    # Calculate freq_offset
    if [ $frequency -lt $frequency_min ]; then
        freq_offset=$freq_offset_max
    elif [ $frequency -gt $frequency_max ]; then
        freq_offset=$freq_offset_min
    else freq_offset=$((freq_offset_max - ((frequency - frequency_min) * (freq_offset_max - freq_offset_min) / (frequency_max - frequency_min))))
    fi
    
    # Calculate drain_offset if control is enabled
if [ $drain_offset_control == true ]; then
    if [ $frequency -ge $low_freq_min ] && [ $frequency -le $low_freq_max ]; then
        drain_offset=$(( (drain_offset_lmax - drain_offset_lmin) * (temperature - temperature_min) / (temperature_max - temperature_min) + drain_offset_lmin ))
        
        if [ $temperature -gt $temperature_max ]; then
            drain_offset=$drain_offset_lmax  # Apply drain_offset_lmax if temperature exceeds temperature_max
        fi
    elif [ $frequency -ge $high_freq_min ] && [ $frequency -le $high_freq_max ]; then
        drain_offset=$(( (drain_offset_hmax - drain_offset_hmin) * (temperature - temperature_min) / (temperature_max - temperature_min) + drain_offset_hmin ))
        
        if [ $temperature -gt $temperature_max ]; then
            drain_offset=$drain_offset_hmin  # Apply drain_offset_hmin if temperature exceeds temperature_max
        fi
    fi

    # Apply specific drain_offsets based on temperature exceeding threshold and critical_temp_range_control
    if [ $critical_temp_range_control == true ] && [ $temperature -gt $critical_temp_min ] && [ $temperature -lt $critical_temp_max ]; then
        if [ $frequency -ge $low_freq_min ] && [ $frequency -le $low_freq_max ]; then
            drain_offset=$drain_offset_lmin
        elif [ $frequency -ge $high_freq_min ] && [ $frequency -le $high_freq_max ]; then
            drain_offset=$drain_offset_hmin
        fi
    fi
fi
    
    # Calculate power_offset if control is enabled
    if [ $power_offset_control == true ]; then
        if [ $power -le $plimit_min ]; then
            power_offset=$power_offset_max
        elif [ $power -gt $plimit_min ] && [ $power -le $plimit_max ]; then
            power_offset=$(($power_offset_max - ($power_offset_max - $power_offset_min) * ($power - $plimit_min) / ($plimit_max - $plimit_min)))
        else
            power_offset=$power_offset_min
        fi
    fi

    # Calculate total_offset based on control settings
    if [ $power_offset_control == true ] && [ $drain_offset_control == true ]; then
        total_offset=$(( freq_offset + drain_offset + power_offset ))
    elif [ $power_offset_control == true ] && [ $drain_offset_control == false ]; then
        total_offset=$(( freq_offset + power_offset ))
    elif [ $power_offset_control == false ] && [ $drain_offset_control == true ]; then
        total_offset=$(( freq_offset + drain_offset ))
    else
        total_offset=$freq_offset
    fi
    
    # Round total_offset to nearest multiple of 5
    total_offset=$(echo $((total_offset / 5 * 5)))

    # Show GPU statistics if show_info is true
    if [ "$show_info" = true ]; then
        echo "Current time: $current_time"
        echo "Frequency: $frequency MHz"
        echo "Temperature: $temperature °C"
        echo "Power: $power W"
        echo "Voltage: $voltage"
        echo "Freq Offset: $freq_offset"
        echo "Drain Offset: $drain_offset"
        echo "Power Offset: $power_offset"
        echo "Total Offset: $total_offset"
    fi

    # Apply offset
    nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=$total_offset"
    
    # Wait for refresh interval
    sleep $refresh_interval
done
