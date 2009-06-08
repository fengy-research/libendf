namespace Endf {
	/**
	 * A card represents one line in the ENDF tape(or filesystem file)
	 *
	 * The parser internally only use one card.
	 */
	public struct Card {
		/**
		 * The 6 real numbers in this line, filled by the parser
		 **/
		[CCode (array_length = false)]
		public double[6] numbers;
		/**
		 * The pointer to the starting of the line.
		 */
		public weak string start;
		/**
		 * The pointer to the ending of the line
		 */
		public weak string end;
		/**
		 * META control words of the line.
		 *
		 * It contains the MAT, MF, and MT magic numbers,
		 * defined by MATType, MFType and MTType repectively.
		 *
		 */
		public Section.META meta;
		/**
		 * The line number of this card.
		 */
		public int line;
		/**
		 * format the card to a string
		 */
		public string to_string() {
			StringBuilder sb = new StringBuilder("");
			sb.append_printf("L%d ", line);
			sb.append_printf("M%.4d F%.2d T%.3d ", meta.MAT, meta.MF, meta.MT);
			for(int i = 0; i< 6; i++) {
				sb.append_printf("%e ", numbers[i]);
			}
			return sb.str;
		}
	}


}
