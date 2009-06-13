using Endf;

public void main(string[] args) {
	Gsl.RNG rng = new Gsl.RNG(Gsl.RNGTypes.mt19937);
	Loader loader = new Loader();
	loader.add_file("test-data.endf");

	Section s4 = loader.lookup((MATType)31, MFType.THERMAL_SCATTERING, MTType.REACTION_Z_N);
	assert(s4 is MF7MT4);
	var mf7mt4 = s4 as MF7MT4;

	//stdout.printf(s4.to_string());

	mf7mt4.E = 0.2;
	mf7mt4.T = 300;
	double Eout = 0.9;
	for(int i = 0; i< 20; i++) {
		double mu = (double)i / 10.0 - 1.0;
		double dS = mf7mt4.dS(Eout, mu);
		stdout.printf("%le %le\n", mu, dS);
	}
}
