namespace Endf {
	public class MF7MT2 : Section {
		public enum LTHRType {
			COHERENT = 1,
			INCOHERENT = 2,
		}
		public struct HEAD {
			public double ZA;
			public double AWR;
			public LTHRType LTHR;
		}
		public HEAD head;

		private struct TPage {
			public double[] S;
		}
		private struct COHDataType {
			public int NR;
			public int NP;
			public int LT;
			public double[] E;
			public TPage[] Tpages;
			public double[] T;
			public Interpolation INT;
		}
		private struct INCDataType {
			public double SB;
			public int NR;
			public int NP;
		}

		private COHDataType COH;
		private INCDataType INC;

		private TAB tab;
		private LIST list;
		private int state;
		private const int HEAD_DONE = 0;
		private const int TABHEAD_DONE = 1;
		private const int TABDATA_DONE = 2;
		private const int LISTHEAD_DONE = 3;
		private const int LISTDATA_DONE = 4;
		private int i;

		public override void accept_head(Card card) {
			head.ZA = card.numbers[0];
			head.AWR = card.numbers[1];
			head.LTHR = (LTHRType) card.numbers[2];
			state = HEAD_DONE;
		}
		public override bool accept_card(Card card) {
			switch(head.LTHR) {
				case LTHRType.COHERENT:
					if(state == LISTDATA_DONE
						&& i == COH.LT) {
						return true;
					}
					if(state == HEAD_DONE) {
						COH.LT = (int) card.numbers[2];
						COH.T = new double[COH.LT + 1];
						COH.T[0] = card.numbers[0];
						tab.accept_head(card);
						COH.E = new double[tab.NP];
						COH.Tpages = new TPage [COH.LT + 1];
						COH.Tpages[0].S = new double[tab.NP];
						tab.X = COH.E;
						tab.Y = COH.Tpages[0].S;
						state = TABHEAD_DONE;
						break;
					}
					if(state  == TABHEAD_DONE) {
						if(!tab.accept_card(card)) {
							COH.INT = tab.INT;
							i = 0;
							state = TABDATA_DONE;
							/*recover to test the next state */
						}
					}
					if(state == LISTHEAD_DONE) {
						if(!list.accept_card(card)) {
							state = LISTDATA_DONE;
							i++;
						}
						/* recover to test the next state*/
					}
					if(state == TABDATA_DONE ||
					  (state == LISTDATA_DONE
					  && i < COH.LT)
						) {
						list.accept_head(card);
						COH.Tpages[i + 1].S  = new double[list.NP];
						list.Y = COH.Tpages[i + 1].S;
						state = LISTHEAD_DONE;
						break;
					}
					/* after all list data are done we are full */
					assert_not_reached();
				break;
			}
			return false;
		}
	}
}
