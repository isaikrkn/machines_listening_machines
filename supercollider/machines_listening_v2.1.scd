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

    ~buffers = List.new;

    // =========================
    // LOAD BUFFERS
    // =========================
    ~audioFiles.do { |file|
        var path = ~audioDir ++ file;
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
        var sig;
        var amp, ampRand;
        var densityCtrl;
        var mouseX, mouseY;

        // =========================
        // MOUSE CONTROL
        // =========================
        // X = velocidad del azar (densidad perceptual)
        mouseX = MouseX.kr(0.05, 2.0);

        // Y = energía / amplitud
        mouseY = MouseY.kr(0.05, 1.0);

        // =========================
        // ALEATORIEDAD ORGÁNICA
        // =========================
        densityCtrl = LFNoise1.kr(mouseX).range(0.1, 1.0);
        ampRand     = LFNoise1.kr(densityCtrl).range(0.05, 0.9);

        amp = ampRand * mouseY;

        // =========================
        // AUDIO
        // =========================
        sig = PlayBuf.ar(
            numChannels: 1,
            bufnum: bufnum,
            rate: BufRateScale.kr(bufnum),
            loop: 1
        );

        Out.ar(0, (sig * amp).dup);
    }).add;

    s.sync;

    // =========================
    // CREATE LOOPS
    // =========================
    ~loops = ~buffers.collect { |buf|
        if (buf.notNil and: { buf.numFrames > 0 }) {
            Synth(\machineLoop, [\bufnum, buf.bufnum]);
        };
    };

    "All machines initialized and looping!".postln;
    "Mouse X = density / nervousness".postln;
    "Mouse Y = energy / amplitude".postln;
};
)