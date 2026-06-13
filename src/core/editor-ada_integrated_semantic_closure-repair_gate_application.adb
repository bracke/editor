with Ada.Characters.Handling;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Semantic_Coverage_Gates;

package body Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application is

   package App renames Editor.Ada_AST_Coverage_Repair_Gate_Application;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Context_Kind_For
     (Conclusion : Gates.Semantic_Conclusion_Kind;
      Construct  : Audit.Ada_Construct_Kind) return Integrated_Closure_Context_Kind is
   begin
      case Conclusion is
         when Gates.Conclusion_Assignment |
              Gates.Conclusion_Return |
              Gates.Conclusion_Exception_Finalization =>
            return Closure_Context_Statement;
         when Gates.Conclusion_Conversion |
              Gates.Conclusion_Aggregate |
              Gates.Conclusion_Call |
              Gates.Conclusion_Overload |
              Gates.Conclusion_Staticness |
              Gates.Conclusion_Accessibility |
              Gates.Conclusion_Record_Variant =>
            return Closure_Context_Expression;
         when Gates.Conclusion_Contract |
              Gates.Conclusion_Dataflow |
              Gates.Conclusion_Elaboration =>
            return Closure_Context_Compilation_Unit;
         when Gates.Conclusion_Generic_Instance =>
            return Closure_Context_Generic_Instance;
         when Gates.Conclusion_Tasking_Protected =>
            return Closure_Context_Task_Protected_Unit;
         when Gates.Conclusion_Representation =>
            return Closure_Context_Representation_Item;
         when Gates.Conclusion_Integrated_Closure |
              Gates.Conclusion_Unknown =>
            case Construct is
               when Audit.Construct_Assignment |
                    Audit.Construct_Return_Statement |
                    Audit.Construct_Extended_Return |
                    Audit.Construct_Accept_Statement |
                    Audit.Construct_Requeue_Statement |
                    Audit.Construct_Select_Statement =>
                  return Closure_Context_Statement;
               when Audit.Construct_Generic_Instantiation |
                    Audit.Construct_Generic_Renaming |
                    Audit.Construct_Generic_Formal_Object |
                    Audit.Construct_Generic_Formal_Type |
                    Audit.Construct_Generic_Formal_Subprogram |
                    Audit.Construct_Generic_Formal_Package =>
                  return Closure_Context_Generic_Declaration;
               when Audit.Construct_Task_Type |
                    Audit.Construct_Task_Body |
                    Audit.Construct_Protected_Type |
                    Audit.Construct_Protected_Body |
                    Audit.Construct_Entry_Declaration |
                    Audit.Construct_Entry_Body =>
                  return Closure_Context_Task_Protected_Unit;
               when Audit.Construct_Representation_Clause |
                    Audit.Construct_Operational_Attribute_Clause =>
                  return Closure_Context_Representation_Item;
               when Audit.Construct_Call |
                    Audit.Construct_Conversion |
                    Audit.Construct_Qualified_Expression |
                    Audit.Construct_Record_Aggregate |
                    Audit.Construct_Extension_Aggregate |
                    Audit.Construct_Array_Aggregate |
                    Audit.Construct_Container_Aggregate |
                    Audit.Construct_Delta_Aggregate |
                    Audit.Construct_Reduction_Expression |
                    Audit.Construct_Quantified_Expression |
                    Audit.Construct_Membership_Test |
                    Audit.Construct_Case_Expression |
                    Audit.Construct_If_Expression |
                    Audit.Construct_Declare_Expression |
                    Audit.Construct_Target_Name |
                    Audit.Construct_Allocator |
                    Audit.Construct_Raise_Expression =>
                  return Closure_Context_Expression;
               when others =>
                  return Closure_Context_Compilation_Unit;
            end case;
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

   procedure Apply_Application
     (C   : in out Integrated_Closure_Context_Info;
      Row : App.Application_Info) is
   begin
      case Row.Status is
         when App.Application_Already_Confident |
              App.Application_Repair_Clears_Parser_AST_Blocker |
              App.Application_Repair_Clears_Metadata_Blocker |
              App.Application_Repair_Clears_Consumer_Blocker |
              App.Application_Repair_Clears_Suppressed_Legal |
              App.Application_Repair_Clears_Suppressed_Derived |
              App.Application_Repair_Clears_Unsafe_Blocker =>
            C.Dependency := Dependency_Local_Only;
            C.Primary_Blocker := Closure_Blocker_None;
         when App.Application_Cross_Unit_Still_Required =>
            C.Dependency := Dependency_Missing;
            C.Primary_Blocker := Closure_Blocker_Dependency;
         when App.Application_Repair_Indeterminate |
              App.Application_Repair_Partial =>
            C.Dependency := Dependency_Unknown;
            C.Indeterminate := True;
            C.Primary_Blocker := Closure_Blocker_Indeterminate;
         when App.Application_Original_Error_Preserved |
              App.Application_Repair_Missing |
              App.Application_Repair_Mismatch |
              App.Application_Enforcement_Still_Blocking |
              App.Application_Not_Checked =>
            C.Dependency := Dependency_Local_Only;
            C.Coverage_Gate_Error := True;
            C.Primary_Blocker := Closure_Blocker_Coverage_Gate;
      end case;
   end Apply_Application;

   function Build_With_Repair_Gate_Application
     (Contexts     : Integrated_Closure_Context_Model;
      Applications : Editor.Ada_AST_Coverage_Repair_Gate_Application.Application_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. App.Row_Count (Applications) loop
         declare
            Row : constant App.Application_Info := App.Row_At (Applications, Index);
            C   : Integrated_Closure_Context_Info;
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Row.Conclusion, Row.Construct);
            C.Unit_Name := Row.Construct_Name;
            C.Normalized_Unit_Name := Normalized (Row.Normalized_Name);
            C.Dependency_Name := To_Unbounded_String
              (Gates.Semantic_Conclusion_Kind'Image (Row.Conclusion) &
               ":" & Audit.Semantic_Consumer_Family'Image (Row.Consumer));
            C.Normalized_Dependency := To_Unbounded_String
              (App.Application_Status'Image (Row.Status) &
               ":" & Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement.Enforcement_Status'Image (Row.Enforcement_Status));
            C.Node := Row.Node;
            C.Dependency_Node := Row.Parent_Node;
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;

            Apply_Application (C, Row);
            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Repair_Gate_Application;

end Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application;
