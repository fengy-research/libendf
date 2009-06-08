namespace Endf {
	/**
	 * A Section corresponds to a section in the ENDF file.
	 *
	 * A Section has to implement accept_card and accept_head with
	 * a state-machine to populate its data.
	 *
	 * When generating random events, the Section is also a state machine.
	 * Set the E and T first, then use either the Inelastic interface
	 * or the elastic interface to obtain a random event.
	 */
	public abstract class Section {
		public struct META {
			public MATType MAT;
			public MFType MF;
			public MTType MT;
			public uint to_uint() {
				return (uint)MAT * 100000 + (uint) MF * 1000 + (uint) MT;
			}
			public static uint hash(META h) {
				return h.to_uint();
			}
			public static bool equal(META h1, META h2) {
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
		public abstract void accept(Parser parser);

		public abstract double T {get; set;}
		public abstract double E {get; set;}
		/**
		 * The total cross section at this E and T
		 **/
		public abstract double S() throws Error;
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
