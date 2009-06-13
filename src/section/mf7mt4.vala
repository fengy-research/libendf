namespace Endf {
	/**
	 * File 7 Section 4 is the Inelastic Incoherent thermal
	 * scattering data.
	 *
	 * */
	public class MF7MT4 : Section {
		/**
		 * The real temperature is used to compute alpha and beta.
		 * */
		public const int LAT_ACTURAL = 0;
		/**
		 * The fake temperature kT0 = 0.0253eV is used to compute alpha and beta.
		 * */
		public const int LAT_FAKE = 1;
		private const double kT0 = 0.0253;
		/**
		 * S is symmetric by beta = 0
		 * */
		public const int LASYM_SYMMETRIC = 0;
		/**
		 * S is asymmetric by beta = 0
		 * */
		public const int LASYM_ASYMMETRIC = 1;
		/**
		 * The true value of S is stored.
		 * */
		public const int LLN_DIRECT = 0;
		/**
		 * log S is stored in the file.
		 */
		public const int LLN_LOG = 1;


		public struct HEAD {
			public double ZA;
			public double AWR;
			public int LAT;
			public int LASYM;
		}
		public HEAD head;

		public struct DATA {
			public int LLN;

			public int NI;
			public int NS;
			public int Nb;

			public double[] B;
			public double[] b;
			public double[] a;

			public int LT;
			public double[] T;
			public INTType[] LI;
		}

		public Interpolation bINT;
		public Interpolation aINT;
		public DATA data;
		public override double T{get; set;}
		public override double E{get; set;}

		bPage[] bpages;
		EffPage[] Effpages;

		public struct bPage {
			public TPage[] Tpages;
		}
		public struct TPage {
			public double[] S;
		}
		public struct EffPage {
			public double[] Tint;
			public double[] Teff;
			public Interpolation INT;
		}

		public override void accept(Parser parser) throws Error {
			accept_head(parser.card);
			if(!parser.fetch_card()) {
				throw new Error.MALFORMED(
				"unexpected stream end parsing a MF7MT4 section, after the head"
				);
			}
			data.LLN = (int) parser.card.numbers[2];
			data.NI = (int) parser.card.numbers[4];
			data.NS = (int) parser.card.numbers[5];
			Effpages = new EffPage[data.NS];

			list.accept(parser);
			data.B = (owned) list.Y;

			int NR = (int) parser.card.numbers[4];
			bINT = new Interpolation(NR);
			data.Nb = (int) parser.card.numbers[5];
			if(!parser.fetch_card()) {
				throw new Error.MALFORMED(
				"unexpected stream end parsing a MF7MT4 section, after the beta interpolation data"
				);
			}
			bINT.accept(parser);

			bpages = new bPage[data.Nb];
			data.b = new double[data.Nb];

			for(int i = 0; i < data.Nb; i++) {
				if(i == 0) {
					data.LT = (int) parser.card.numbers[2];
					data.T = new double[data.LT + 1];
					data.T[0] = parser.card.numbers[0];
					data.LI = new INTType[data.LT + 1];
				} else {
					/* where or not each beta page has the same
					 * temperature grid is not documented.
					 * We assume they are the same. Because the
					 * document forbids a temperature interpolation
					 * of S, the only choice would be interpolation
					 * by beta on the same T grid, calculate the cross
					 * section, then interpolate cross section by T.
					 */
					assert(data.LT == parser.card.numbers[2]);
				}
				bpages[i].Tpages = new TPage[data.LT + 1];
				data.b[i] = parser.card.numbers[1];
				tab.accept(parser);
				bpages[i].Tpages[0].S = (owned) tab.Y;
				/* SPEC says:
				 * Alpha grid should be the same for each beta value
				 * of and for each temperature.*/
				if(i == 0) {
					/* Therefore we save the first grid to the global
					 * grid data
					 */
					data.a = (owned)tab.X;
					aINT = tab.INT;
				} else {
					/*
					 * And happily panic if the new grid doesn't match
					 * with the old one.
					 */
					assert(tab.X.length == data.a.length);
					for(int l = 0; l < data.a.length; l++) {
						assert(data.a[l] == tab.X[l]);
					}
				}
				for(int j = 0; j< data.LT; j++) {
					data.T[j + 1] = parser.card.numbers[0];
					data.LI[j + 1] = (INTType) parser.card.numbers[2];
					list.accept(parser);
					bpages[i].Tpages[j + 1].S = (owned) list.Y;
				}
			}
			Effpages = new EffPage[data.NS + 1];
			for(int i = 0; i < data.NS + 1; i++) {
				tab.accept(parser);
				Effpages[i].Tint = (owned) tab.X;
				Effpages[i].Teff = (owned) tab.Y;
				Effpages[i].INT = (owned) tab.INT;
			}
		}
		private void accept_head(Card card) {
			head.ZA = card.numbers[0];
			head.AWR = card.numbers[1];
			head.LAT = (int) card.numbers[3];
			head.LASYM = (int) card.numbers[4];
		}
		private LIST list = new LIST();
		private TAB tab = new TAB();

		public override double S() {
			return 0.0;
		}
		private double Teff(double T, int n) {
			return Effpages[n].INT.eval(T, Effpages[n].Tint, Effpages[n].Teff);
		}

		private const double k = 8.617343e-5; /*EV * K^-1*/
		private double MSb(int n) {
			double MSf;
			double A;
			if(n == 0) {
				/* the principle scattering kernel is stored
				 * as a differnt format. Shit.*/
				MSf = data.B[0];
				A = data.B[2];
			} else {
				MSf = data.B[n * 6 + 1];
				A = data.B[n * 6 + 2];
			}
			double r = (A + 1.0) / A;
			return r * r * MSf;
		}
		private double a(double Eout, double mu) {
			double A0 = data.B[2];
			double rt = (Eout + E - 2.0 * mu * Math.sqrt(E * Eout)) ;
			switch(head.LAT) {
				case LAT_ACTURAL:
					return rt / ( k * T * A0);
				case LAT_FAKE:
					return rt / (kT0 * A0);
			}
			assert_not_reached();
		}
		private double b(double Eout) {
			double A0 = data.B[2];
			double rt = (Eout - E);
			switch(head.LAT) {
				case LAT_ACTURAL:
					return rt / ( k * T);
				case LAT_FAKE:
					return rt / (kT0);
			}
			assert_not_reached();
		}
		public double dS(double Eout, double mu) throws Error {
			double a = this.a(Eout, mu);
			double b = this.b(Eout);
			bool use_sct = false;

			int ai = 0;
			int bi = 0;
			try {
				ai = search_double(a, data.a);
				bi = search_double(head.LASYM == LASYM_SYMMETRIC?Math.fabs(b):b, data.b);
			} catch(Error.OVERFLOWN e) {
				use_sct = true;
				warning("using sct");
			}

			if(use_sct) {
				double rt = 0.0;
				/* ignore the real data, use Sct for testing */
				double pr_cs = MSb(0) * Math.exp( - b * 0.5 + lnSct(a, b, T, 0));
				double non_pr_cs = 0.0;
				for(int n = 1; n < data.NS; n++) {
					int non_pr_type = (int)data.B[n * 6];
					assert(non_pr_type == 0); /* Only SCT is implemented */
					non_pr_cs += MSb(n) * Math.exp( -b * 0.5 + lnSct(a, b, T, n));
				}
				rt = pr_cs + non_pr_cs;
				rt *= Math.sqrt(Eout / E) / (4.0 * Math.PI * k * T);
				return rt;
			} else {
				int Ti = search_double(T, data.T);
				double rt;
				double pr_cs_Tl = MSb(0) * Math.exp( - b * 0.5 + lnS(a, b, ai, bi, Ti));
				double pr_cs_Th = MSb(0) * Math.exp( - b * 0.5 + lnS(a, b, ai, bi, Ti + 1));
				double Th = data.T[Ti + 1];
				double Tl = data.T[Ti];
				double non_pr_cs_Th = 0.0;
				double non_pr_cs_Tl = 0.0;
				for(int n = 1; n < data.NS; n++) {
					int non_pr_type = (int)data.B[n * 6];
					assert(non_pr_type == 0); /* Only SCT is implemented */
					non_pr_cs_Tl += MSb(n) * Math.exp( -b * 0.5 + lnSct(a, b, Tl, n));
					non_pr_cs_Th += MSb(n) * Math.exp( -b * 0.5 + lnSct(a, b, Th, n));
				}
				double rt_Th = pr_cs_Th + non_pr_cs_Th;
				double rt_Tl = pr_cs_Tl + non_pr_cs_Tl;
				rt_Th *= Math.sqrt(Eout / E) / (4.0 * Math.PI * k * Th);
				rt_Tl *= Math.sqrt(Eout / E) / (4.0 * Math.PI * k * Tl);

				rt = Interpolation.eval_static(
					data.LI[Ti + 1],
					T,
					Tl, Th,
					rt_Tl,
					rt_Th);
				return rt;
			}
		}

		private double lnS(double a, double b, int ai, int bi, int Ti) {
			double S_bl = aINT.eval_by_index(a, ai, data.a, bpages[bi].Tpages[Ti].S);
			double S_bh = aINT.eval_by_index(a, ai, data.a, bpages[bi + 1].Tpages[Ti].S);
			double S = Interpolation.eval_static(bINT.get_int_type_by_index(bi), 
					   b, data.b[bi], data.b[bi+1], S_bl, S_bh);
			switch(data.LLN) {
				case LLN_DIRECT:
					if(S >= 0.0)
					return Math.log(S);
					else {
					warning("s = %lf assuming 0", S);
					return -999.99; /*As suggested in the spec*/
					}
				case LLN_LOG:
					return S;
			}
			return S;
		}
		private double lnSct(double a, double b, double T, int n) {
			double sigma = 4.0 * Math.fabs(a) * Teff(T, n) / T;
			double r = Math.fabs(a) - b;
			r = r * r / sigma  + Math.fabs(b) / 2.0;
			double d = Math.PI * sigma;
			return - r - 0.5 * Math.log(d);
		}
		/**
		 * Format the section to a string
		 * */
		public override string to_string(StringBuilder? sb = null) {
			StringBuilder _sb;
			if(sb == null) {
				_sb = new StringBuilder("");
				sb = _sb;
			}
			sb.append_printf("ZA = %e AWR=%e LAT=%d LASYM=%d\n",
				head.ZA, head.AWR, head.LAT, head.LASYM);

			array_to_string(sb, data.B, "scatters");
			array_to_string(sb, data.T, "T grid");
			array_to_string(sb, data.b, "beta grid");
			array_to_string(sb, data.a, "alpha grid");

			return sb.str;
		}
	}
}
