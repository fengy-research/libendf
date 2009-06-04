
namespace Endf {
	/**
	 * MF labels an ENDF file. 
	 * "Files" are usually used to store different types of data.
	 */
	public enum MFType {
		FILE_END = 0,
		/*
		 * MF=1 contains descriptive and miscellaneous data
		 * */
		DESC_AND_MISC = 1,
		/*
		 * MF=2 contains resonance parameter data
		 * */
		RESONANCE_PARA = 2,
		/*
		 * MF=3 contains reaction cross sections vs energy,
		 * */
		REACTION_CS_ENERGY = 3,
		/*
		 * MF=4 contains angular distributions, 
		 */
		ANGULAR_DIST = 4,
		/*
		 * MF=5 contains energy distributions
		 * */
		ENERGY_DIST = 5,
		/*
		 * MF=6 contains energy-angle distributions
		 * */
		ENERGY_ANGLE_DIST = 6,
		/*
		 * MF=7 contains thermal scattering data, 
		 * */
		THERMAL_SCATTERING = 7,
		/*
		 * MF=8 contains radioactivity data 
		 * */
		RADIOACTIVITY = 8,
		/*
		 * MF=9-10 contain nuclide production data, 
		 * */
		NUCLIDE_PROD_9 = 9,
		NUCLIDE_PROD_10 = 10,
		UNKNOWN_11 = 11,
		/*
		 * MF=12-15 contain photon production data
		 * */
		PHOTON_PROD_12 = 12,
		PHOTON_PROD_13 = 13,
		PHOTON_PROD_14 = 14,
		PHOTON_PROD_15 = 15,
		/*
		 * MF=30-36 contain covariance data
		 * */
		COVARIANCE_30 = 30,
		COVARIANCE_31 = 31,
		COVARIANCE_32 = 32,
		COVARIANCE_33 = 33,
		COVARIANCE_34 = 34,
		COVARIANCE_35 = 35,
		COVARIANCE_36 = 36
	}
	
}
