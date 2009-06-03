using Endf;

public void main(string[] args) {
	
	Loader loader = new Loader();
	loader.add_file("test-data.endf");
	Section s = loader.lookup((MATType)31, MFType.THERMAL_SCATTERING, MTType.ELASTIC);
	assert(s is MF7MT2);
}
