namespace Endf {
	public double parse_number(string s) {
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
