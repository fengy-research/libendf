namespace Endf {
	public class MF7MT2 : Section, Elastic {
		private const int COHERENT = 1;
		private const int INCOHERENT = 2;

		public struct HEAD {
			public double ZA;
			public double AWR;
			public int LTHR;
		}
		public HEAD head;

		private struct TPage {
			public double[] S;
			public INTType LI;
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
			public double[] T;
			public double[] W;
			public Interpolation INT;
		}

		private COHDataType COH;
		private INCDataType INC;

		private TAB tab = new TAB();
		private LIST list = new LIST();
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
			head.LTHR = (int) card.numbers[2];
			state = HEAD_DONE;
		}

		public override bool accept_card(Card card) {
			switch(head.LTHR) {
				case COHERENT:
				return accept_card_coh(card);
				case INCOHERENT:
				return accept_card_incoh(card);
			}
			return false;
		}

		public bool accept_card_incoh(Card card) {
			assert_not_reached();
		}

		public bool accept_card_coh(Card card) {
			if(state == LISTDATA_DONE
				&& i == COH.LT) {
				return false;
			}
			if(state == HEAD_DONE) {
				COH.LT = (int) card.numbers[2];
				COH.T = new double[COH.LT + 1];
				COH.T[0] = card.numbers[0];
				tab.accept_head(card);
				COH.E = new double[tab.NP];
				COH.NP = tab.NP;
				COH.NR = tab.NR;
				COH.Tpages = new TPage [COH.LT + 1];
				COH.Tpages[0].S = new double[tab.NP];
				tab.X = COH.E;
				tab.Y = COH.Tpages[0].S;
				state = TABHEAD_DONE;
				return true;
			}

			if(state  == TABHEAD_DONE) {
				if(!tab.accept_card(card)) {
					COH.INT = tab.INT;
					i = 0;
					state = TABDATA_DONE;
					/*recover to test the next state */
				} else {
					return true;
				}
			}
			if(state == LISTHEAD_DONE) {
				assert(list.Y != null);
				if(!list.accept_card(card)) {
					state = LISTDATA_DONE;
					i++;
				/* recover to test the next state*/
				} else {
					return true;
				}
			}
			if(state == TABDATA_DONE ||
			  (state == LISTDATA_DONE
			  && i < COH.LT)
				) {
				list.accept_head(card);
				assert(list.NP == COH.NP);
				COH.Tpages[i + 1].S  = new double[COH.NP];
				COH.Tpages[i + 1].LI  = (INTType) card.numbers[2];
				list.Y = COH.Tpages[i + 1].S;
				assert(list.Y != null);
				state = LISTHEAD_DONE;
				return true;
			}
			/* after all list data are done we are full */
			assert_not_reached();
		}
		private double _T;
		private double _E;
		/**
		 * _T is in page_range, page_range +1
		 */
		private int page_range;
		private bool page_range_dirty = true;
		private bool rdist_dirty = true;
		private double S0;
		private double S1;
		private double W;
		private double[] s;
		private Gsl.RanDiscrete rdist;

		private void very_dirty() {
				page_range_dirty = true;
				rdist_dirty = true;
		}

		public override double T {
			get {
				return _T;
			}
			set {
				_T = value;
				very_dirty();
			}
		}

		public override double E {
			get {
				return _E;
			}
			set {
				_E = value;
				very_dirty();
			}
		}
		protected void prepare_page_range() throws Error {
			if(page_range_dirty) {
				switch(head.LTHR) {
					case COHERENT:
						for(int i = 1; i < COH.T.length; i++) {
							if(COH.T[i] > T && COH.T[i - 1] <= T)
							page_range = i -1;
							break;
						}
						if(i == COH.T.length) throw new
							Error.OVERFLOWN("T(%lf) out of range [%lf, %lf]"
							.printf(T, COH.T[0], COH.T[COH.T.length -1]));
						/* do the E interpolation */
						S0 = COH.INT.eval(E, COH.E, COH.Tpages[page_range].S);
						S1 = COH.INT.eval(E, COH.E, COH.Tpages[page_range + 1].S);
						page_range_dirty = false;
					break;
					case INCOHERENT:
						for(int i = 1; i < INC.T.length; i++) {
							if(INC.T[i] > T && INC.T[i - 1] <= T)
							page_range = i -1;
							break;
						}
						if(i == this.INC.T.length) throw new
							Error.OVERFLOWN("T out of range");
						/* do the W interpolation */
						W = INC.INT.eval(T, INC.T, INC.W);

						page_range_dirty = false;
					break;
				}
			}
			
		}
		protected void prepare_rdist() throws Error {
			if(rdist_dirty) {
				if(s.length != COH.NP) {
					s = new double[COH.NP - 1];
				}
				for(int i = 0; i < (this.COH.NP - 1); i++) {
					if(this.COH.E[i] < E) {
						weak double[] S_Tlow = COH.Tpages[page_range].S;
						weak double[] S_Thigh = COH.Tpages[page_range + 1].S;
						double s_low = S_Tlow[i + 1] - S_Tlow[i];
						double s_high = S_Thigh[i + 1] - S_Thigh[i];
						INTType LI = COH.Tpages[page_range + 1].LI;
						s[i] = Interpolation.eval_static(
							LI, T, COH.T[page_range], COH.T[page_range + 1], s_low, s_high);
					} else {
						s[i] = 0.0;
					}
				}
				rdist = new Gsl.RanDiscrete(s);
				rdist_dirty = false;
			}
		}
		public override double S() throws Error {
			prepare_page_range();
			switch(head.LTHR) {
				case COHERENT:
				INTType LI = COH.Tpages[page_range + 1].LI;
				/* E interpolation (S0 , S1) are done in prepare_range */
				/* Then do the temperature intepolation */
				double S =
					Interpolation.eval_static(
					LI, T, COH.T[page_range], COH.T[page_range +1], S0, S1);
				return S/E;
				case INCOHERENT:
				return INC.SB * 0.5 * ( 1.0 - Math.exp( - 4.0 * E * W))/ (2.0 * E * W);
				default:
				throw new Error.OVERFLOWN("lthr (%d) is neither coherent or incoherent", head.LTHR);
			}
		}
		public void random_event(Gsl.RNG rng, out double mu) throws Error {
			prepare_page_range();
			switch(head.LTHR) {
				case COHERENT:
					prepare_rdist();
					size_t ch = rdist.discrete(rng);
					mu = 1.0 - 2.0 * COH.E[ch] / E;
				return;
				case INCOHERENT:
					double mu1;
					do {
						mu1 = Gsl.Randist.exponential(rng, 1.0/(-2.0 * E * W));
					}
					while(mu1 > 2.0);
					mu = 1.0 - mu1;
				return;
			}
		}
	}
}
