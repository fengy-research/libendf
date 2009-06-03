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
		StringBuilder MAT_buffer = new StringBuilder("");
		StringBuilder MT_buffer = new StringBuilder("");
		StringBuilder MF_buffer = new StringBuilder("");
		StringBuilder NUM_buffer = new StringBuilder("");
		public CardFunction card_function;
		Card card = Card();
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
						card.numbers[i] = NUM_buffer.str.to_double();
						NUM_buffer.truncate(0);
					}
					i++;
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
	public class Section {
		public struct META {
			public MATType MAT;
			public MFType MF;
			public MTType MT;
			public uint to_uint() {
				return (uint)MAT * 100000 + (uint) MF * 1000 + (uint) MT;
			}
			public static uint hash(META h) {
				return h.to_uint();
			}
			public static bool equal(META h1, META h2) {
				return h1.to_uint() == h2.to_uint();
			}
		}
		public META meta;
		public virtual void accept_head(Card card) {
			
		}
		/**
		 * @return true if it is full.
		 */
		public virtual bool accept_card(Card card) {
			return false;
		}
	}
	public class TAB {
		public int NR;
		public int NP;
		public Interpolation INT;
		[CCode (array_length = false)]
		public weak double[] X;
		[CCode (array_length = false)]
		public weak double[] Y;

		private int state;
		private const int HEAD_DONE = 0;
		private const int INT_DONE = 1;
		private const int DATA_DONE = 2;
		private int i;

		public void accept_head(Card card) {
			NR = (int)card.numbers[4];
			NP = (int)card.numbers[5];
			INT = new Interpolation(NR);
			state = HEAD_DONE;
		}
		public bool accept_card(Card card) {
			if(state == DATA_DONE) {
				return true;
			}
			if(state == HEAD_DONE) {
				if(!INT.accept_card(card)) {
					state = INT_DONE;
				/* recover to fill the data*/
					i = 0;
				}
			}
			if(state == INT_DONE) {
				X[i] = card.numbers[0];
				Y[i] = card.numbers[1];
				i++;
				if(i == NR) {
					state = DATA_DONE;
					return false;
				}
				X[i] = card.numbers[2];
				Y[i] = card.numbers[3];
				i++;
				if(i == NR) {
					state = DATA_DONE;
					return false;
				}
				X[i] = card.numbers[4];
				Y[i] = card.numbers[5];
				if(i == NR) {
					state = DATA_DONE;
					return false;
				}
			}
			return false;
		}
	}
	public class LIST {
		public int NP;
		[CCode (array_length = false)]
		public weak double[] Y;
		private const int HEAD_DONE = 0;
		private int state;
		private int i;
		public void accept_head(Card card) {
			NP = (int) card.numbers[4];
			state = HEAD_DONE;
			i = 0;
		}
		public bool accept_card(Card card) {
			if(i > NP) return true;
			if(state == HEAD_DONE) {
				for(int j = 0; j < 6; j++) {
					Y[i] = card.numbers[0];
					i++;
					if(i > NP) return false;
				}
			}
			return false;
		}
	}

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
			}
		}
		public void push_current_section() {
			if(section != null) {
				section.meta = meta;
				message("%u", meta.to_uint());
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
			message("%u", meta.to_uint());
			return dict.lookup(meta);
		}
	}
}
