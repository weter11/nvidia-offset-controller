# nvidia-offset-controller
control Nvidia GPUs frequency offsets

Basic offset controller with advanced settings.
nvidia_smi_lgc_min & nvidia_smi_lgc_max -set range GPU frequencies should work
frequency_min & frequency_max - set frequencies range for offset calculations
temperature_min & temperature_max - set temperatures range for additional offset calculations
power_min & power_max - set GPU power consumpion range for additional offset calculations
freq_offset_min & freq_offset_max - set main offsets to calculate offsets between frequency_min & frequency_max
low_freq_min, low_freq_max, high_freq_min, high_freq_max - additinal offset, which applied with positive coefficient at low frequencies and negative coefficient at high frequencies, because of transistors characteristics. Controlled by variable enable_drain_offset
power_offset_max - additional offset, which further downvolt GPU core, because GPU can work with lower voltage when not fully loaded. Controlled by variable enable_power_offset
critical_range_offset - additional setting to prevent GPU instabilities because of voltage fluctuations in a predefined temperature range
