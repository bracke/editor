with Editor.Syntax;

package Editor.Syntax_Overlays is

   type Overlay_Kind is
     (No_Overlay,
      Diagnostic_Warning_Overlay,
      Diagnostic_Error_Overlay,
      Search_Match_Overlay,
      Selection_Overlay);

   function Merge
     (Base    : Editor.Syntax.Token_Kind;
      Overlay : Overlay_Kind) return Editor.Syntax.Token_Kind;

   function Precedence (Kind : Editor.Syntax.Token_Kind) return Natural;

end Editor.Syntax_Overlays;
