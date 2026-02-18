// ==================================================
// MACHINES LISTENING TO THEMSELVES
// SuperCollider Engine v2.0 (mejorado)
// ==================================================

s.waitForBoot {

	"Server booted".postln;

	// --------------------------------------------------
	// AUDIO PATH
	// --------------------------------------------------
	~audioPath = "C:/Users/dell/Documents/projects/Ars-Electronica/machine_listening/audio_clean/";

	// --------------------------------------------------
	// BUFFER SETUP
	// --------------------------------------------------
	~buffers = IdentityDictionary.new;

	~bufferNames = [
		"01_assembly",
		"02_chassis",
		"03_chassis_human",
		"04_chasis_tanks",
		"05_chassis_assembly",
		"06_chassis_table_0",
		"06_chassis_table_1",
		"06_chassis_table_2",
		"06_chassis_table_3",
		"07_electric_room",
		"08_welding"
	];

	"Loading buffers...".postln;

	~bufferNames.do { |name|
		var path = ~audioPath ++ name ++ ".wav";
		~buffers[name] = Buffer.read(s, path, action: { |buf|
			("Loaded: " ++ name ++ " bufnum: " ++ buf.bufnum).postln;
		});
	};

	s.sync; // esperar a que todos los buffers terminen de cargar
	"ALL BUFFERS READY".postln;

	// Verificación rápida de buffers
	~buffers.keysDo { |k|
		if (~buffers[k].notNil) {
			("Buffer ok: " ++ k ++ " bufnum: " ++ ~buffers[k].bufnum).postln;
		} {
			("ERROR: Buffer NIL -> " ++ k).postln;
		}
	};

	// --------------------------------------------------
	// CONTROL BUSSES
	// --------------------------------------------------
	~listenerBus = Bus.control(s, 2);
	"Control buses created".postln;

	// --------------------------------------------------
	// SYNTH DEFINITIONS
	// --------------------------------------------------

	// Listener position (virtual body)
	SynthDef(\listenerControl, {
		|x = 0.5, y = 0.5|
		Out.kr(~listenerBus, [x, y]);
	}).add;

	"Listener control synth defined".postln;

	// Machine sound field
	SynthDef(\machineField, {
		|buf = 0, areaX = 0.5, areaY = 0.5, maxGain = 1.0|
		var listenerPos, dist, amp, sig;

		// Obtener posición del listener
		listenerPos = In.kr(~listenerBus, 2);

		// Distancia entre listener y máquina
		dist = ((listenerPos[0] - areaX).squared + (listenerPos[1] - areaY).squared).sqrt.clip(0.01, 1);

		// Volumen según distancia
		amp = (1 - dist).clip(0, 1);

		// Reproducir buffer
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1);

		// Filtro LPF dinámico (menos agresivo)
		sig = LPF.ar(sig, dist.linexp(0.01, 1, 20000, 2000));

		// Ganancia final
		sig = sig * amp * maxGain;

		// Salida estéreo
		Out.ar(0, sig.dup);
	}).add;

	"Machine synth defined".postln;
	s.sync;

	// --------------------------------------------------
	// START SYSTEM
	// --------------------------------------------------
	~listener = Synth(\listenerControl);

	// Crear máquinas solo si el buffer existe
	~machines = [
		~buffers["01_assembly"].notNil.if({ Synth(\machineField, [\buf, ~buffers["01_assembly"].bufnum, \areaX, 0.1, \areaY, 0.2]) }, { nil }),
		~buffers["02_chassis"].notNil.if({ Synth(\machineField, [\buf, ~buffers["02_chassis"].bufnum, \areaX, \areaY, 0.9, 0.3]) }, { nil }),
		~buffers["03_chassis_human"].notNil.if({ Synth(\machineField, [\buf, ~buffers["03_chassis_human"].bufnum, \areaX, 0.4, \areaY, 0.8]) }, { nil }),
		~buffers["04_chasis_tanks"].notNil.if({ Synth(\machineField, [\buf, ~buffers["04_chasis_tanks"].bufnum, \areaX, 0.6, \areaY, 0.6]) }, { nil }),
		~buffers["08_welding"].notNil.if({ Synth(\machineField, [\buf, ~buffers["08_welding"].bufnum, \areaX, 0.5, \areaY, 0.5]) }, { nil })
	].reject(_.isNil);

	"Machine field initialized".postln;
	"Listener active".postln;

	// --------------------------------------------------
	// MOVIMIENTO AUTOMÁTICO DEL LISTENER (opcional)
	// --------------------------------------------------
	~listenerMotion = {
		var t = 0.0;
		{
			t = t + 0.01;
			~listener.set(\x, 0.5 + 0.3 * sin(t), \y, 0.5 + 0.3 * cos(t));
			0.05.wait;
		}.loop;
	}.fork;

	"Listener motion started".postln;

};