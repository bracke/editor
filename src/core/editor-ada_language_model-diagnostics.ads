with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Diagnostics is

   procedure Add_Legality_Diagnostic
     (Analysis       : in out Analysis_Result;
      Kind           : Legality_Diagnostic_Kind;
      Message        : String;
      Severity       : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Source_Span          : Source_Range := (others => 1));

   function Legality_Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural;

   function Legality_Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Legality_Diagnostic_Info;

   function Has_Legality_Diagnostics
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Boolean;

   function Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural;

   function Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Diagnostic_Info;


end Editor.Ada_Language_Model.Diagnostics;
