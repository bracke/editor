with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Freezing_Helpers is

   function Line_Before
     (Left  : Editor.Ada_Language_Model.Source_Range;
      Right : Editor.Ada_Language_Model.Source_Range) return Boolean;

   function Is_Freezable_Representation_Target
     (S : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Targeted_Body_Completion
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Generic_Formal_Freezing_Use
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Symbol_Freezing_Use
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Freezing_Message
     (Kind : Editor.Ada_Language_Model.Freezing_Point_Kind) return String;

end Editor.Ada_Declaration_Parser.Freezing_Helpers;
