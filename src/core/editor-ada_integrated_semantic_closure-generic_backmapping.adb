with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping is
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Context_Kind_For
     (Kind : Backmap.Generic_Backmap_Context_Kind)
      return Integrated_Closure_Context_Kind is
   begin
      case Kind is
         when Backmap.Generic_Backmap_Declaration_Replay |
              Backmap.Generic_Backmap_Nested_Instance_Replay =>
            return Closure_Context_Generic_Instance;
         when Backmap.Generic_Backmap_Statement_Replay |
              Backmap.Generic_Backmap_Return_Replay |
              Backmap.Generic_Backmap_Assignment_Replay |
              Backmap.Generic_Backmap_Flow_Replay =>
            return Closure_Context_Statement;
         when Backmap.Generic_Backmap_Expression_Replay |
              Backmap.Generic_Backmap_Call_Replay |
              Backmap.Generic_Backmap_Predicate_Replay |
              Backmap.Generic_Backmap_Accessibility_Replay =>
            return Closure_Context_Expression;
         when Backmap.Generic_Backmap_Representation_Replay =>
            return Closure_Context_Representation_Item;
         when Backmap.Generic_Backmap_Unknown =>
            return Closure_Context_Unknown;
      end case;
   end Context_Kind_For;

   function Unit_Name_For
     (Row : Backmap.Generic_Backmap_Info) return Unbounded_String is
   begin
      if Length (Row.Instance_Name) > 0 then
         return Row.Instance_Name;
      elsif Length (Row.Generic_Unit_Name) > 0 then
         return Row.Generic_Unit_Name;
      else
         return To_Unbounded_String ("<anonymous generic backmap context>");
      end if;
   end Unit_Name_For;

   function Dependency_Name_For
     (Row : Backmap.Generic_Backmap_Info) return Unbounded_String is
   begin
      if Length (Row.Actual_Name) > 0 then
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
     (Row : Backmap.Generic_Backmap_Info) return Editor.Ada_Syntax_Tree.Node_Id is
   begin
      if Row.Actual_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Actual_Node;
      elsif Row.Formal_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Formal_Node;
      elsif Row.Instance_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Instance_Node;
      elsif Row.Generic_Source_Node /= Editor.Ada_Syntax_Tree.No_Node then
         return Row.Generic_Source_Node;
      else
         return Editor.Ada_Syntax_Tree.No_Node;
      end if;
   end Dependency_Node_For;

   procedure Apply_Status
     (Row : Backmap.Generic_Backmap_Info;
      C   : in out Integrated_Closure_Context_Info) is
   begin
      if Backmap.Is_Legal (Row.Status) then
         return;
      end if;

      case Row.Status is
         when Backmap.Generic_Backmap_Not_Checked |
              Backmap.Generic_Backmap_Indeterminate |
              Backmap.Generic_Backmap_Replay_CPD_Indeterminate |
              Backmap.Generic_Backmap_Overload_Type_Edge_Indeterminate =>
            C.Indeterminate := True;
            C.Primary_Blocker := Closure_Blocker_Indeterminate;

         when Backmap.Generic_Backmap_Missing_Generic_Source_Node |
              Backmap.Generic_Backmap_Missing_Instance_Node |
              Backmap.Generic_Backmap_Missing_Formal_Node |
              Backmap.Generic_Backmap_Missing_Actual_Node |
              Backmap.Generic_Backmap_Missing_Body_Node |
              Backmap.Generic_Backmap_Missing_Source_Instance_Map |
              Backmap.Generic_Backmap_Missing_Formal_Actual_Map |
              Backmap.Generic_Backmap_Missing_Diagnostic_Backmap |
              Backmap.Generic_Backmap_Source_Instance_Fingerprint_Mismatch |
              Backmap.Generic_Backmap_Substitution_Fingerprint_Mismatch |
              Backmap.Generic_Backmap_Replay_Mapping_Error =>
            C.Coverage_Gate_Error := True;

         when Backmap.Generic_Backmap_Base_Replay_Error =>
            case Row.Kind is
               when Backmap.Generic_Backmap_Flow_Replay =>
                  C.Dataflow_Error := True;
               when Backmap.Generic_Backmap_Predicate_Replay =>
                  C.Contract_Error := True;
               when Backmap.Generic_Backmap_Accessibility_Replay =>
                  C.Accessibility_Error := True;
               when Backmap.Generic_Backmap_Representation_Replay =>
                  C.Representation_Error := True;
               when others =>
                  C.Wide_Legality_Error := True;
            end case;

         when Backmap.Generic_Backmap_Missing_Replay_CPD_Row |
              Backmap.Generic_Backmap_Replay_CPD_Blocker |
              Backmap.Generic_Backmap_Multiple_Matching_Replay_CPD_Rows =>
            case Row.Kind is
               when Backmap.Generic_Backmap_Flow_Replay =>
                  C.Dataflow_Error := True;
               when Backmap.Generic_Backmap_Predicate_Replay =>
                  C.Contract_Error := True;
               when Backmap.Generic_Backmap_Accessibility_Replay =>
                  C.Accessibility_Error := True;
               when Backmap.Generic_Backmap_Representation_Replay =>
                  C.Representation_Error := True;
               when Backmap.Generic_Backmap_Nested_Instance_Replay |
                    Backmap.Generic_Backmap_Declaration_Replay =>
                  C.Contract_Error := True;
               when others =>
                  C.Wide_Legality_Error := True;
            end case;

         when Backmap.Generic_Backmap_Missing_Overload_Type_Edge_Row |
              Backmap.Generic_Backmap_Overload_Type_Edge_Blocker |
              Backmap.Generic_Backmap_Overload_Type_Edge_Ambiguous |
              Backmap.Generic_Backmap_Multiple_Matching_Overload_Rows =>
            C.Overload_Error := True;

         when Backmap.Generic_Backmap_Legal_Declaration_Backmapped |
              Backmap.Generic_Backmap_Legal_Statement_Backmapped |
              Backmap.Generic_Backmap_Legal_Expression_Backmapped |
              Backmap.Generic_Backmap_Legal_Call_Backmapped |
              Backmap.Generic_Backmap_Legal_Return_Backmapped |
              Backmap.Generic_Backmap_Legal_Assignment_Backmapped |
              Backmap.Generic_Backmap_Legal_Representation_Backmapped |
              Backmap.Generic_Backmap_Legal_Flow_Backmapped |
              Backmap.Generic_Backmap_Legal_Predicate_Backmapped |
              Backmap.Generic_Backmap_Legal_Accessibility_Backmapped |
              Backmap.Generic_Backmap_Legal_Nested_Instance_Backmapped =>
            null;
      end case;
   end Apply_Status;

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   function Build_With_Generic_Backmapping
     (Contexts : Integrated_Closure_Context_Model;
      Backmaps : Backmap.Generic_Backmap_Model) return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. Backmap.Row_Count (Backmaps) loop
         declare
            Row : constant Backmap.Generic_Backmap_Info := Backmap.Row_At (Backmaps, Index);
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
            if C.Node = Editor.Ada_Syntax_Tree.No_Node then
               C.Node := Row.Generic_Source_Node;
            end if;
            C.Dependency_Node := Dependency_Node_For (Row);
            C.Dependency := Dependency_Local_Only;
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := 1;
            C.Start_Column := 1;
            C.End_Line := 1;
            C.End_Column := 1;

            Apply_Status (Row, C);
            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Generic_Backmapping;

end Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
