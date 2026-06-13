with Editor.Outline;

package Editor.Outline.Fixtures is

   --  Populate the outline with deterministic synthetic rows for tests.
   --  Production code should use extractor-backed refresh paths; this package
   --  keeps synthetic row fabrication out of the public product API.
   function Populate_Synthetic_Outline
     (Outline : in out Editor.Outline.Outline_State)
      return Editor.Outline.Outline_Refresh_Result;

end Editor.Outline.Fixtures;
