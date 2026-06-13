with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain is
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Context_Kind_For
     (Kind : GRR.Generic_Replay_Representation_Context_Kind)
      return Integrated_Closure_Context_Kind is
   begin
      case Kind is
         when GRR.Generic_Replay_Representation_Formal_Substitution |
              GRR.Generic_Replay_Representation_Generic_Instance |
              GRR.Generic_Replay_Representation_Nested_Generic_Instance =>
            return Closure_Context_Generic_Instance;
         when GRR.Generic_Replay_Representation_Body_Declaration |
              GRR.Generic_Replay_Representation_Body_Statement |
              GRR.Generic_Replay_Representation_Tasking_Effect =>
            return Closure_Context_Statement;
         when GRR.Generic_Replay_Representation_Body_Expression =>
            return Closure_Context_Expression;
         when GRR.Generic_Replay_Representation_Freezing_Effect |
              GRR.Generic_Replay_Representation_Representation_Clause |
              GRR.Generic_Replay_Representation_Operational_Attribute |
              GRR.Generic_Replay_Representation_Stream_Attribute |
              GRR.Generic_Replay_Representation_Record_Layout |
              GRR.Generic_Replay_Representation_Private_Full_View =>
            return Closure_Context_Representation_Item;
         when GRR.Generic_Replay_Representation_Unknown =>
            return Closure_Context_Unknown;
      end case;
   end Context_Kind_For;

   function Unit_Name_For (Row : GRR.Generic_Replay_Representation_Info) return Unbounded_String is
   begin
      if Length (Row.Instance_Name) > 0 then
         return Row.Instance_Name;
      elsif Length (Row.Generic_Unit_Name) > 0 then
         return Row.Generic_Unit_Name;
      elsif Length (Row.Target_Name) > 0 then
         return Row.Target_Name;
      else
         return To_Unbounded_String ("<anonymous generic replay consumer context>");
      end if;
   end Unit_Name_For;

   function Dependency_Name_For (Row : GRR.Generic_Replay_Representation_Info) return Unbounded_String is
   begin
      if Length (Row.Target_Name) > 0 then
         return Row.Target_Name;
      elsif Length (Row.Actual_Name) > 0 then
         return Row.Actual_Name;
      elsif Length (Row.Formal_Name) > 0 then
         return Row.Formal_Name;
      elsif Length (Row.Generic_Unit_Name) > 0 then
         return Row.Generic_Unit_Name;
      else
         return Null_Unbounded_String;
      end if;
   end Dependency_Name_For;

   function Dependency_Node_For
     (Row : GRR.Generic_Replay_Representation_Info) return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      if Row.Target_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Target_Node;
      elsif Row.Representation_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Representation_Node;
      elsif Row.Instance_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Instance_Node;
      elsif Row.Generic_Source_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Generic_Source_Node;
      else
         return Editor.Ada_Syntax_Tree.No_Node;
      end if;
   end Dependency_Node_For;

   procedure Apply_Status
     (Row : GRR.Generic_Replay_Representation_Info;
      C   : in out Integrated_Closure_Context_Info) is
   begin
      if GRR.Is_Legal (Row.Status) then
         null;
      else
         case Row.Status is
            when GRR.Generic_Replay_Representation_Not_Checked |
                 GRR.Generic_Replay_Representation_Missing_Representation_CPD_Row =>
               C.Dependency := Dependency_Unknown;

            when GRR.Generic_Replay_Representation_Replay_Mapping_Error |
                 GRR.Generic_Replay_Representation_Replay_Expansion_Error |
                 GRR.Generic_Replay_Representation_Base_Replay_Error =>
               C.Primary_Blocker := Closure_Blocker_Wide_Legality;
               C.Wide_Legality_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Overload_Error =>
               C.Overload_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Flow_Error |
                 GRR.Generic_Replay_Representation_Linked_Flow_Graph_Error |
                 GRR.Generic_Replay_Representation_Call_Effect_Not_Propagated =>
               C.Dataflow_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Predicate_Error |
                 GRR.Generic_Replay_Representation_Base_Contract_Flow_Error =>
               C.Contract_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Accessibility_Error =>
               C.Accessibility_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Representation_Error |
                 GRR.Generic_Replay_Representation_Base_Representation_CPD_Error |
                 GRR.Generic_Replay_Representation_Base_Freezing_Error =>
               C.Representation_Error := True;

            when GRR.Generic_Replay_Representation_Refined_Global_Missing_Read |
                 GRR.Generic_Replay_Representation_Refined_Global_Missing_Write |
                 GRR.Generic_Replay_Representation_Refined_Global_Mode_Mismatch |
                 GRR.Generic_Replay_Representation_Refined_Global_Extra_Item |
                 GRR.Generic_Replay_Representation_Refined_Depends_Missing_Edge |
                 GRR.Generic_Replay_Representation_Refined_Depends_Extra_Edge |
                 GRR.Generic_Replay_Representation_Refined_Depends_Source_Mode_Error |
                 GRR.Generic_Replay_Representation_Refined_Depends_Target_Mode_Error =>
               C.Refined_Global_Depends_Error := True;

            when GRR.Generic_Replay_Representation_Replay_Coverage_Gate_Blocker |
                 GRR.Generic_Replay_Representation_Coverage_Feedback_Blocker =>
               C.Coverage_Gate_Error := True;

            when GRR.Generic_Replay_Representation_Base_Elaboration_Error =>
               C.Elaboration_Error := True;

            when GRR.Generic_Replay_Representation_Base_Tasking_Effect_Error =>
               C.Wide_Legality_Error := True;

            when GRR.Generic_Replay_Representation_Multiple_Representation_CPD_Blockers =>
               C.Contract_Error := True;
               C.Dataflow_Error := True;
               C.Representation_Error := True;

            when GRR.Generic_Replay_Representation_Representation_CPD_Indeterminate |
                 GRR.Generic_Replay_Representation_Indeterminate =>
               C.Indeterminate := True;
               C.Primary_Blocker := Closure_Blocker_Indeterminate;

            when GRR.Generic_Replay_Representation_Legal_Formal_Substitution_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Body_Declaration_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Body_Statement_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Body_Expression_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Generic_Instance_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Nested_Generic_Instance_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Freezing_Effect_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Representation_Clause_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Operational_Attribute_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Stream_Attribute_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Record_Layout_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Private_Full_View_Accepted |
                 GRR.Generic_Replay_Representation_Legal_Tasking_Effect_Accepted =>
               null;
         end case;
      end if;
   end Apply_Status;

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   function Build_With_Consumer_Chain
     (Contexts : Integrated_Closure_Context_Model;
      Generic_Replay : GRR.Generic_Replay_Representation_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. GRR.Row_Count (Generic_Replay) loop
         declare
            Row : constant GRR.Generic_Replay_Representation_Info := GRR.Row_At (Generic_Replay, Index);
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
            C.Dependency_Node := Dependency_Node_For (Row);
            C.Dependency := Dependency_Local_Only;
            C.Source_Fingerprint := Row.Fingerprint;
            if C.Source_Fingerprint = 0 then
               C.Source_Fingerprint := Row.Source_Fingerprint;
            end if;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;

            Apply_Status (Row, C);
            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Consumer_Chain;

end Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
