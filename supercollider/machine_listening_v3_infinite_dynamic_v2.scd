(
s.waitForBoot {

    // =========================
    // CONFIG
    // =========================
    ~audioDir = "C:/Users/dell/Documents/projects/Ars-Electronica/machine_listening/audio_clean/";
    ~audioFiles = [
        "01_assembly.wav",
        "02_chassis.wav",
        "03_chassis_human.wav",
        "04_chasis_tanks.wav",
        "05_chassis_assembly.wav",
        "06_chassis_table_0.wav",
        "06_chassis_table_1.wav",
        "06_chassis_table_2.wav",
        "06_chassis_table_3.wav",
        "07_electric_room.wav",
        "08_welding.wav"
    ];

    // =========================
    // CONTROL BUSES (mouse → futuro web)
    // =========================
    ~ctrlX = Bus.control(s, 1); // espacio
    ~ctrlY = Bus.control(s, 1); // energía / filtro

    ~ctrlX.set(0.5);
    ~ctrlY.set(0.5);

    // =========================
    // LOAD BUFFERS
    // =========================
    ~buffers = List.new;

    ~audioFiles.do { |file|
        var path = (~audioDir ++ file);
        if (File.exists(path)) {
            Buffer.read(s, path, action: { |buf|
                ~buffers.add(buf);
                ("Loaded: " ++ file).postln;
            });
        } {
            ("⚠ Archivo faltante: " ++ path).postln;
        };
    };

    s.sync;
    "ALL BUFFERS READY".postln;

    // =========================
    // SYNTHDEF
    // =========================
    SynthDef(\machineLoop, { |bufnum|
        var sig, amp, pan, cutoff;
        var ampRand, panRand, cutoffRand;
        var xCtrl, yCtrl;

        // leer controles (mouse o web)
        xCtrl = In.kr(~ctrlX);
        yCtrl = In.kr(~ctrlY);

        // reproducción completa + loop infinito
        sig = PlayBuf.ar(
            numChannels: 1,
            bufnum: bufnum,
            rate: BufRateScale.kr(bufnum),
            loop: 1
        );

        // amplitud viva
        ampRand = LFNoise1.kr(0.05).range(0.15, 0.6);
        amp = ampRand;

        // paneo: mouse + vida
        panRand = LFNoise1.kr(0.1).range(-0.4, 0.4);
        pan = (xCtrl.linlin(0,1,-1,1) + panRand).clip(-1,1);

        // filtro: mouse Y + deriva lenta
        cutoffRand = LFNoise1.kr(0.03).range(-1200,1200);
        cutoff = (yCtrl.linlin(0,1,300,8000) + cutoffRand).clip(200,10000);
        sig = LPF.ar(sig, cutoff);

        Out.ar(0, Pan2.ar(sig * amp, pan));
    }).add;

    s.sync;

    // =========================
    // DENSITY CONTROL (click)
    // =========================
    ~density = 0.6;

    ~densityControl = Routine {
        loop {
            if (MouseButton.kr(0,1) > 0.5) {
                ~density = rrand(0.2, 1.0);
                ("New density: " ++ ~density).postln;
                0.4.wait;
            };
            0.1.wait;
        };
    }.play;

    // =========================
    // MOUSE → CONTROL BUSES
    // =========================
    Routine {
        loop {
            ~ctrlX.set(MouseX.kr(0,1));
            ~ctrlY.set(MouseY.kr(0,1));
            0.05.wait;
        };
    }.play;

    // =========================
    // PLAYER
    // =========================
    ~player = Routine {
        loop {
            ~buffers.do { |buf|
                if (1.0.rand < ~density) {
                    Synth(\machineLoop, [\bufnum, buf.bufnum]);
                };
                rrand(0.5, 3.0).wait;
            };
        };
    }.play;

    "All machines initialized and looping!".postln;
    "Mouse X = space | Mouse Y = energy | Click = new density".postln;
};
)