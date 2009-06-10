namespace Endf {
	/**
	 * A Section corresponds to a section in the ENDF file.
	 *
	 * A section implements the Acceptor interface, which accept cards from 
	 * parser and builts its content.
	 *
	 * When generating random events, the Section is also a state machine.
	 * Set the E and T first, then use either the Inelastic interface
	 * or the elastic interface to obtain a random event.
	 */
	public abstract class Section : Acceptor {
		public struct META {
			public MATType MAT;
			public MFType MF;
			public MTType MT;
			public uint to_uint() {
				return (uint)MAT * 100000 + (uint) MF * 1000 + (uint) MT;
			}
			public static uint hash(ref META h) {
				return h.to_uint();
			}
			public static bool equal(ref META h1, ref META h2) {
				return h1.to_uint() == h2.to_uint();
			}
		}
		public META meta;

		/**
		 * Accept cards for this section from parser.
		 *
		 * When the function returns, parser.card should points to the
		 * next available(unused) card.
		 */
		public abstract void accept(Parser parser) throws Error;
		public abstract string to_string(StringBuilder? builder = null);

		public abstract double T {get; set;}
		public abstract double E {get; set;}
		/**
		 * The total cross section at this E and T
		 **/
		public abstract double S() throws Error;
		protected static void array_to_string(StringBuilder sb, double[] array, string name) {
			sb.append_printf("%s %d entries\n", name, array.length);
			int i;
			for(i = 0; i< array.length; i++) {
				sb.append_printf("%le ", array[i]);
				if((i + 1) % 6 == 0) sb.append_unichar('\n');
			}
			if(i % 6 != 0)
				sb.append_unichar('\n');
		}
	}

	protected static int search_double(double foo, double[] array) throws Error {
		int i;
		for(i = 1; i < array.length; i++) {
			if(array[i] > foo && array[i - 1] <= foo) {
				return i - 1;
			}
		}
		throw new
			Error.OVERFLOWN(
			"%le out of range %le %le".printf(
			foo, array[0], array[array.length - 1])
			);
	}
	/**
	 * Elastic scatter cross section
	 */
	public interface Elastic: Section {
		public abstract void random_event(Gsl.RNG rng, out double mu) throws Error;
	}
	/**
	 * Inelastic scatter cross section
	 */
	public interface Inelastic : Section {
		public abstract double random_event(Gsl.RNG rng, out double dE, out double mu) throws Error;
	}
}
