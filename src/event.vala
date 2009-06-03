namespace Endf {
	public struct Card {
		[CCode (array_length = false)]
		public double[6] numbers;
		public weak string start;
		public weak string end;
		public Section.META meta;
		public int line;
		public string to_string() {
			StringBuilder sb = new StringBuilder("");
			sb.append_printf("%d: ", line);
			for(int i = 0; i< 6; i++) {
				sb.append_printf("%.011lf ", numbers[i]);
			}
			return sb.str;
		}
	}

	public delegate void CardFunction (Card card);

}
