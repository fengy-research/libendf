namespace Endf {
	/**
	 * An ENDF interpolation
	 *
	 * ENDF has 7 types of interpolations, and uses an awkward table format to 
	 * specify which range of the data should be interpolated in which way.
	 * 
	 * Example: FIXME
	 */
	public class Interpolation : Acceptor {
		public INTType [] type;
		public int[] range_end;
		public int NR;
		/**
		 * The index of the last empty range to be filled in.
		 * */
		public int i;

		/**
		 * Creates an Interpolation with NR ranges.
		 *
		 * @param NR
		 *        the number of ranges
		 */
		public Interpolation(int NR) {
			this.NR = NR;
			type = new INTType[NR];
			range_end = new int[NR];
			i = 0;
		}

		/**
		 * Parse a card. Never reuse an Interpolation object after it has been
		 * parsed.
		 *
		 * @return if the card is rejected.
		 */
		public void accept(Parser parser) throws Error {
			while(accept_card(parser.card)) {
				if(!parser.fetch_card()) {
					throw new 
					Error.MALFORMED("unexpected stream end when parsing a INTERPOLATION");
				}
			}
		}
		public bool accept_card(Card card) {
			if( i == NR) {
				return false;
			}
			range_end[i] = (int)card.numbers[0];
			type[i] = (INTType) card.numbers[1];
			i++;
			if( i == NR) {
				return true;
			}
			range_end[i] = (int)card.numbers[2];
			type[i] = (INTType) card.numbers[3];
			i++;
			if( i == NR) {
				return true;
			}
			range_end[i] = (int)card.numbers[4];
			type[i] = (INTType) card.numbers[5];
			return true;
		}
		/**
		 * find the range where value x fits in an array.
		 *
		 * @param xs
		 *        the array to look for the position of x, sorted.
		 * @return the first index where xs[index] < x and xs[index + 1} > x;
		 *        -1 if not found
		 */
		private int find(double x, double[] xs) {
			int xi;
			for(xi = 1; xi < xs.length; xi++) {
				if(x >= xs[xi-1] && x < xs[xi]) {
					return xi - 1;
				}
			}
			/* xi == max(length, 1) */
			if(x == xs[xi - 1]) {
				return xi - 1;
			}
			return -1;
		}
		/**
		 * find the range where the index x sits in
		 *
		 * @return -1 if not found
		 */
		private int find_range(int x) {
			int xi = 0;
			if(xi < range_end[0]) return 0;
			for(xi = 1; xi < range_end.length; xi++) {
				if(x >= range_end[xi-1] && x < range_end[xi]) {
					return xi - 1;
				}
			}
			return -1;
		}
		public INTType get_int_type_by_index(int index) {
			int ri = find_range(index);
			assert(ri >= 0 && ri < NR);
			INTType type = type[ri];
			return type;
		}
		/**
		 * Evaluate the interpolation of y.
		 *
		 * It searches the xs to find the interpolation type then call eval_static.
		 *
		 * @param x the expected x value
		 * @param xs  the array of x values
		 * @param ys the array of y values
		 */
		public double eval(double x, double[] xs, double[] ys) throws Error {
			int xi = find(x, xs);
			if(xi == -1) throw new Error.OVERFLOWN(
				"value %lf not in the range(%lf %lf)"
				.printf(x, xs[0], xs[xs.length - 1])
				);
			return eval_by_index(x, xi, xs, ys);
		}
		public double eval_by_index(double x, int xi, double[] xs, double [] ys) {
			if(xi < xs.length - 1) {
				return eval_static(get_int_type_by_index(xi), 
					x, xs[xi], xs[xi + 1], 
					ys[xi], ys[xi + 1]);
			} else {
				/*xi == xs.length - 1*/
				return ys[xs.length - 1];
			}
		}
		private static double eval_linlin(
			double x, double x0, double x1, double y0, double y1) {
			return (y0 - y1) / (x0 - x1) * (x - x0) + y0;
		}
		/**
		 * Evaluate an interpolation of y making use of the neighbour points.
		 *
		 * */
		public static double eval_static(INTType type,
			double x,
			double x0, double x1, double y0, double y1) {
			assert(x >= x0 && x <= x1);
			/*only linear is done */
			if(y0 == y1) return y0;
			assert(x0 != x1);
			switch(type) {
				case INTType.HISTOGRAM:
					return y0;
				case INTType.LINEAR_LOG:
					return eval_linlin(
						Math.log(x), Math.log(x0), Math.log(x1),
						y0, y1);
				case INTType.LOG_LINEAR:
					return Math.exp(
					eval_linlin(x, x0, x1, Math.log(y0), Math.log(y1)));
				case INTType.LOG_LOG:
					return Math.exp(
					eval_linlin(
						Math.log(x), Math.log(x0), Math.log(x1),
						Math.log(y0), Math.log(y1)));
				case INTType.GAMOW:
					double T = 0;
					double B = Math.log(y1 /y0 * x1 /x0)
							/  (1.0/Math.sqrt(x0 - T) 
							- 1.0/Math.sqrt(x1 - T));
					double A = Math.exp(B/(Math.sqrt(x0 - T))) * y1 * x1;
					return A / B * Math.exp(- B/Math.sqrt(x - T));
				default:
				case INTType.LINEAR_LINEAR:
					return eval_linlin(x, x0, x1, y0, y1);
			}
		}
	}
}
