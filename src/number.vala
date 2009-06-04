/* DEPRECATED */
namespace Endf {
	public double read_number(string p, out unowned string outptr) {
		StringBuilder buffer = new StringBuilder("");
		for(int i = 0; i < 11; i++) {
			unichar c = 0;
			do {
				c = p.get_char();
				p = p.next_char();
			} while(c == '\n' || c == '\a' );
			buffer.append_unichar(c);
		}
		outptr = p;
		return parse_number(buffer.str);
	}
	public void skip_to_next_line(string p, out weak string outptr) {
		unichar c = 0;
		do {
			c = p.get_char();
			p = p.next_char();
		} while(c != '\n');
		outptr = p;
	}
}
