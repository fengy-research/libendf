
namespace Endf {
	/**
	 * MT labels an ENDF section. 
	 * Sections are usually used to hold different reactions.
	 * */
	public enum MTType {
		SECTION_END = 0,
		TOTAL_CS = 1,
		ELASTIC = 2,
		REACTION_Z_N = 4,
		REACTION_Z_2N = 16,
		FISSION = 18,
		RADIATIVE_CAP = 102
	}

}
