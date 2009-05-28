using Endf;
MF7MT2 section;
public void main(string[] args) {
	
	section = new MF7MT2();
	Endf.Parser parser = new Endf.Parser();
	parser.section_end_function = (event) => {
		stdout.printf("section-end\n");
		if(event.MF == 7 && event.MT == 2) {
			section.load(event);
		}
	};
	parser.section_start_function = (event) => {
		stdout.printf("section-start\n");
		event.dump();
	};
	parser.mat_start_function = (event) => {
		stdout.printf("mat-start\n");
	};
	parser.mat_end_function = (event) => {
		stdout.printf("mat-end\n");
	};
	parser.file_start_function = (event) => {
		stdout.printf("file-start\n");
	};
	parser.file_end_function = (event) => {
		stdout.printf("file-end\n");
	};
	parser.tape_start_function = (event) => {
		stdout.printf("tape-start\n");
	};
	parser.tape_end_function = (event) => {
		stdout.printf("tape-end\n");
	};
	parser.add_file("test-data.endf");

	assert( 131.0 == parse_number("1.310000+2"));
	assert( 96 == parse_number("     96  "));
	assert( 0.0 == parse_number("0.00000+0"));
	assert( 1.008e-2 == parse_number("1.008000-2"));

	double T = 1000;
	double [] Es = {
		4.555489e-4,
		4.515512e-3,
		1.988424e-2,
		3e-2,
		4e-2,
		5e-2,
		8e-2,
		1e-1,
		2e-1,
		5e-1,
		1
	};
	for(int i = 0; i< Es.length; i++) {
		stdout.printf("%lf %lf\n", Es[i], section.S(Es[i], T));
	}

}
