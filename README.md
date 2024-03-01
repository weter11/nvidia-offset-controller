# nvidia-offset-controller
Small script to control Nvidia GPUs frequency offsets

Basic offset controller with advanced settings.

Settings explanation: 

nvidia_smi_lgc_min & nvidia_smi_lgc_max -set range GPU frequencies should work (RTX 30xx desktop & mobile (Ampere arch) & up only)

frequency_min & frequency_max - set frequencies range for offset calculations

freq_offset_min & freq_offset_max - set main offsets to calculate offsets between frequency_min & frequency_max

temperature_min & temperature_max - set temperatures range for additional offset calculations

plimit_min & plimit_max - set GPU power consumpion range for additional offset calculations

low_freq_min, low_freq_max, high_freq_min, high_freq_max - additinal offset, which applied with positive coefficient at low frequencies and negative coefficient at high frequencies, because of transistors characteristics. Controlled by variable enable_drain_offset

drain_offset_lmin, drain_offset_lmax, drain_offset_hmin, drain_offset_hmax - offset, which take into account tranfer characteristics of transistors with regions of positive and negative temperature coefficient

power_offset_max, power_offset_min - additional offset, which further downvolt GPU core, because GPU can work with lower voltage when not fully loaded. Controlled by variable power_offset_control

critical_range_offset - additional setting to prevent GPU instabilities because of voltage fluctuations in a predefined temperature range by disabling drain offset calculations
