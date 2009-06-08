
namespace Endf {
	/**
	 * Parse an ENDF TAB element
	 *
	 * The storage has to be filled to X and Y before accept_card is invoked.
	 * The interpolation is built and accessible from INT.
	 */
	public class TAB {
		public int NR;
		public int NP;
		public Interpolation INT;
		public double[] X;
		public double[] Y;

		private int state;
		private const int HEAD_DONE = 0;
		private const int INT_DONE = 1;
		private const int DATA_DONE = 2;
		private int i;

		public void accept(Parser parser) {
			accept_head(parser.card);
			while(parser.fetch_card()) {
				if(!accept_card(parser.card)) {
					return;
				}
			}
			return;
		}
		private void accept_head(Card card) {
			NR = (int)card.numbers[4];
			NP = (int)card.numbers[5];
			X = new double[NP];
			Y = new double[NP];
			INT = new Interpolation(NR);
			state = HEAD_DONE;
		}
		private bool accept_card(Card card) {
			if(state == DATA_DONE) {
				return false;
			}
			if(state == HEAD_DONE) {
				if(!INT.accept_card(card)) {
					state = INT_DONE;
				/* recover to fill the data*/
					i = 0;
				} else {
					return true;
				}
			}
			if(state == INT_DONE) {
				X[i] = card.numbers[0];
				Y[i] = card.numbers[1];
				i++;
				if(i == NP) {
					state = DATA_DONE;
					return true;
				}
				X[i] = card.numbers[2];
				Y[i] = card.numbers[3];
				i++;
				if(i == NP) {
					state = DATA_DONE;
					return true;
				}
				X[i] = card.numbers[4];
				Y[i] = card.numbers[5];
				i++;
				if(i == NP) {
					state = DATA_DONE;
					return true;
				}
			}
			return true;
		}
	}

}
