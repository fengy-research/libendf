namespace Endf {
	/**
	 * Parse an ENDF tape
	 *
	 * The parser parses each line(card) of the ENDF file,
	 * and emits a card_event for it.
	 * */
	public class Parser {
		public delegate void CardFunction (Parser parser);
		StringBuilder MAT_buffer = new StringBuilder("");
		StringBuilder MT_buffer = new StringBuilder("");
		StringBuilder MF_buffer = new StringBuilder("");
		StringBuilder NUM_buffer = new StringBuilder("");
		/**
		 * The callback function when a card is parsed
		 * */
		public CardFunction card_function;
		/**
		 * The internally used card, will be send to the card_function.
		 */
		public Card card = Card();

		/**
		 * Parse a ENDF formatted number.
		 *
		 * Examples:
		 *  1.12341+11
		 *  1.231243-54
		 *  12
		 *   9
		 */
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

		/**
		 * The current cursor in the string being parsed.
		 */
		private weak string p;
		/**
		 * Parse more string
		 */
		public void add_string(string str) {
			p = str;
			while(fetch_card()) {
				if(card_function != null)
					card_function(this);
			}
		}
		public bool fetch_card() {
			unichar c = p.get_char();
			int column = 0;
			int i = 0;
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
					card.line ++;
					p = p.next_char();
					return true;
				}
			}
			return false;
		}
		/**
		 * Open the file, load the content and parse it.
		 */
		public void add_file(string filename) throws GLib.Error {
			string str;
			FileUtils.get_contents(filename, out str);
			add_string(str);
		}
	}


	/**
	 * Load endf file into memory and build the Section objects.
	 *
	 */
	public class Loader {
		private HashTable<Section.META?, weak Section> dict
		 = new HashTable<Section.META?, weak Section>(
			(HashFunc) Section.META.hash,
			(EqualFunc) Section.META.equal);
		private List<Section> sections;

		private Parser parser = new Parser();
		private Section.META meta;
		private Section section;

		public Loader() {
			parser.card_function = card_function;
		}
		/**
		 * load more ENDF objects from a string
		 */
		public void add_string(string str) {
			parser.add_string(str);
		}
		/**
		 * load more ENDF objects from a file
		 */
		public void add_file(string filename) throws GLib.Error {
			parser.add_file(filename);
		}
		/**
		 * Dispatch the card event from the parser.
		 * */
		private void card_function(Parser parser) {
			Card card = parser.card;
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
				return;
			}
		}
		/**
		 * save the current section. Invoked by card_function when the current section ends.
		 */
		private void push_current_section() {
			if(section != null) {
				section.meta = meta;
				dict.insert(section.meta, section);
				sections.prepend((owned)section);
			}
		}

		/**
		 * start a new section. Invoked by card_function when a 
		 * new section starts.
		 **/
		private void start_new_section(Card card) {
			switch(card.meta.MF) {
				case MFType.THERMAL_SCATTERING:
				switch(card.meta.MT) {
					case MTType.ELASTIC:
						section = new MF7MT2();
					break;
				}
				break;
			}
			if(section != null)
				section.accept(parser);
		}
		/**
		 * Look up the specific section from all built ENDF objects
		 *
		 * @param MAT
		 *        the material id
		 * @param MF
		 *        the file number
		 * @param MT
		 *        the section number
		 *
		 * @return null if the section is not ever parsed,
		 *         the specific section if it is built.
		 */
		public Section? lookup(MATType MAT, MFType MF, MTType MT) {
			Section.META meta = { MAT, MF, MT };
			return dict.lookup(meta);
		}
	}
}
