using UCNTracker;
/* DEPRECATED */
namespace Endf {
	public enum LTHRType {
		COHERENT = 1,
		INCOHERENT = 2,
	}
	/**
	 * An object for a Section in the ENDF file.
	 *
	 * The most useful interfaces are `load' and
	 * `S'.
	 *
	 * `load' is to load the event.content into this section 
	 * object.
	 *
	 * S(E, T) returns an interpolated S 
	 * corresponding to the reaction.
	 */
	public class ThermalElastic {
		public struct HEAD {
			public double ZA;
			public double AWR;
			public LTHRType LTHR;
		}
		private struct Page {
			public double [] S;
			public double [] s;
			public INTType LI;
		}
		double [] T;

		/**
		 * The current range where T fits in
		 * T is in T[T_range_index] T[T_range_index + 1].
		 * if T_range_index = -1, T is out of range.
		 **/
		int T_range_index = -1;

		double prepared_T;
		double prepared_E;

		Page [] pages;
		double [] E;

		/** 
		 * internall used as the prepared probability at
		 * each E.
		 * */
		private double [] s;

		private Gsl.RanDiscrete rd;

		Interpolation INT;
		public MTType MT;
		public MFType MF;
		public MATType MAT;

		public double ZA; /* first number in the first row */
		double AWR; /* second number in the first row */
		public int NP; /* number of data points*/
		int NR; /* number of interpolation ranges */

		public LTHRType LTHR;
		/* * For LTHR = COHERENT */
		public int LT; /* Temperature points (number of pages) - 1*/
		/* * For LTHR = INCOHERENT */
		public double SB; /* Characteristic bound cross section (barns) */

		/** 
		 * Debye-Waller integral divided by the atomic mass eV-1,
		 * as a function of T(K)
		 **/
		public double[] W;

		/**
		 * Prepare the cross section, heat it to temparture T
		 *
		 * @return false if T is out of range;
		 **/
		public bool prepare_T(double T) {
			T_range_index = find_T(T);
			prepared_T = T;
			if(T_range_index == -1) return false;
		}

		public bool prepare_E(double E) {
			prepared_E = E;
			if(LTHR == LTHRType.INCOHERENT) {
				rd = null;
				return true;
			}
			if(T_range_index == -1) {
				rd = null;
				return false;
			}
			for(int i = 0; i < (this.NP - 1); i++ ){

				if(this.E[i] < E) {
					double s0 = pages[T_range_index].s[i];
					double s1 = pages[T_range_index + 1].s[i];
					double LI = pages[T_range_index + 1].LI;
					s[i] = Interpolation.eval_static(
						LI, T, this.T[iT], this.T[iT +1], s0, s1);
				} else {
					s[i] = 0.0;
				}
				rd = new Gsl.RanDiscrete(s);
			}
			
			return true;
		}

		private int find_T(double T) {
			for(int i = 1; i < this.T.length; i++) {
				if(this.T[i] > T && this.T[i - 1] <= T)
					return i - 1;
			}
			return -1;
		}

		/** 
		 * The total cross section for given E.
		 *
		 * Notice that the Temperature is applied in @link prepare_T
		 * 
		 * # For a coherent section, Refer to ENDF-102 Dataformats 7.2.2
		 * # For a incoherent section, Refer to ENDF-102 Dataformat 7.3.2
		 *
		 * @return the total cross section at given E.
		 *
		 * */
		public double S(double E) {
			switch(LTHR) {
				case LTHRType.COHERENT:
					/* if out of range or not prepared, return a NAN */
					if(T_range_index == -1) return double.NAN;
					/* First do the E interpolation */
					double S0 = INT.eval(E, this.E, pages[T_range_index].S);
					double S1 = INT.eval(E, this.E, pages[T_range_index + 1].S);
					INTType LI = pages[T_range_index + 1].LI;
					/* Then do the temperature intepolation */
					double S_E_T =
						Interpolation.eval_static(
						LI, T, this.T[iT], this.T[iT +1], S0, S1);
					return S_E_T / E;
				case LTHRType.INCOHERENT:
					/* interpolate by T */
					double W_T = INT.eval(T, this.T, W);
					double EW = E * W_T;
					return SB * 0.5 * ( 1 - Math.exp(-4.0 * EW)) / (2.0 * EW);
			}
			return double.NAN;
		}

		/**
		 * After prepare is called return a mu according to the 
		 * angular distributation.
		 * 
		 * By definiation mu is the cos of the scattering angle.
		 *
		 * If LTHR == INCOHERENT, return a uniform mu,
		 * Refer to
		 * mathworld.wolfram.com/SpherePointPicking.html
		 *
		 * If LTHR == COHERENT, returns the angle by 1 - 2Ei/E,
		 * where Ei is the energy of a randomly choosen bragg edge,
		 * weighted by the cross section.
		 *
		 * @return a distributed mu.
		 * */
		public double next_mu(Gsl.RNG rng) {
			if(LTHR == LTHRType.INCOHERENT) {
				return 2.0 * rng.uniform() - 1.0;
			} else {
				size_t ch = rd.discrete(rng);
				return 1.0 - 2.0 * E[ch] / prepared_E;
			}
		}


//		public void load(SectionEvent event) {
//			assert(event.MF == MFType.THERMAL_SCATTERING);
//			assert(event.MT == MTType.ELASTIC);
//			MT = event.MT;
//			MAT = event.MAT;
//			MF = event.MF;
//			weak string p = event.content;
//			/* first line */
//			ZA = read_number(p, out p);
//			AWR = read_number(p, out p);
//			LTHR = (LTHRType) read_number(p, out p);
//			skip_to_next_line(p, out p);
//j
//j			switch(LTHR) {
//j				case LTHRType.COHERENT:
//jj					load_coherent(p, out p);
//jj				break;
//jj				case LTHRType.INCOHERENT:
//jjj					load_incoherent(p, out p);
//				break;
//			}	
//		}
		private void load_coherent(string p, out weak string outptr) {
			load_first_page(p, out p);
			
			for(int i = 1; i < LT + 1; i++) {
				load_other_page(i, p, out p);
			}
			outptr = p;
		}
		private void load_incoherent(string p, out weak string outptr) {
			SB = read_number(p, out p);
			assert(0.0 == read_number(p, out p));
			assert(0.0 == read_number(p, out p));
			assert(0.0 == read_number(p, out p));

			NR = (int) read_number(p, out p);
			NP = (int) read_number(p, out p);

			INT = new Interpolation(NR);
			INT.load(p, out p);


			W = new double[NP];
			T = new double[NP];

			for(int i = 0; i < NP; i++) {
				T[i] = read_number(p, out p);
				W[i] = read_number(p, out p);
			}

			skip_to_next_line(p, out p);

			outptr = p;
		}

		private void load_first_page(string p, out weak string outptr) {
			/* second line */
			double T0 = read_number(p, out p);
			//assert (0.0 == read_number(p, out p));
			assert (0.0 == read_number(p, out p));
			LT = (int) read_number(p, out p);
			assert (0.0 ==read_number(p, out p));
			NR = (int) read_number(p, out p);
			NP = (int) read_number(p, out p);

			pages = new Page[LT + 1];
			T = new double[LT+1];
			T[0] = T0;
			pages[0].S = new double[NP];
			pages[0].s = new double[NP];

			INT = new Interpolation(NR);
			s = new double[NP - 1];

			INT.load(p, out p);

			E = new double[NP];
			double prevS = 0.0;
			for(int i = 0; i < NP; i ++) {
				E[i] = read_number(p, out p);
				double S = read_number(p, out p);
				pages[0].S[i] = S;
				if(i > 0)
					pages[0].s[i - 1] = S - prevS;
				prevS = S;
			}
			skip_to_next_line(p, out p);
			outptr = p;
		}
		private void load_other_page(int page_number, 
			string p, out weak string outptr) {
			double T1 = read_number(p, out p);
			assert(0.0 == read_number(p, out p));
			INTType LI =  (INTType) read_number(p, out p);
			assert(0.0 == read_number(p, out p));
			int NP = (int) read_number(p, out p);
			skip_to_next_line(p, out p);

			pages[page_number].S = new double[NP];
			pages[page_number].s = new double[NP];

			T[page_number] = T1;
			pages[page_number].LI = LI;
			assert(NP == this.NP);
			double prevS = 0.0;
			for(int i = 0; i< NP; i ++) {
				double S = read_number(p, out p);
				pages[page_number].S[i] = S;
				if(i > 0)
					pages[page_number].s[i - 1] = S - prevS;
				prevS = S;
			}
			skip_to_next_line(p, out p);
			outptr = p;
		}
	}
}
