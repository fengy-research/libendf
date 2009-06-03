namespace Endf {
	/**
	 * Parse an ENDF tape
	 *
	 * The parser parses each line(card) of the ENDF file,
	 * and emits a card_event for it.
	 *
	 * */
	public class Parser {
		StringBuilder MAT_buffer = new StringBuilder("");
		StringBuilder MT_buffer = new StringBuilder("");
		StringBuilder MF_buffer = new StringBuilder("");
		StringBuilder NUM_buffer = new StringBuilder("");
		public CardFunction card_function;
		Card card = Card();

		private static double parse_number(string s) {
			unowned string endptr;
			double radix;
			int m = 0;
			int m_sign = 0;
			radix = s.to_double(out endptr);
			unichar sign = endptr.get_char();
			if(sign == 0 || sign.isspace()) return radix;
			if(sign == '+') m_sign = 1;
			if(sign == '-') m_sign = -1;
			endptr = endptr.next_char();
			m = endptr.to_int();
			return radix * Math.pow(10, m_sign * m);
		}

		public void add_string(string str) {
			int column = 0;
			int i = 0;
			weak string p = str;
			unichar c = p.get_char();
			for(c = p.get_char(); c != 0;
				p = p.next_char(), c = p.get_char()) {
				if(column == 0) {
					card.start = p;
				}
				if(column >=0 && column < 66) {
					NUM_buffer.append_unichar(c);
					if((column + 1) % 11 == 0) {
						card.numbers[i] = parse_number(NUM_buffer.str);
						NUM_buffer.truncate(0);
						i++;
					}
				}
				if(column == 66) {
					card.end = p;
				}
				if(column >= 66 && column < 70) {
					MAT_buffer.append_unichar(c);
				}
				if(column == 70) {
					card.meta.MAT = (MATType) MAT_buffer.str.to_int();
					MAT_buffer.truncate(0);
				}
				if(column >= 70 && column < 72) {
					MF_buffer.append_unichar(c);
				}
				if(column == 72) {
					card.meta.MF = (MFType) MF_buffer.str.to_int();
					MF_buffer.truncate(0);
				}
				if(column >= 72 && column < 75) {
					MT_buffer.append_unichar(c);
				}
				if(column == 75) {
					card.meta.MT = (MTType) MT_buffer.str.to_int();
					MT_buffer.truncate(0);
				}
				column++;
				if(c == '\n') {
					column = 0;
					i = 0;
					card.line ++;
					if(card_function != null)
						card_function(card);
				}
			}
		}
		public void add_file(string filename) throws GLib.Error {
			string str;
			FileUtils.get_contents(filename, out str);
			add_string(str);
		}
	}


	/**
	 * The loader loads endf file into memory and build the Section objects.
	 *
	 */
	public class Loader {
		public HashTable<Section.META?, weak Section> dict
		 = new HashTable<Section.META?, weak Section>(
			(HashFunc) Section.META.hash,
			(EqualFunc) Section.META.equal);
		List<Section> sections;

		private Parser parser = new Parser();
		public Section.META meta;

		public Section section;

		public Loader() {
			parser.card_function = card_function;
		}
		public void add_string(string str) {
			parser.add_string(str);
		}
		public void add_file(string filename) throws GLib.Error {
			parser.add_file(filename);
		}
		public void card_function(Card card) {
			if(!Section.META.equal(meta, card.meta)) {
				if(card.meta.MT == MTType.SECTION_END) {
					push_current_section();
					meta = card.meta;
					return;
				} 
				if(meta.MT == MTType.SECTION_END &&
					card.meta.MT != MTType.SECTION_END) {
					start_new_section(card);
					meta = card.meta;
					return;
				}
			} else {
				if(section != null) {
					section.accept_card(card);
				}
			}
		}
		public void push_current_section() {
			if(section != null) {
				section.meta = meta;
				dict.insert(section.meta, section);
				sections.prepend((owned)section);
			}
		}
		public void start_new_section(Card card) {
			switch(card.meta.MF) {
				case MFType.THERMAL_SCATTERING:
				switch(card.meta.MT) {
					case MTType.ELASTIC:
						section = new MF7MT2();
						section.accept_head(card);
					break;
				}
				break;
			}
		}
		public Section? lookup(MATType MAT, MFType MF, MTType MT) {
			Section.META meta = { MAT, MF, MT };
			return dict.lookup(meta);
		}
	}
}
