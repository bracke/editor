with Editor.Ada_Declaration_Parser.Parse_Line_Contexts;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase is

   use Editor.Ada_Language_Model;

   generic
      with procedure Parse_Line
        (Analysis    : in out Analysis_Result;
         Raw_Line    : String;
         Line_Number : Positive;
         Context     : in out Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Context);
   procedure Parse_Compact_Scope_Tail
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Owner       : Symbol_Id;
      Context     : in out Editor.Ada_Declaration_Parser.Parse_Line_Contexts.Context);

end Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase;
