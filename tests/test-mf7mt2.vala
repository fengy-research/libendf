using Endf;

public void main(string[] args) {
	Gsl.RNG rng = new Gsl.RNG(Gsl.RNGTypes.mt19937);
	Loader loader = new Loader();
	loader.add_file("test-data.endf");
	Section s2 = loader.lookup((MATType)31, MFType.THERMAL_SCATTERING, MTType.ELASTIC);
	assert(s2 is MF7MT2);
	var mf7mt2 = s2 as MF7MT2;
	mf7mt2.T = 296;
	weak double [] E = mf7mt2.COH.E;
	//stdout.printf(s2.to_string());

	for(int i = 0; i< E.length ; i++) {
		mf7mt2.E = E[i];
		stdout.printf("%lf %lf\n", E[i], mf7mt2.S());
	}

}
