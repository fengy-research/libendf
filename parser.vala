namespace Endf {
	/**
	 * Parse an ENDF tape
	 *
	 * The parser emits events at certain points of the stream.
	 *
	 * The most useful event is SectionEvent at section end,
	 * listen to that event by setting a function to
	 * `section_end_event' .
	 *
	 * In the event handler, filter the MF and MT number,
	 * then load the event content into a Section object,
	 * e.g, MF7MT2 or MF7MT4.
	 *
	 * */

	public class Parser {

		StringBuilder content_buffer = new StringBuilder("");
		StringBuilder line_buffer = new StringBuilder("");
		StringBuilder MAT_buffer = new StringBuilder("");
		StringBuilder MF_buffer = new StringBuilder("");
		StringBuilder MT_buffer = new StringBuilder("");
		StringBuilder LN_buffer = new StringBuilder("");

		SectionEvent section_event;
		FileEvent file_event;
		MaterialEvent mat_event;
		TapeEvent tape_event;

		MTType MT;
		MATType MAT;
		MFType MF;

		int line = 0;
		int column = 0;
		private bool tape_not_started = true;
		public SectionEventFunction section_start_function;
		public FileEventFunction file_start_function;
		public MaterialEventFunction mat_start_function;
		public TapeEventFunction tape_start_function;
		public SectionEventFunction section_end_function;
		public FileEventFunction file_end_function;
		public MaterialEventFunction mat_end_function;
		public TapeEventFunction tape_end_function;

		public void add_string(string str) {
			weak string p = str;
			unichar c = p.get_char();
			for(c = p.get_char(); c != 0;
				p = p.next_char(), c = p.get_char()) {
				add_char(c);
			}
		}
		public void add_file(string filename) throws GLib.Error {
			string str;
			FileUtils.get_contents(filename, out str);
			add_string(str);
		}
		public void add_char(unichar c) {
			if(column < 66) {
				line_buffer.append_unichar(c);
			} else if(column < 70) {
				MAT_buffer.append_unichar(c);
			} else if(column < 72) {
				MF_buffer.append_unichar(c);
			} else if(column < 75) {
				MT_buffer.append_unichar(c);
			} else {
				LN_buffer.append_unichar(c);
			}

			if(advance_column(c)) {
				finish_line();
				line ++;
			}
			return;
		}
		public bool advance_column(unichar c) {
			switch (c) {
				case '\n':
					column = 0;
					return true;
				case '\t':
					column = ((column >> 3) + 1) << 3;
					return false;
				default:
					column++;
					return false;
			}
		}
		private void finish_line () {
			int LN = LN_buffer.str.to_int();
			MATType MAT = (MATType) MAT_buffer.str.to_int();
			MFType MF = (MFType) MF_buffer.str.to_int();
			MTType MT = (MTType) MT_buffer.str.to_int();
			
			bool fire_mat = !tape_not_started 
			              && (this.MAT != MAT)
			              && (MAT != -1);

			bool fire_file = (this.MF != MF);
			bool fire_section = (this.MT != MT) ;

			if(MAT == MATType.TAPE_END) {
				tape_event.end = line -1;
				if(tape_end_function != null) {
					tape_end_function(tape_event);
				}
				
			}
			if(tape_not_started) {
				tape_event.start = line;
				tape_event.id = MAT;
				MAT = MATType.TAPE_END;
				if(tape_start_function != null) {
					tape_start_function(tape_event);
				}
			}
			if(fire_mat) {
				if(MAT != MATType.MAT_END) {
					mat_event.MAT = MAT;
					mat_event.start = line;
					mat_event.end = -1;
					if(mat_start_function != null) {
						mat_start_function(mat_event);
					}
				} else {
					mat_event.end = line - 1;
					if(mat_end_function != null) {
						mat_end_function(mat_event);
					}
				}
			}
			if(fire_file) {
				if(MF != MFType.FILE_END) {
					file_event.MAT = MAT;
					file_event.MF = MF;
					file_event.start = line;
					file_event.end = -1;
					if(file_start_function != null) {
						file_start_function(file_event);
					}
				} else {
					file_event.end = line - 1;
					if(file_end_function != null) {
						file_end_function(file_event);
					}
				}
			}
			if(fire_section) {
				if(MT != MTType.SECTION_END) {
					section_event.start = line;
					section_event.MAT = MAT;
					section_event.MF = MF;
					section_event.MT = MT;
					content_buffer.truncate(0);
					section_event.end = -1;
					section_event.content = null;
					if(section_start_function != null) {
						section_start_function(section_event);
					}
				} else {
					section_event.content = content_buffer.str;
					section_event.end = line - 1;
					if(section_end_function != null) {
						section_end_function(section_event);
					}
				} }

			this.MAT = MAT;
			this.MF = MF;
			this.MT = MT;
			tape_not_started = false;
			content_buffer.append(line_buffer.str);
			content_buffer.append_unichar('\n');
			LN_buffer.truncate(0);
			MAT_buffer.truncate(0);
			MF_buffer.truncate(0);
			MT_buffer.truncate(0);
			line_buffer.truncate(0);
		}
	}
}
