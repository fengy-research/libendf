
namespace Endf {
	/**
	 * Parse an ENDF TAB element
	 *
	 * After the input has been accepted fromthe parser, X, Y, and INT contains the
	 * parsed data list and interpolation data for this TAB.
	 *
	 * The caller shall then take away the ownership of X, Y, and INT.
	 *
	 */
	public class TABBuilder : Acceptor {
		/* Public access deprecated */
		private int NR;
		/* Public access deprecated */
		private int NP;
		/**
		 * The interpolation object. Take away when made.
		 * */
		public Interpolation INT;
		/**
		 * The tabulated data for X. Take away when made.
		 * */
		public double[] X;
		/**
		 * The tabulated data for Y. Take away when made.
		 * */
		public double[] Y;

		private int i;

		public void accept(Parser parser) throws Error {
			accept_head(parser.card);
			return_if_fail(parser.fetch_card());
			INT.accept(parser);
			while(accept_card(parser.card)) {
				if(parser.fetch_card()) continue;
				throw new 
				Error.MALFORMED("unexpected stream end when parsing a TAB");
			}
		}

		private void accept_head(Card card) {
			NR = (int)card.numbers[4];
			NP = (int)card.numbers[5];
			X = new double[NP];
			Y = new double[NP];
			INT = new Interpolation(NR);
			i = 0;
		}
		private bool accept_card(Card card) {
			if(i == NP) return false;
			X[i] = card.numbers[0];
			Y[i] = card.numbers[1];
			i++;
			if(i == NP) {
				return true;
			}
			X[i] = card.numbers[2];
			Y[i] = card.numbers[3];
			i++;
			if(i == NP) {
				return true;
			}
			X[i] = card.numbers[4];
			Y[i] = card.numbers[5];
			i++;
			if(i == NP) {
				return true;
			}
			return true;
		}
	}

}
