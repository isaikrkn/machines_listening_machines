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
    // SYNTHDEF LOOP DINÁMICO
    // =========================
SynthDef(\machineLoop, { |bufnum|
    var sig;
    var ampRand, amp;
    var speedRand;
    var mouseX, mouseY;

    // =========================
    // MOUSE CONTROL
    // =========================
    mouseX = MouseX.kr(0.02, 0.2);   // velocidad de cambios
    mouseY = MouseY.kr(0.1, 1.0);    // intensidad general

    // =========================
    // ALEATORIEDAD MODULADA
    // =========================
    speedRand = LFNoise1.kr(mouseX).range(0.05, 1.0);
    ampRand   = LFNoise1.kr(speedRand).range(0.05, 0.8);

    // Amplitud final = azar * intención humana
    amp = ampRand * mouseY;

    // =========================
    // AUDIO
    // =========================
    sig = PlayBuf.ar(
        1,
        bufnum,
        BufRateScale.kr(bufnum),
        loop: 1
    );

    Out.ar(0, (sig * amp).dup);
}).add;

    s.sync;

    // =========================
    // CREAR UN LOOP POR WAV
    // =========================
    ~loops = ~buffers.collect { |buf|
        if (buf.notNil and: { buf.numFrames > 0 }) {
            Synth(\machineLoop, [\bufnum, buf.bufnum]);
        };
    };

    "All loops running infinitely with dynamic amplitude.".postln;
};
)