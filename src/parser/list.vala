
namespace Endf {
	/**
	 * Parse an endf LIST element.
	 *
	 * After the input has been accepted from the parser, Y will be the accepted list
	 * of double numbers.
	 *
	 * The caller of this builder shall then take away the ownership of Y;
	 * */
	public class LISTBuilder : Acceptor {
		/* Deprecated. Used by the internal */
		private int NP;
		/* The array accepting the list values */
		public double[] Y;
		
		private int i;

		public void accept(Parser parser) throws Error {
			accept_head(parser.card);
			while(parser.fetch_card()) {
				if(!accept_card(parser.card)) {
					return;
				}
			}
			throw new
			Error.MALFORMED("unexpected stream end when parsing a LIST");
		}
		private void accept_head(Card card) {
			NP = (int) card.numbers[4];
			Y = new double[NP];
			i = 0;
		}

		/**
		 * @return whether the card is rejected.
		 */
		private bool accept_card(Card card) {
			if(i >= NP) return false;
			for(int j = 0; j < 6; j++) {
				Y[i] = card.numbers[j];
				i++;
				if(i == NP) return true;
			}
			return true;
		}
	}
}
