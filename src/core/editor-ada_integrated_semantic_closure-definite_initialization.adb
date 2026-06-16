with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Status;

   package DIF renames Editor.Ada_Definite_Initialization_Flow_Legality;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Is_Legal (Status : DIF.Initialization_Legality_Status) return Boolean is
   begin
      return Status in
        DIF.Initialization_Legality_Definitely_Initialized |
        DIF.Initialization_Legality_Default_Initialized |
        DIF.Initialization_Legality_Explicitly_Initialized |
        DIF.Initialization_Legality_Component_Initialized |
        DIF.Initialization_Legality_Out_Parameter_Assigned |
        DIF.Initialization_Legality_Return_Object_Initialized |
        DIF.Initialization_Legality_Exception_Path_Preserved |
        DIF.Initialization_Legality_Finalization_Path_Preserved;
   end Is_Legal;

   function Context_Kind_For
     (Kind : DIF.Initialization_Context_Kind) return Integrated_Closure_Context_Kind is
   begin
      case Kind is
         when DIF.Initialization_Context_Object_Declaration |
              DIF.Initialization_Context_Parameter_In |
              DIF.Initialization_Context_Parameter_Out |
              DIF.Initialization_Context_Parameter_In_Out =>
            return Closure_Context_Subprogram_Body;
         when DIF.Initialization_Context_Assignment |
              DIF.Initialization_Context_Read |
              DIF.Initialization_Context_Return |
              DIF.Initialization_Context_Extended_Return |
              DIF.Initialization_Context_Exception_Path |
              DIF.Initialization_Context_Finalization_Path |
              DIF.Initialization_Context_Loop_Merge |
              DIF.Initialization_Context_Branch_Merge =>
            return Closure_Context_Statement;
         when DIF.Initialization_Context_Component |
              DIF.Initialization_Context_Aggregate =>
            return Closure_Context_Expression;
         when DIF.Initialization_Context_Unknown =>
            return Closure_Context_Unknown;
      end case;
   end Context_Kind_For;

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   function Build_With_Definite_Initialization
     (Contexts       : Integrated_Closure_Context_Model;
      Initialization : DIF.Initialization_Legality_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. DIF.Row_Count (Initialization) loop
         declare
            Row : constant DIF.Initialization_Legality_Info :=
              DIF.Row_At (Initialization, Index);
            C   : Integrated_Closure_Context_Info;
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Row.Kind);
            C.Unit_Name := Row.Object_Name;
            C.Normalized_Unit_Name := Normalized (Row.Object_Name);
            C.Node := Row.Node;
            C.Dependency_Node := Row.Object_Node;
            C.Dependency := Dependency_Local_Only;
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;

            if Row.Status = DIF.Initialization_Legality_Indeterminate then
               C.Indeterminate := True;
               C.Primary_Blocker := Closure_Blocker_Indeterminate;
            elsif Row.Status = DIF.Initialization_Legality_Not_Checked then
               C.Dependency := Dependency_Unknown;
            elsif not Is_Legal (Row.Status) then
               C.Initialization_Error := True;
               C.Primary_Blocker := Closure_Blocker_Definite_Initialization;
            end if;

            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Definite_Initialization;

end Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization;
