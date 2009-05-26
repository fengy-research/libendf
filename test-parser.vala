using Endf;
public void main(string[] args) {
	
	Endf.Parser parser = new Endf.Parser();
	parser.section_end_function = (event) => {
		stdout.printf("section-end\n");
		event.dump();
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

}
