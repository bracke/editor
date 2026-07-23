with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker is

   use Editor.Ada_Language_Model;

   subtype Collected_Symbol_List is
     Editor.Ada_Declaration_Parser.Declaration_Collectors.Collected_Symbol_List;

   Max_Scope_Nesting : constant Natural := 128;
   type Scope_Stack_Type is array (0 .. Max_Scope_Nesting) of Symbol_Id;
   type Scope_Private_Stack_Type is array (0 .. Max_Scope_Nesting) of Boolean;

   type Parse_Line_Scope_Context is record
      Depth           : Natural := 0;
      Scope_Stack     : Scope_Stack_Type := (others => No_Symbol);
      In_Record       : Boolean := False;
      Private_Stack   : Scope_Private_Stack_Type := (others => False);
   end record;

   type Parse_Line_Declaration_Target_Context is record
      Pending_Generic : Boolean := False;
      Pending_Discriminants : Boolean := False;
      Pending_Discriminant_Owner : Symbol_Id := No_Symbol;
      Pending_Type_Header_Owner : Symbol_Id := No_Symbol;
      Pending_Record_After_Is_Owner : Symbol_Id := No_Symbol;
      Pending_Concurrent_Header_Owner : Symbol_Id := No_Symbol;
      Pending_Array_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Access_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Access_Subprogram_Profile_Owner : Symbol_Id := No_Symbol;
      Pending_Return_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Return_Access_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Subtype_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Derived_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Interface_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Declaration_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Generic_Formal_Package_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Generic_Formal_Subprogram_Target_Owner : Symbol_Id := No_Symbol;
      Pending_Object_Array_Target_Owners : Collected_Symbol_List := (others => No_Symbol);
      Pending_Object_Array_Target_Count  : Natural := 0;
      Pending_Object_Access_Target_Owners : Collected_Symbol_List := (others => No_Symbol);
      Pending_Object_Access_Target_Count  : Natural := 0;
      Pending_Object_Access_Subprogram_Profile_Owners : Collected_Symbol_List := (others => No_Symbol);
      Pending_Object_Access_Subprogram_Profile_Count  : Natural := 0;
      Pending_Generic_Formal_Object_Target_Owners : Collected_Symbol_List := (others => No_Symbol);
      Pending_Generic_Formal_Object_Target_Count  : Natural := 0;
   end record;

   type Parse_Line_Profile_Context is record
      Pending_Profile_Access_Target_Owners : Collected_Symbol_List := (others => No_Symbol);
      Pending_Profile_Access_Target_Count  : Natural := 0;
      Pending_Profile : Boolean := False;
      Pending_Profile_Owner : Symbol_Id := No_Symbol;
   end record;

   type Parse_Line_Executable_Binding_Context is record
      Pending_Enumeration : Boolean := False;
      Pending_Enumeration_Owner : Symbol_Id := No_Symbol;
      Pending_Body_Owner : Symbol_Id := No_Symbol;
   end record;

   type Parse_Line_Source_Recovery_Context is record
      Pending_Separate_Target     : String (1 .. 256) := (others => ' ');
      Pending_Separate_Target_Len : Natural := 0;
      Pending_Aspect_Owner        : Symbol_Id := No_Symbol;
   end record;

   type Parse_Line_Context is record
      Scope              : Parse_Line_Scope_Context;
      Declaration_Targets : Parse_Line_Declaration_Target_Context;
      Profile            : Parse_Line_Profile_Context;
      Executable_Binding : Parse_Line_Executable_Binding_Context;
      Source_Recovery    : Parse_Line_Source_Recovery_Context;
   end record;

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result;

   procedure Project_Syntax_Tree_Into_Model
     (Analysis    : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text : String);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker;
