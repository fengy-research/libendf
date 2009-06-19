using Endf;

private double E = 0.4;
private double T = 296.0;
private double Eout = 0.3;
private double mu = 0.4;
private double Eout_min;
private double Eout_max;
private int bins = 10;
private enum ScanMode {
	MU,
	EOUT
}
private ScanMode mode = ScanMode.MU;

private bool Eout_callback(string option_name, string value, void* data) throws GLib.Error {
	weak string comma = value.chr(-1, ',');
	if(comma == null) {
		mode = ScanMode.MU;
		Eout = value.to_double();
	} else {
		mode = ScanMode.EOUT;
		Eout_min = value.to_double();
		Eout_max = comma.next_char().to_double();
		message("%lf %lf", Eout_min, Eout_max);
	}
	message("mode = %d", mode);
	return true;
}
private const OptionEntry[] entries = {

	{"E", 'E', 0, OptionArg.DOUBLE, out E, "incident energy", "ev"},
	{"T", 'T', 0, OptionArg.DOUBLE, out T, "temperature", "K"},
	{"bins", 'b', 0, OptionArg.INT, out bins, "number of bins", "bins"},
	{"Eout", 'O', 0, OptionArg.CALLBACK, (void*)Eout_callback, "outcoming energy", "ev"},
	{"mu", 'M', 0, OptionArg.DOUBLE, out mu, "cos(outcoming angle)", "-1 to 1"},
	{null}
};
public void main(string[] args) {
	OptionContext oc = new OptionContext("dump mt4 crosssection data");
	oc.add_main_entries(entries, null);
	oc.parse(ref args);
	Loader loader = new Loader();
	loader.add_file("test-data.endf");

	Section s4 = loader.lookup((MATType)31, MFType.THERMAL_SCATTERING, MTType.REACTION_Z_N);
	assert(s4 is MF7MT4);
	var mf7mt4 = s4 as MF7MT4;

	//stdout.printf(s4.to_string());

	mf7mt4.E = E;
	mf7mt4.T = T;
	switch(mode) {
		case ScanMode.EOUT:
			for(int i = 0; i <= bins; i++) {
				double Eout = (double) i / bins * (Eout_max - Eout_min) + Eout_min;
				double dS = mf7mt4.dS(Eout, mu);
				stdout.printf("%le %le\n", Eout, dS);
			}
		break;
		case ScanMode.MU:
			for(int i = 0; i<= bins; i++) {
				double mu = (double)i / bins * 2.0 - 1.0;
				double dS = mf7mt4.dS(Eout, mu);
				stdout.printf("%le %le\n", mu, dS);
			}
		break;
	}
}
