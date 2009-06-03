using Endf;

public void main(string[] args) {
	Gsl.RNG rng = new Gsl.RNG(Gsl.RNGTypes.mt19937);
	Loader loader = new Loader();
	loader.add_file("test-data.endf");
	Section s = loader.lookup((MATType)31, MFType.THERMAL_SCATTERING, MTType.ELASTIC);
	assert(s is MF7MT2);
	var mf7mt2 = s as MF7MT2;
	mf7mt2.T = 296;
	double [] E = {
		0.01,
		0.1,
		1
	};
	for(int i = 0; i< E.length; i++) {
		mf7mt2.E = E[i];
		stdout.printf("%lf %lf\n", E[i], mf7mt2.S());
	}
	mf7mt2.E = 0.03;
	mf7mt2.T = 1000;
	for(int i = 0; i< 1000; i++) {
		double mu;
		mf7mt2.random_event(rng, out mu);
		stdout.printf("%lf\n", mu);
	}
}
