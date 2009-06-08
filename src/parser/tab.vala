
namespace Endf {
	/**
	 * Parse an ENDF TAB element
	 *
	 * The storage has to be filled to X and Y before accept_card is invoked.
	 * The interpolation is built and accessible from INT.
	 */
	public class TAB : Acceptor {
		public int NR;
		public int NP;
		public Interpolation INT;
		public double[] X;
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
