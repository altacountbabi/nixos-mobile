{
  flake.nixosModules.default =
    { lib, ... }:
    {
      boot.kernelPatches = [
        {
          name = "nothing-spacewar-config";
          patch = null;

          structuredExtraConfig = with lib.kernel; {
            # Touchscreen
            TOUCHSCREEN_FTS = yes;
            TOUCHSCREEN_FTS_DIRECTORY = freeform "focaltech_touch";
            RMI4_CORE = module;
            RMI4_SPI = module;
            RMI4_SMB = module;
            RMI4_F03 = yes;
            RMI4_F03_SERIO = module;
            RMI4_2D_SENSOR = yes;
            RMI4_F11 = yes;
            RMI4_F12 = yes;
            RMI4_F30 = yes;
            RMI4_F34 = yes;
            RMI4_F3A = yes;
            RMI4_F55 = yes;

            # GPU Driver
            DRM_MSM = module;

            # Backlight
            BACKLIGHT_CLASS_DEVICE = yes;
            BACKLIGHT_QCOM_WLED = yes;

            # Network
            NET_VENDOR_QUALCOMM = yes;

            # MFDs
            MFD_QCOM_PM8008 = yes;

            # Regulators
            REGULATOR_QCOM_LABIBB = yes;
            REGULATOR_QCOM_PM8008 = yes;
            REGULATOR_QCOM_SPMI = yes;
            REGULATOR_QCOM_USB_VBUS = yes;
            REGULATOR_QCOM_CONSUMER = yes;

            # Audio
            SND_SOC_WCD9385 = yes;
            SND_SOC_TFA9873 = yes;
            SND_SOC_TFA9872 = module;

            # Camera
            VIDEO_CS3308 = yes;
            VIDEO_CS5345 = yes;
            VIDEO_CS53L32A = yes;
            VIDEO_CX25840 = yes;

            # USB
            USB_ANNOUNCE_NEW_DEVICES = yes;
            USB_LEDS_TRIGGER_USBPORT = yes;
            USB_CONFIGFS_F_UAC2 = yes;
            USB_CONFIGFS_F_UVC = yes;

            # LEDs
            LEDS_QCOM_FLASH = module;
            LEDS_TRIGGER_ONESHOT = yes;
            LEDS_TRIGGER_BACKLIGHT = yes;
            LEDS_TRIGGER_ACTIVITY = yes;
            LEDS_TRIGGER_GPIO = yes;
            LEDS_TRIGGER_TRANSIENT = yes;
            LEDS_TRIGGER_CAMERA = yes;
            LEDS_TRIGGER_NETDEV = yes;
            LEDS_TRIGGER_PATTERN = yes;
            LEDS_TRIGGER_TTY = yes;

            # Clock Controllers
            SC_CAMCC_7280 = yes;
            SC_DISPCC_7280 = yes;
            SC_GPUCC_7280 = yes;

            # System Monitoring (thermal, voltage, clocks, etc..)
            QCOM_SYSMON = yes;

            # Filesystems
            F2FS_STAT_FS = yes;
            F2FS_FS_XATTR = yes;
            F2FS_FS_LZO = yes;
            F2FS_FS_LZORLE = yes;
            F2FS_FS_LZ4 = yes;
            F2FS_FS_LZ4HC = yes;
            F2FS_FS_ZSTD = yes;
            F2FS_IOSTAT = yes;
            FS_ENCRYPTION_ALGS = yes;

            FAT_DEFAULT_IOCHARSET = freeform "utf8";

            PROC_CHILDREN = yes;

            UNICODE = yes;

            # Memory Management
            CMA_SIZE_SEL_PERCENTAGE = unset;
            CMA_SIZE_PERCENTAGE = unset;
            CMA_SIZE_SEL_MBYTES = yes;
            CMA_SIZE_MBYTES = lib.mkForce (freeform "64");

            # ARM Security Features
            CC_HAS_BRANCH_PROT_PAC_RET = yes;
            ARCH_SUPPORTS_SHADOW_CALL_STACK = yes;
            CC_HAVE_SHADOW_CALL_STACK = yes;
            AS_HAS_MOPS = yes;

            # QCOM Misc
            ARCH_QCOM = yes;
            QRTR = yes;
            QCOM_LLCC = yes;
            QCOM_PDR_HELPERS = yes;
            QCOM_PDR_MSG = yes;
            QCOM_QMI_HELPERS = yes;
            QCOM_RMTFS_MEM = yes;
            QCOM_SOCINFO = yes;
            QCOM_APR = yes;
            QCOM_ICC_BWMON = yes;
            PHY_QCOM_QMP = yes;
            PHY_QCOM_QMP_COMBO = module;
            PHY_QCOM_QMP_UFS = yes;
            PHY_QCOM_QMP_USB = yes;
            PHY_QCOM_USB_SNPS_FEMTO_V2 = yes;

            # Misc
            NR_CPUS = lib.mkForce (freeform "8");
          };
        }
      ];
    };
}
