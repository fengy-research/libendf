namespace Endf {
	public class MF7MT2 {
		private struct Page {
			public double [] S;
			public INTType LI;
			public double T;
		}
		double [] T;
		Page [] pages;
		double [] E;
		Interpolation INT;
		Interpolation T_INT;
		MTType MT;
		MFType MF;
		MATType MAT;

		double ZA; /* first number in the first row */
		double AWR; /* second number in the first row */

		int LTHR; /*type coherent or incoh. */
		int LT; /* Temperature points (number of pages) - 1*/
		int NR; /* number of interpolation ranges */
		int NP; /* number of data points*/

		public double S(double E, double T) {
			double[] Ss = new double[LT + 1];
			for(int i= 0; i < LT + 1; i++) {
				Ss[i] = INT.eval(E, this.E, pages[i].S);
			}
			return T_INT.eval(T, this.T, Ss);
		}
		public void load(SectionEvent event) {
			assert(event.MF == MFType.THERMAL_SCATTERING);
			assert(event.MT == MTType.ELASTIC);
			MT = event.MT;
			MAT = event.MAT;
			MF = event.MF;
			weak string p = event.content;
			/* first line */
			ZA = read_number(p, out p);
			AWR = read_number(p, out p);
			LTHR = (int) read_number(p, out p);
			skip_to_next_line(p, out p);
			
			load_first_page(p, out p);
			
			for(int i = 1; i < LT + 1; i++) {
				load_other_page(i, p, out p);
			}
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
			pages[0].T = T0;

			INT = new Interpolation(NR);
			T_INT = new Interpolation(LT);

			INT.load(p, out p);

			E = new double[NP];
			for(int i = 0; i < NP; i ++) {
				E[i] = read_number(p, out p);
				pages[0].S[i] = read_number(p, out p);
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
			T[page_number] = T1;
			T_INT.set_range(page_number - 1, page_number + 1, LI);
			assert(NP == this.NP);
			for(int i = 0; i< NP; i ++) {
				pages[page_number].S[i] = read_number(p, out p);
			}
			skip_to_next_line(p, out p);
			outptr = p;
		}
	}
}
