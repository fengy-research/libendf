namespace Endf {
	/**
	 * A Section corresponds to a section in the ENDF file.
	 *
	 * A Section has to implement accept_card and accept_head with
	 * a state-machine to populate its data.
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
		public abstract void accept_head(Card card);
		/**
		 * accept a data card.
		 * @return true if it is full and the card is rejected.
		 *         false if the card is accepted.
		 */
		public abstract bool accept_card(Card card);
	}
}
