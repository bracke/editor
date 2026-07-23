with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase is

   subtype Symbol_Id is Editor.Ada_Language_Model.Symbol_Id;
   subtype Scope_Context is
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker
       .Parse_Line_Scope_Context;

   function Current_Parent (Scope : Scope_Context) return Symbol_Id;
   function Current_Private (Scope : Scope_Context) return Boolean;

   procedure Mark_Current_Private (Scope : in out Scope_Context);
   procedure Set_In_Record
     (Scope   : in out Scope_Context;
      Enabled : Boolean);
   procedure Enter_Scope
     (Scope : in out Scope_Context;
      Owner : Symbol_Id);
   procedure Leave_Scope (Scope : in out Scope_Context);
   procedure Open_Record_Scope
     (Scope : in out Scope_Context;
      Owner : Symbol_Id);
   procedure Close_Record_Scope (Scope : in out Scope_Context);

end Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
