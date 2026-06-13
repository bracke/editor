with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;

package body Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates is

   package Gate_Pkg renames Editor.Ada_Semantic_Coverage_Gates;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Context_Kind_For
     (Construct : Audit.Ada_Construct_Kind) return Integrated_Closure_Context_Kind is
   begin
      case Construct is
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
         when Audit.Construct_Assignment |
              Audit.Construct_Return_Statement |
              Audit.Construct_Extended_Return |
              Audit.Construct_Accept_Statement |
              Audit.Construct_Requeue_Statement |
              Audit.Construct_Select_Statement =>
            return Closure_Context_Statement;
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
         when Audit.Construct_Separate_Body |
              Audit.Construct_Body_Stub =>
            return Closure_Context_Package_Body;
         when Audit.Construct_Aspect_Specification |
              Audit.Construct_Pragma |
              Audit.Construct_Renaming_Declaration |
              Audit.Construct_Access_Definition |
              Audit.Construct_Discriminant_Specification |
              Audit.Construct_Variant_Part |
              Audit.Construct_Exception_Handler =>
            return Closure_Context_Compilation_Unit;
         when Audit.Construct_Unknown =>
            return Closure_Context_Unknown;
      end case;
   end Context_Kind_For;

   function Dependency_For
     (Gate : Gate_Pkg.Gate_Info) return Closure_Dependency_State is
   begin
      case Gate.Action is
         when Gate_Pkg.Gate_Allow_Confident_Result =>
            return Dependency_Local_Only;
         when Gate_Pkg.Gate_Require_Cross_Unit_Closure =>
            return Dependency_Missing;
         when Gate_Pkg.Gate_Degrade_To_Indeterminate =>
            return Dependency_Unknown;
         when others =>
            return Dependency_Local_Only;
      end case;
   end Dependency_For;

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   procedure Apply_Gate
     (C    : in out Integrated_Closure_Context_Info;
      Gate : Gate_Pkg.Gate_Info) is
   begin
      C.Dependency := Dependency_For (Gate);

      case Gate.Action is
         when Gate_Pkg.Gate_Allow_Confident_Result =>
            C.Primary_Blocker := Closure_Blocker_None;
         when Gate_Pkg.Gate_Require_Cross_Unit_Closure =>
            C.Primary_Blocker := Closure_Blocker_Dependency;
         when Gate_Pkg.Gate_Degrade_To_Indeterminate =>
            C.Indeterminate := True;
            C.Primary_Blocker := Closure_Blocker_Indeterminate;
         when Gate_Pkg.Gate_Suppress_Legal_Result |
              Gate_Pkg.Gate_Suppress_Derived_Result |
              Gate_Pkg.Gate_Require_Parser_AST_Repair |
              Gate_Pkg.Gate_Require_Metadata_Repair |
              Gate_Pkg.Gate_Require_Consumer_Integration |
              Gate_Pkg.Gate_Block_Unsafe_Result =>
            C.Coverage_Gate_Error := True;
            C.Primary_Blocker := Closure_Blocker_Coverage_Gate;
      end case;
   end Apply_Gate;

   function Build_With_Coverage_Gates
     (Contexts : Integrated_Closure_Context_Model;
      Gates    : Editor.Ada_Semantic_Coverage_Gates.Gate_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. Editor.Ada_Semantic_Coverage_Gates.Gate_Count (Gates) loop
         declare
            Gate : constant Editor.Ada_Semantic_Coverage_Gates.Gate_Info :=
              Editor.Ada_Semantic_Coverage_Gates.Gate_At (Gates, Index);
            C    : Integrated_Closure_Context_Info;
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Gate.Construct);
            C.Unit_Name := Gate.Construct_Name;
            C.Normalized_Unit_Name := Normalized (Gate.Normalized_Name);
            C.Dependency_Name := To_Unbounded_String
              (Gate_Pkg.Semantic_Conclusion_Kind'Image (Gate.Conclusion));
            C.Normalized_Dependency := To_Unbounded_String
              (Gate_Pkg.Gate_Action'Image (Gate.Action));
            C.Node := Gate.Node;
            C.Dependency_Node := Gate.Parent_Node;
            C.Source_Fingerprint := Gate.Fingerprint;
            C.Start_Line := Gate.Start_Line;
            C.Start_Column := Gate.Start_Column;
            C.End_Line := Gate.End_Line;
            C.End_Column := Gate.End_Column;

            Apply_Gate (C, Gate);
            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_Coverage_Gates;

end Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates;
