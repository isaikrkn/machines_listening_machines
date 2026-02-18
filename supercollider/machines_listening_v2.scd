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
    // LOAD BUFFERS
    // =========================
    ~buffers = List.new;

    ~audioFiles.do { |file|
        var path = (~audioDir ++ file).asString;
        if (File.exists(path)) {
            Buffer.read(s, path, action: { |buf|
                ~buffers.add(buf);
                ("Loaded: " ++ file ++ " bufnum: " ++ buf.bufnum).postln;
            });
        } {
            ("⚠ Archivo faltante: " ++ path).postln;
        };
    };

    // ⛔ Esperar a que TODOS los buffers estén listos
    s.sync;

    "ALL BUFFERS READY".postln;

    // =========================
    // SYNTHDEF
    // =========================
    SynthDef(\machinePlayer, { |bufnum, amp = 0.4|
        var sig, env;
        env = EnvGen.kr(Env.linen(0.01, 1.0, 0.2), doneAction: 2);
        sig = PlayBuf.ar(
            numChannels: 1,
            bufnum: bufnum,
            rate: BufRateScale.kr(bufnum),
            loop: 1
        );
        Out.ar(0, (sig * env * amp).dup);
    }).add;

    s.sync;

    // =========================
    // PLAYER ROUTINE
    // =========================
    ~player = Routine {
        loop {
            ~buffers.do { |buf|
                if (buf.notNil and: { buf.numFrames > 0 }) {
                    Synth(\machinePlayer, [\bufnum, buf.bufnum]);
                    2.0.wait;
                };
            };
        };
    }.play;

    "All machines initialized and looping!".postln;
};
)