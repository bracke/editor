with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase is

   use Editor.Ada_Language_Model;

   procedure Clear_After_Scope_Close (Context : in out Parse_Line_Context) is
   begin
      Context.Declaration_Targets.Pending_Discriminants := False;
      Context.Declaration_Targets.Pending_Discriminant_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Type_Header_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Record_After_Is_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Concurrent_Header_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Array_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Access_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Access_Subprogram_Profile_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Return_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Return_Access_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Subtype_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Derived_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Interface_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Declaration_Target_Owner := No_Symbol;
      Context.Declaration_Targets.Pending_Generic_Formal_Package_Target_Owner :=
        No_Symbol;
      Context.Declaration_Targets.Pending_Generic_Formal_Subprogram_Target_Owner :=
        No_Symbol;
      Context.Declaration_Targets.Pending_Object_Array_Target_Owners :=
        (others => No_Symbol);
      Context.Declaration_Targets.Pending_Object_Array_Target_Count := 0;
      Context.Declaration_Targets.Pending_Object_Access_Target_Owners :=
        (others => No_Symbol);
      Context.Declaration_Targets.Pending_Object_Access_Target_Count := 0;
      Context.Declaration_Targets
        .Pending_Object_Access_Subprogram_Profile_Owners :=
        (others => No_Symbol);
      Context.Declaration_Targets
        .Pending_Object_Access_Subprogram_Profile_Count := 0;

      Context.Profile.Pending_Profile_Access_Target_Owners :=
        (others => No_Symbol);
      Context.Profile.Pending_Profile_Access_Target_Count := 0;
      Context.Profile.Pending_Profile := False;
      Context.Profile.Pending_Profile_Owner := No_Symbol;

      Context.Executable_Binding.Pending_Enumeration := False;
      Context.Executable_Binding.Pending_Enumeration_Owner := No_Symbol;
      Context.Executable_Binding.Pending_Body_Owner := No_Symbol;
   end Clear_After_Scope_Close;

end Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase;
