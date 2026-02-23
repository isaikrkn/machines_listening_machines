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
    // CONTROL BUSES (web-ready)
    // =========================
    ~densityBus = Bus.control(s, 1);   // velocidad de cambio / energía interna
    ~energyBus  = Bus.control(s, 1);   // amplitud global / intención humana

    // valores iniciales (estado base)
    ~densityBus.set(0.3);
    ~energyBus.set(0.6);

    // =========================
    // LOAD BUFFERS
    // =========================
    ~buffers = List.new;

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
    // SYNTHDEF – MACHINE LOOP
    // =========================
SynthDef(\machineLoop, { |bufnum|
    var sig;
    var ampRand, amp;
    var densityHuman, energyHuman;
    var densityAuto, energyAuto;
    var densityFinal, energyFinal;

    // =========================
    // CONTROL HUMANO (WEB / OSC)
    // =========================
    densityHuman = In.kr(~densityBus).linlin(0, 1, 0.05, 1.5);
    energyHuman  = In.kr(~energyBus).linlin(0, 1, 0.05, 1.0);

    // =========================
    // ESTADO AUTÓNOMO (LENTO)
    // =========================
    densityAuto = Lag.kr(
        LFNoise1.kr(0.02).range(0.05, 1.2),
        8
    );

    energyAuto = Lag.kr(
        LFNoise1.kr(0.015).range(0.1, 0.9),
        10
    );

    // =========================
    // FUSIÓN HUMANO + MÁQUINA
    // =========================
    densityFinal = (densityHuman * 0.5) + (densityAuto * 0.5);
    energyFinal  = (energyHuman  * 0.5) + (energyAuto  * 0.5);

    // =========================
    // VARIACIÓN ORGÁNICA
    // =========================
    ampRand = LFNoise1.kr(densityFinal).range(0.05, 0.9);
    amp = ampRand * energyFinal;

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
    // START ONE LOOP PER WAV
    // =========================
    ~loops = ~buffers.collect { |buf|
        if (buf.notNil and: { buf.numFrames > 0 }) {
            Synth(\machineLoop, [\bufnum, buf.bufnum]);
        };
    };

    "All machines initialized and looping!".postln;
    "Waiting for OSC control on /control [density, energy]".postln;

    // =========================
    // OSC CONTROL (FROM WEB)
    // =========================
    OSCdef(\webControl, { |msg|
        var density = msg[1];
        var energy  = msg[2];

        if (density.notNil and: energy.notNil) {
            ~densityBus.set(density.clip(0, 1));
            ~energyBus.set(energy.clip(0, 1));
        };
    }, '/control');

};
)

~densityBus.set(0.1);   // cambios lentos
~densityBus.set(0.9);   // cambios nerviosos

~energyBus.set(0.2);    // ambiente lejano
~energyBus.set(1.0);    // presencia fuerte

