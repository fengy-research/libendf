namespace Endf {
	public class Interpolation {
		INTType [] type;
		int[] range_end;
		int NR;
		public Interpolation(int NR) {
			this.NR = NR;
			type = new INTType[NR];
			range_end = new int[NR];
		}
		public void set_range(int id, int range_end, INTType type) {
			this.range_end[id] = range_end;
			this.type[id] = type;
		}
		public void load(string p, out weak string outptr) {
			for(int i = 0; i< NR; i++) {
				range_end[i] = (int) read_number(p, out p);
				type[i] = (INTType) read_number(p, out p);
			}
			skip_to_next_line(p, out p);
			outptr = p;
		}
		private int find(double x, double[] xs) {
			int xi;
			for(xi = 1; xi < xs.length; xi++) {
				if(x >= xs[xi-1] && x <= xs[xi]) {
					return xi - 1;
				}
			}
			return -1;
		}
		private int find_range(int x) {
			int xi = 0;
			if(xi < range_end[0]) return 0;
			for(xi = 1; xi < range_end.length; xi++) {
				if(x >= range_end[xi-1] && x < range_end[xi]) {
					return xi - 1;
				}
			}
			return -1;
		}
		public double eval(double x, double[] xs, double[] ys) {
			int xi = find(x, xs);
			if(xi == -1) return double.NAN;
			int ri = find_range(xi);
			assert(ri >= 0 && ri < NR);
			INTType type = type[ri];
			return eval_static(type, 
				x, xs[xi], xs[xi + 1], 
				ys[xi], ys[xi + 1]);
		}
		private static double eval_linlin(
			double x, double x0, double x1, double y0, double y1) {
			return (y0 - y1) / (x0 - x1) * (x - x0) + y0;
		}
		public static double eval_static(INTType type,
			double x,
			double x0, double x1, double y0, double y1) {
			/*only linear is done */
			assert(x0 != x1);
			switch(type) {
				case INTType.HISTOGRAM:
					return y0;
				case INTType.LINEAR_LOG:
					return eval_linlin(
						Math.log(x), Math.log(x0), Math.log(x1),
						y0, y1);
				case INTType.LOG_LINEAR:
					return Math.exp(
					eval_linlin(x, x0, x1, Math.log(y0), Math.log(y1)));
				case INTType.LOG_LOG:
					return Math.exp(
					eval_linlin(
						Math.log(x), Math.log(x0), Math.log(x1),
						Math.log(y0), Math.log(y1)));
				case INTType.GAMOW:
					double T = 0;
					double B = Math.log(y1 /y0 * x1 /x0)
							/  (1.0/Math.sqrt(x0 - T) 
							- 1.0/Math.sqrt(x1 - T));
					double A = Math.exp(B/(Math.sqrt(x0 - T))) * y1 * x1;
					return A / B * Math.exp(- B/Math.sqrt(x - T));
				default:
				case INTType.LINEAR_LINEAR:
					return eval_linlin(x, x0, x1, y0, y1);
			}
		}
	}
}
