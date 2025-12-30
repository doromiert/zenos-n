# will contain generic syncthing settings and devices
{ ... }: {
    services.syncthing = {
        enable = true;

        overrideDevices = true;     # Overrides GUI settings with Nix config
        overrideFolders = true;     # Overrides GUI settings with Nix config
        
        openDefaultPorts = true;

        settings.devices = {
            # my devices
            "doromi-tul-2" = { id = "placeholder"; };
            "doromipad"     = { id = "placeholder"; };
            "doromi-server"  = { id = "placeholder"; };
            "np2"           = { id = "3WNXGMD-ZAROXSW-RMQC6Q4-T66662R-CXUK336-3G2O5FX-3WZ7E66-EW2JQQU"; };
            "i8"            = { id = "CWAU4ZX-KGHW7ZM-OOAWJEQ-2SW6JOW-MAGYYNN-SXPZJZA-TO46TM5-G7PRXAH"; };
            "quest"         = { id = "F6YQGXO-AC2JQXK-E7H7NLM-H4UW7LV-VX4W5PI-ZZNUD2W-6C2VSJY-HI4BJQL"; };
            "spes_a16"      = { id = "FCZAJ2J-CREUQOX-2G3WKO4-6WCHBCO-OLDG3QD-KUQPDS6-4YKQQUU-OVS4TAC"; };
            "macbook"       = { id = "OIBKP7M-MM67F6L-3NMCVXA-QUPHXYW-CASMZ7M-RYEMQTN-FVQBSPA-H6BQMAY"; };
            "mi11t"         = { id = "3YYJTGH-52MBXOZ-CHNKB42-5LGNWFK-QRJM6GS-N535LR6-BS6HCQN-GW5T2QJ"; };
            # ralu
            "ralue_pixel_7" = { id = "4MMSZK2-4HE35WA-EFVWNA5-W26GBMO-LQHJPW7-BIG6ZZA-EH44LIR-K3ZMGAT"; };
            # j
            "j_big_rig"     = { id = "HWGMO4E-GRF3G32-HL64E63-VQBF6T6-GY4YODD-WPI5PVJ-6DJ2HK6-7USXXAH"; };
            # blade
            "blade_phone"   = { id = "C5IITCD-SC36RFN-CBBVCY2-7PKGJQZ-2CEVD3Z-GEIZGSJ-TA5CIV4-MHBDMAB"; };
            "bladetop"      = { id = "ZX3NYQZ-X564MUA-CX67FTI-VR2KPUR-QO5VXLV-HO3XOAE-4NZWFXN-AVXMYAC"; };
        };
    };
}