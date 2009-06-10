namespace Endf {
	/**
	 * File 7 Section 2 is the Elastic Coh/Incoh-erent thermal
	 * scattering data.
	 *
	 * */
	public class MF7MT2 : Section, Elastic {
		private const int COHERENT = 1;
		private const int INCOHERENT = 2;

		/** 
		 * The head element 
		 * */
		public struct HEAD {
			/** 
			 * Charge parameter, refer to the spec (FIXME)
			 * */
			public double ZA;
			/**
			 * mass parameter, refer to the spec (FIXME)
			 */
			public double AWR;
			/**
			 * COHERENT(1) or INCOHERENT(2)
			 */
			public int LTHR;
		}
		public HEAD head;

		/**
		 * Data are organized into pages by the temperature.
		 * */
		public struct TPage {
			/**
			 * S[i] is the summed differential cross section up to
			 * E[i]
			 * */
			public double[] S;
			/**
			 * the interpolation rule from last temperature tho this termparture.
			 * */
			public INTType LI;
		}
		/**
		 * Coherent scattering data.
		 * */
		public struct COHDataType {
			/**
			 * number of interpolation ranges with respect of E.
			 * */
			public int NR;
			/**
			 * nubmer of data points
			 * */
			public int NP;
			/**
			 * number of tempreatures (pages) - 1
			 */
			public int LT;
			/**
			 * energy grid
			 */
			public double[] E;
			/**
			 * pages are sliced in parallel of the temperature axis
			 * */
			public TPage[] Tpages;
			/**
			 * temperature grid
			 */
			public double[] T;
			/**
			 * the inerpolation object
			 * */
			public Interpolation INT;
		}
		/**
		 * Incoherent scattering  data
		 * */
		public struct INCDataType {
			/**
			 * the characteristic bound cross section in barns
			 * */
			public double SB;
			/**
			 * number of interpolation ranges
			 */
			public int NR;
			/**
			 * nubmer of data(grid) points.
			 */
			public int NP;
			/**
			 * Temperature grid
			 */
			public double[] T;
			/**
			 * Debyie-waller intergral divided by the atomic mass as function 
			 * of T
			 */
			public double[] W;
			/**
			 * The interpolation object
			 */
			public Interpolation INT;
		}

		public COHDataType COH;
		public INCDataType INC;

		/* Tab parser and list parser */
		private TAB tab = new TAB();
		private LIST list = new LIST();

		public override void accept(Parser parser) throws Error {
			accept_head(parser.card);
			assert(parser.fetch_card());
			switch(head.LTHR) {
				case COHERENT:
					accept_coh(parser);
				break;
				case INCOHERENT:
					accept_inc(parser);
				break;
			}
		}
		private void accept_coh(Parser parser) throws Error {
			COH.LT = (int)parser.card.numbers[2];
			COH.T = new double[COH.LT + 1];
			COH.T[0] = parser.card.numbers[0];
			COH.Tpages = new TPage [COH.LT + 1];
			tab.accept(parser);
			COH.NP = tab.NP;
			COH.NR = tab.NR;
			COH.E = (owned) tab.X;
			COH.Tpages[0].S = (owned) tab.Y;
			COH.INT = tab.INT;

			for(int i = 0; i < COH.LT; i++) {
				COH.T[i + 1] = parser.card.numbers[0];
				COH.Tpages[i + 1].LI  = (INTType) parser.card.numbers[2];
				list.accept(parser);
				COH.Tpages[i + 1].S  = (owned) list.Y;
			}
		}

		private void accept_inc(Parser parser) throws Error {
			INC.SB = parser.card.numbers[0];
			INC.NR = (int)parser.card.numbers[4];
			INC.NP = (int)parser.card.numbers[5];
			tab.accept(parser);
			INC.INT = tab.INT;
			INC.T = (owned) tab.X;
			INC.W = (owned) tab.Y;
		}

		private void accept_head(Card card) {
			head.ZA = card.numbers[0];
			head.AWR = card.numbers[1];
			head.LTHR = (int) card.numbers[2];
		}

		/* private members for the Elastic interface */
		private double _T;
		private double _E;
		/**
		 * _T is in page_range, page_range +1
		 */
		private int page_range;
		private bool page_range_dirty = true;
		private bool rdist_dirty = true;
		/**
		 * interpolated S at lower temperature
		 */
		private double S0;
		/**
		 * interpolated S at higher temperature
		 */
		private double S1;
		/**
		 * interpolated W integral 
		 * */
		private double W;
		/**
		 * all possible channels of the discrete angles.
		 */
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
				if(_T == value) return;
				_T = value;
				very_dirty();
			}
		}

		public override double E {
			get {
				return _E;
			}
			set {
				if(_E == value) return;
				_E = value;
				very_dirty();
			}
		}

		/**
		 * initialize the page_range
		 * */
		protected void prepare_page_range() throws Error {
			if(!page_range_dirty) return;
			switch(head.LTHR) {
				case COHERENT:
					page_range = search_double(T, COH.T);

					/* do the E interpolation */
					S0 = COH.INT.eval(E, COH.E, COH.Tpages[page_range].S);
					S1 = COH.INT.eval(E, COH.E, COH.Tpages[page_range + 1].S);
					page_range_dirty = false;
				break;
				case INCOHERENT:
					page_range = search_double(T, INC.T);
					/* do the W interpolation */
					W = INC.INT.eval(T, INC.T, INC.W);

					page_range_dirty = false;
				break;
			}
		}
		protected void prepare_rdist() throws Error {
			if(!rdist_dirty) return;
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
					if(s[i] < 0.0) {
						warning(" s = %lf < 0.0, s_low = %lf s_hight = %lf, page_range=%d ", s[i], s_low, s_high, page_range);
						s[i] = 0.0;
					}
				} else {
					s[i] = 0.0;
				}
			}
			rdist = new Gsl.RanDiscrete(s);
			rdist_dirty = false;
		}
		/**
		 * Caluclate the totoal cross section at the already set E and T.
		 *
		 * The formula is from the ENDF spec.
		 *
		 * @return the total cross section
		 * */
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
		/**
		 * produce a random scattering event.
		 *
		 * @param rng
		 *        a GSL random number generator
		 * @param mu
		 *        the cosine of the scattering angle
		 */
		public void random_event(Gsl.RNG rng, out double mu) throws Error {
			prepare_page_range();
			switch(head.LTHR) {
				case COHERENT:
					prepare_rdist();
					size_t ch = rdist.discrete(rng);
					mu = 1.0 - 2.0 * COH.E[ch] / E;
					assert((mu >= -1.0));
					assert((mu <= 1.0));
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
		public override string to_string(StringBuilder? sb = null) {
			StringBuilder _sb;
			if(sb == null) {
				_sb = new StringBuilder("");
				sb = _sb;
			}
			sb.append_printf("ZA=%e AWR=%e LTHR=%d\n",
				head.ZA, head.AWR, head.LTHR);

			switch(head.LTHR) {
				case COHERENT:
					array_to_string(sb, COH.T, "T grid");
					array_to_string(sb, COH.E, "E grid");
				break;
				case INCOHERENT:
					array_to_string(sb, INC.T, "T grid");
				break;
			}
			return sb.str;
		}
	}
}
