
namespace Endf {
	/**
	 * Parse an endf LIST element.
	 *
	 * The storage has to be fed into Y before any call to accept_card is made.
	 *
	 * */
	public class LIST : Acceptor {
		public int NP;
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
				Y[i] = card.numbers[0];
				i++;
				if(i == NP) return true;
			}
			return true;
		}
	}
}
