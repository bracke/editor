with Editor.Syntax;
package body Editor.Syntax_Overlays is

   function Merge
     (Base    : Editor.Syntax.Token_Kind;
      Overlay : Overlay_Kind) return Editor.Syntax.Token_Kind is
   begin
      case Overlay is
         when No_Overlay =>
            return Base;
         when Diagnostic_Warning_Overlay =>
            return Editor.Syntax.Diagnostic_Warning;
         when Diagnostic_Error_Overlay =>
            return Editor.Syntax.Diagnostic_Error;
         when Search_Match_Overlay =>
            return Editor.Syntax.Search_Match;
         when Selection_Overlay =>
            return Editor.Syntax.Selection_Overlay;
      end case;
   end Merge;

   function Precedence (Kind : Editor.Syntax.Token_Kind) return Natural is
   begin
      case Kind is
         when Editor.Syntax.Selection_Overlay =>
            return 60;
         when Editor.Syntax.Search_Match =>
            return 50;
         when Editor.Syntax.Diagnostic_Error =>
            return 40;
         when Editor.Syntax.Diagnostic_Warning =>
            return 30;
         when Editor.Syntax.Type_Identifier
            | Editor.Syntax.Subprogram_Identifier
            | Editor.Syntax.Package_Identifier
            | Editor.Syntax.Parameter_Identifier
            | Editor.Syntax.Attribute
            | Editor.Syntax.Aspect_Name
            | Editor.Syntax.Pragma_Name
            | Editor.Syntax.Generic_Formal =>
            return 20;
         when others =>
            return 10;
      end case;
   end Precedence;

end Editor.Syntax_Overlays;
