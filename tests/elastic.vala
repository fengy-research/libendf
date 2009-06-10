using Endf;
private int mat = 31;
private int mf = 7;
private int mt = 2;
private double T = 300.0;
private double E = 1.0;
private int count = 1000;
private string filename = null;

private const OptionEntry[] options = {
	{"mat", 'm', 0, OptionArg.INT, out mat, "ENDF material", "MAT"},
	{"mf", 'f', 0, OptionArg.INT, out mf, "ENDF file", "MF"},
	{"mt", 't', 0, OptionArg.INT, out mt, "ENDF section", "MT"},
	{"section", 's', 0, OptionArg.INT, out mt, "ENDF section, alias of mt", "MT"},
	{"temprature", 'T', 0, OptionArg.DOUBLE, out T, "Temprature", "in K"},
	{"energy", 'E', 0, OptionArg.DOUBLE, out E, "Energy", "in EV"},
	{"count", 'c', 0, OptionArg.INT, out count, "number of events", "N"},
	{"file", 'F', 0, OptionArg.FILENAME, out filename, "endf file", "filenaem"},
	{null}
};

public int main(string[] args) {
	filename = "test-data.endf";
	var opc = new OptionContext("generating random mu for an elastic section");

	opc.add_main_entries (options, null);
	opc.set_help_enabled(true);
	opc.parse(ref args);

	Gsl.RNG rng = new Gsl.RNG(Gsl.RNGTypes.mt19937);
	Loader loader = new Loader();
	loader.add_file(filename);

	var s = loader.lookup((MATType)mat, (MFType)mf, (MTType) mt);
	assert(s is Elastic);
	var elastic = s as Elastic;
	elastic.T = T;
	elastic.E = E;
	for(int i = 0; i< count; i++) {
		double mu;
		elastic.random_event(rng, out mu);
		stdout.printf("%lf\n", mu);
	}
	return 0;
}
