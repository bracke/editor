with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Integrated_Semantic_Closure.Dataflow is

   pragma Suppress (Overflow_Check);

   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;

   use type DGL.Dataflow_Legality_Status;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Is_Legal (Status : DGL.Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        DGL.Dataflow_Legality_Legal_Read |
        DGL.Dataflow_Legality_Legal_Write |
        DGL.Dataflow_Legality_Legal_Read_Write |
        DGL.Dataflow_Legality_Legal_Null_Effect |
        DGL.Dataflow_Legality_Legal_Depends_Edge |
        DGL.Dataflow_Legality_Legal_Refinement;
   end Is_Legal;

   function Context_Kind_For
     (Kind : DGL.Dataflow_Context_Kind) return Integrated_Closure_Context_Kind is
   begin
      case Kind is
         when DGL.Dataflow_Context_Subprogram |
              DGL.Dataflow_Context_Entry |
              DGL.Dataflow_Context_Protected_Operation |
              DGL.Dataflow_Context_Task_Body |
              DGL.Dataflow_Context_Generic_Instance =>
            return Closure_Context_Subprogram_Body;
         when DGL.Dataflow_Context_Package_Elaboration =>
            return Closure_Context_Package_Body;
         when DGL.Dataflow_Context_Contract_Aspect =>
            return Closure_Context_Expression;
         when DGL.Dataflow_Context_Statement =>
            return Closure_Context_Statement;
         when DGL.Dataflow_Context_Expression =>
            return Closure_Context_Expression;
         when DGL.Dataflow_Context_Unknown =>
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

   function Build_With_Dataflow
     (Contexts : Integrated_Closure_Context_Model;
      Dataflow : DGL.Dataflow_Legality_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. DGL.Row_Count (Dataflow) loop
         declare
            Row : constant DGL.Dataflow_Legality_Info := DGL.Row_At (Dataflow, Index);
            C   : Integrated_Closure_Context_Info;
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Row.Kind);
            C.Unit_Name := Row.Object_Name;
            C.Normalized_Unit_Name := Normalized (Row.Object_Name);
            C.Dependency_Name := Row.Source_Name;
            C.Normalized_Dependency := Normalized (Row.Source_Name);
            C.Node := Row.Node;
            C.Dependency_Node := Row.Source_Node;
            C.Dependency := Dependency_Local_Only;
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;

            if Row.Status = DGL.Dataflow_Legality_Indeterminate then
               C.Indeterminate := True;
               C.Primary_Blocker := Closure_Blocker_Indeterminate;
            elsif Row.Status = DGL.Dataflow_Legality_Not_Checked then
               C.Dependency := Dependency_Unknown;
            elsif not Is_Legal (Row.Status) then
               C.Dataflow_Error := True;
               C.Primary_Blocker := Closure_Blocker_Dataflow;
            end if;

            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Dataflow;

end Editor.Ada_Integrated_Semantic_Closure.Dataflow;
