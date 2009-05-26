namespace Endf {
	public struct SectionEvent {
		public int start;
		public int end;
		public MATType MAT;
		public MFType MF;
		public MTType MT;
		public unowned string content;
		public void dump() {
		stdout.printf(
"""
  start: %d
  end: %d 
  MAT: %s 
  MF: %s 
  MT: %s
  content: |
%s
""",
		start, end, 
		Endf.enum_to_string(typeof(MATType), MAT),
		Endf.enum_to_string(typeof(MFType), MF),
		Endf.enum_to_string(typeof(MTType), MT),
		content);
		}
	}
	public delegate bool SectionEventFunction(SectionEvent event);

	public struct FileEvent {
		public int start;
		public int end;
		public MATType MAT;
		public MFType MF;
	}
	public delegate bool FileEventFunction(FileEvent event);

	public struct MaterialEvent {
		public int start;
		public int end;
		public MATType MAT;
	}
	public delegate bool MaterialEventFunction(MaterialEvent event);

	public struct TapeEvent {
		public int id;
		public int start;
		public int end;
	}
	public delegate bool TapeEventFunction(TapeEvent event);
}
