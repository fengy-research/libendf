namespace Endf {
	/**
	 * File 7 Section 4 is the Inelastic Incoherent thermal
	 * scattering data.
	 *
	 * */
	public class MF7MT4 : Section {
		public const int LAT_ACTURAL = 0;
		public const int LAT_0_0253_K = 1;
		public const int SYMMETRIC = 0;
		public const int ASYMMETRIC = 1;
		public const int DIRECT = 0;
		public const int LN_S = 0;


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
		}

		public Interpolation bINT;
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
			public INTType LI;
		}
		public struct EffPage {
			public double[] Tint;
			public double[] Teff;
			public Interpolation INT;
		}

		public override void accept(Parser parser) {
			accept_head(parser.card);
			return_if_fail(parser.fetch_card());
			data.LLN = (int) parser.card.numbers[2];
			data.NI = (int) parser.card.numbers[4];
			data.NS = (int) parser.card.numbers[5];
			Effpages = new EffPage[data.NS];

			list.accept(parser);
			data.B = (owned) list.Y;

			int NR = (int) parser.card.numbers[4];
			bINT = new Interpolation(NR);
			data.Nb = (int) parser.card.numbers[5];
			parser.fetch_card();
			bINT.accept(parser);

			bpages = new bPage[data.Nb];
			data.b = new double[data.Nb];

			for(int i = 0; i < data.Nb; i++) {
				if(i == 0) {
					data.LT = (int) parser.card.numbers[2];
					data.T = new double[data.LT + 1];
					data.T[0] = parser.card.numbers[0];
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
					bINT = tab.INT;
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
					bpages[i].Tpages[j + 1].LI = (INTType) parser.card.numbers[2];
					bpages[i].Tpages[j + 1].S = (owned) tab.Y;
					list.accept(parser);
				}
			}
			for(int i = 0; i < data.NS; i++) {
				tab.accept(parser);
				Effpages[i].Tint = (owned) tab.X;
				Effpages[i].Teff = (owned) tab.Y;
				Effpages[i].INT = tab.INT;
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
	}
}
