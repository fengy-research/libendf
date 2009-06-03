
namespace Endf {
	/**
	 * Parse an endf LIST element.
	 *
	 * The storage has to be fed into Y before any call to accept_card is made.
	 *
	 * */
	public class LIST {
		public int NP;
		[CCode (array_length = false)]
		public weak double[] Y;
		private const int HEAD_DONE = 0;
		private int state;
		private int i;
		public void accept_head(Card card) {
			NP = (int) card.numbers[4];
			state = HEAD_DONE;
			i = 0;
		}
		public bool accept_card(Card card) {
			if(i >= NP) return false;
			if(state == HEAD_DONE) {
				for(int j = 0; j < 6; j++) {
					Y[i] = card.numbers[0];
					i++;
					if(i == NP) return true;
				}
			}
			return true;
		}
	}
}
