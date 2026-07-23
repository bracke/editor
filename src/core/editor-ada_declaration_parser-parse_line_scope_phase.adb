with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;

package body Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase is

   package Worker renames
     Editor.Ada_Declaration_Parser
       .Semantic_Phases_Engine_Layers_Projection_Worker;

   function Bounded_Depth (Scope : Scope_Context) return Natural is
   begin
      return Natural'Min (Scope.Depth, Worker.Max_Scope_Nesting);
   end Bounded_Depth;

   function Current_Parent (Scope : Scope_Context) return Symbol_Id is
   begin
      return Scope.Scope_Stack (Bounded_Depth (Scope));
   end Current_Parent;

   function Current_Private (Scope : Scope_Context) return Boolean is
   begin
      return Scope.Private_Stack (Bounded_Depth (Scope));
   end Current_Private;

   procedure Mark_Current_Private (Scope : in out Scope_Context) is
   begin
      Scope.Private_Stack (Bounded_Depth (Scope)) := True;
   end Mark_Current_Private;

   procedure Set_In_Record
     (Scope   : in out Scope_Context;
      Enabled : Boolean)
   is
   begin
      Scope.In_Record := Enabled;
   end Set_In_Record;

   procedure Enter_Scope
     (Scope : in out Scope_Context;
      Owner : Symbol_Id)
   is
   begin
      if Scope.Depth < Worker.Max_Scope_Nesting then
         Scope.Depth := Scope.Depth + 1;
         Scope.Scope_Stack (Scope.Depth) := Owner;
         Scope.Private_Stack (Scope.Depth) :=
           Scope.Private_Stack (Scope.Depth - 1);
      end if;
   end Enter_Scope;

   procedure Leave_Scope (Scope : in out Scope_Context) is
   begin
      if Scope.Depth > 0 then
         Scope.Private_Stack (Bounded_Depth (Scope)) := False;
         Scope.Scope_Stack (Bounded_Depth (Scope)) :=
           Editor.Ada_Language_Model.No_Symbol;
         Scope.Depth := Scope.Depth - 1;
      end if;
   end Leave_Scope;

   procedure Open_Record_Scope
     (Scope : in out Scope_Context;
      Owner : Symbol_Id)
   is
   begin
      Scope.In_Record := True;
      Enter_Scope (Scope, Owner);
   end Open_Record_Scope;

   procedure Close_Record_Scope (Scope : in out Scope_Context) is
   begin
      if Scope.In_Record then
         Leave_Scope (Scope);
         Scope.In_Record := False;
      end if;
   end Close_Record_Scope;

end Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
