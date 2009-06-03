namespace Endf {
	public struct Card {
		[CCode (array_length = false)]
		public double[6] numbers;
		public weak string start;
		public weak string end;
		public Section.META meta;
	}

	public delegate void CardFunction (Card card);

}
