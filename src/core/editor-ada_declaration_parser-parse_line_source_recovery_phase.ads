with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase is

   subtype Analysis_Result is Editor.Ada_Language_Model.Analysis_Result;
   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;
   subtype Source_Recovery_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Source_Recovery_Context;

   procedure Set_Pending_Separate_Target
     (Recovery : in out Source_Recovery_Context;
      Text     : String);

   function Has_Pending_Separate_Target
     (Recovery : Source_Recovery_Context) return Boolean;

   function Consume_Pending_Separate_Target
     (Recovery : in out Source_Recovery_Context) return String;

   procedure Set_Pending_Aspect_Owner
     (Recovery : in out Source_Recovery_Context;
      Owner    : Symbol_Id);

   function Handle_Pending_Aspect_Line
     (Analysis    : in out Analysis_Result;
      Recovery    : in out Source_Recovery_Context;
      Raw_Line    : String;
      Lower_Line  : String;
      Line_Number : Positive) return Boolean;

   procedure Add_Trailing_Bare_Aspect
     (Analysis    : in out Analysis_Result;
      Owner       : Symbol_Id;
      Raw_Line    : String;
      Line_Number : Positive);

end Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase;
