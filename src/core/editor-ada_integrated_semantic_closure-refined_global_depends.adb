with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends is
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Status;

   package RGD renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;

   function Map_Status
     (Status : RGD.Refined_Conformance_Status) return Refined_Global_Depends_Status is
   begin
      case Status is
         when RGD.Refined_Conformance_Not_Checked =>
            return Refined_Conformance_Not_Checked;
         when RGD.Refined_Conformance_Legal_Global_Refinement =>
            return Refined_Conformance_Legal_Global_Refinement;
         when RGD.Refined_Conformance_Legal_Depends_Refinement =>
            return Refined_Conformance_Legal_Depends_Refinement;
         when RGD.Refined_Conformance_Legal_Null_Refinement =>
            return Refined_Conformance_Legal_Null_Refinement;
         when RGD.Refined_Conformance_Legal_Call_Effect_Propagation =>
            return Refined_Conformance_Legal_Call_Effect_Propagation;
         when RGD.Refined_Conformance_Body_Read_Missing_From_Spec_Global =>
            return Refined_Conformance_Body_Read_Missing_From_Spec_Global;
         when RGD.Refined_Conformance_Body_Write_Missing_From_Spec_Global =>
            return Refined_Conformance_Body_Write_Missing_From_Spec_Global;
         when RGD.Refined_Conformance_Body_Read_Missing_From_Refined_Global =>
            return Refined_Conformance_Body_Read_Missing_From_Refined_Global;
         when RGD.Refined_Conformance_Body_Write_Missing_From_Refined_Global =>
            return Refined_Conformance_Body_Write_Missing_From_Refined_Global;
         when RGD.Refined_Conformance_Refined_Global_Extra_Item =>
            return Refined_Conformance_Refined_Global_Extra_Item;
         when RGD.Refined_Conformance_Refined_Global_Mode_Mismatch =>
            return Refined_Conformance_Refined_Global_Mode_Mismatch;
         when RGD.Refined_Conformance_Refined_Depends_Missing_Edge =>
            return Refined_Conformance_Refined_Depends_Missing_Edge;
         when RGD.Refined_Conformance_Refined_Depends_Extra_Edge =>
            return Refined_Conformance_Refined_Depends_Extra_Edge;
         when RGD.Refined_Conformance_Refined_Depends_Source_Not_Spec_Input =>
            return Refined_Conformance_Refined_Depends_Source_Not_Spec_Input;
         when RGD.Refined_Conformance_Refined_Depends_Target_Not_Spec_Output =>
            return Refined_Conformance_Refined_Depends_Target_Not_Spec_Output;
         when RGD.Refined_Conformance_Body_Depends_Not_Refined =>
            return Refined_Conformance_Body_Depends_Not_Refined;
         when RGD.Refined_Conformance_Call_Effect_Not_Propagated =>
            return Refined_Conformance_Call_Effect_Not_Propagated;
         when RGD.Refined_Conformance_Linked_Flow_Graph_Error =>
            return Refined_Conformance_Linked_Flow_Graph_Error;
         when RGD.Refined_Conformance_Coverage_Feedback_Blocker =>
            return Refined_Conformance_Coverage_Feedback_Blocker;
         when RGD.Refined_Conformance_Indeterminate =>
            return Refined_Conformance_Indeterminate;
      end case;
   end Map_Status;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Is_Legal (Status : RGD.Refined_Conformance_Status) return Boolean is
   begin
      return Status in
        RGD.Refined_Conformance_Legal_Global_Refinement |
        RGD.Refined_Conformance_Legal_Depends_Refinement |
        RGD.Refined_Conformance_Legal_Null_Refinement |
        RGD.Refined_Conformance_Legal_Call_Effect_Propagation;
   end Is_Legal;

   function Context_Kind_For
     (Kind : RGD.Refined_Context_Kind) return Integrated_Closure_Context_Kind is
   begin
      case Kind is
         when RGD.Refined_Context_Subprogram_Body |
              RGD.Refined_Context_Call_Propagation |
              RGD.Refined_Context_Generic_Instance_Body =>
            return Closure_Context_Subprogram_Body;
         when RGD.Refined_Context_Refined_Global_Item |
              RGD.Refined_Context_Refined_Depends_Edge =>
            return Closure_Context_Expression;
         when RGD.Refined_Context_Task_Protected_Body =>
            return Closure_Context_Task_Protected_Unit;
         when RGD.Refined_Context_Package_Body =>
            return Closure_Context_Package_Body;
         when RGD.Refined_Context_Unknown =>
            return Closure_Context_Unknown;
      end case;
   end Context_Kind_For;

   function Unit_Name_For (Row : RGD.Refined_Conformance_Info) return Unbounded_String is
   begin
      if Length (Row.Subprogram_Name) > 0 then
         return Row.Subprogram_Name;
      elsif Length (Row.Object_Name) > 0 then
         return Row.Object_Name;
      elsif Length (Row.Target_Name) > 0 then
         return Row.Target_Name;
      else
         return To_Unbounded_String ("<anonymous refined Global/Depends context>");
      end if;
   end Unit_Name_For;

   function Dependency_Name_For (Row : RGD.Refined_Conformance_Info) return Unbounded_String is
   begin
      if Length (Row.Source_Name) > 0 then
         return Row.Source_Name;
      elsif Length (Row.Object_Name) > 0 then
         return Row.Object_Name;
      elsif Length (Row.Target_Name) > 0 then
         return Row.Target_Name;
      else
         return Null_Unbounded_String;
      end if;
   end Dependency_Name_For;

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   function Build_With_Refined_Global_Depends
     (Contexts : Integrated_Closure_Context_Model;
      Refined  : RGD.Refined_Conformance_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. RGD.Row_Count (Refined) loop
         declare
            Row : constant RGD.Refined_Conformance_Info := RGD.Row_At (Refined, Index);
            C   : Integrated_Closure_Context_Info;
            Unit_Name : constant Unbounded_String := Unit_Name_For (Row);
            Dependency_Name : constant Unbounded_String := Dependency_Name_For (Row);
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Row.Kind);
            C.Unit_Name := Unit_Name;
            C.Normalized_Unit_Name := Normalized (Unit_Name);
            C.Dependency_Name := Dependency_Name;
            C.Normalized_Dependency := Normalized (Dependency_Name);
            C.Node := Row.Node;
            C.Dependency_Node := Row.Source_Node;
            if C.Dependency_Node = Editor.Ada_Syntax_Tree.No_Node then
               C.Dependency_Node := Row.Target_Node;
            end if;
            C.Dependency := Dependency_Local_Only;
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;
            C.Refined_Global_Depends := Map_Status (Row.Status);

            if Row.Status = RGD.Refined_Conformance_Indeterminate then
               C.Indeterminate := True;
               C.Primary_Blocker := Closure_Blocker_Indeterminate;
            elsif Row.Status = RGD.Refined_Conformance_Not_Checked then
               C.Dependency := Dependency_Unknown;
            elsif not Is_Legal (Row.Status) then
               C.Refined_Global_Depends_Error := True;
               C.Primary_Blocker := Closure_Blocker_Refined_Global_Depends;
            end if;

            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Refined_Global_Depends;

end Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends;
