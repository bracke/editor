with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Integrated_Semantic_Closure.AST_Coverage is
   use type Editor.Ada_AST_Semantic_Coverage_Audit.Coverage_Status;

   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   function Normalized (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalized;

   function Is_Legal (Status : Audit.Coverage_Status) return Boolean is
   begin
      return Status = Audit.Coverage_Complete;
   end Is_Legal;

   function Dependency_For (Status : Audit.Coverage_Status)
      return Closure_Dependency_State is
   begin
      case Status is
         when Audit.Coverage_Cross_Unit_Metadata_Missing =>
            return Dependency_Missing;
         when Audit.Coverage_Not_Checked =>
            return Dependency_Unknown;
         when others =>
            return Dependency_Local_Only;
      end case;
   end Dependency_For;

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

   procedure Copy_Existing_Contexts
     (Source : Integrated_Closure_Context_Model;
      Target : in out Integrated_Closure_Context_Model) is
   begin
      for Index in 1 .. Context_Count (Source) loop
         Add_Context (Target, Context_At (Source, Index));
      end loop;
   end Copy_Existing_Contexts;

   function Build_With_AST_Coverage
     (Contexts : Integrated_Closure_Context_Model;
      Coverage : Audit.Coverage_Model)
      return Integrated_Closure_Model
   is
      Combined : Integrated_Closure_Context_Model;
      Base     : constant Natural := Context_Count (Contexts);
   begin
      Copy_Existing_Contexts (Contexts, Combined);

      for Index in 1 .. Audit.Coverage_Count (Coverage) loop
         declare
            Row : constant Audit.Coverage_Info := Audit.Coverage_At (Coverage, Index);
            C   : Integrated_Closure_Context_Info;
         begin
            C.Id := Integrated_Closure_Context_Id (Base + Index);
            C.Kind := Context_Kind_For (Row.Construct);
            C.Unit_Name := Row.Construct_Name;
            C.Normalized_Unit_Name := Normalized (Row.Normalized_Construct_Name);
            C.Node := Row.Node;
            C.Dependency_Node := Row.Parent_Node;
            C.Dependency := Dependency_For (Row.Status);
            C.Source_Fingerprint := Row.Fingerprint;
            C.Start_Line := Row.Start_Line;
            C.Start_Column := Row.Start_Column;
            C.End_Line := Row.End_Line;
            C.End_Column := Row.End_Column;

            if Row.Status = Audit.Coverage_Indeterminate then
               C.Indeterminate := True;
               C.Primary_Blocker := Closure_Blocker_Indeterminate;
            elsif Row.Status = Audit.Coverage_Not_Checked then
               C.Dependency := Dependency_Unknown;
            elsif Row.Status = Audit.Coverage_Cross_Unit_Metadata_Missing then
               C.Primary_Blocker := Closure_Blocker_Dependency;
            elsif not Is_Legal (Row.Status) then
               C.AST_Coverage_Error := True;
               C.Primary_Blocker := Closure_Blocker_AST_Coverage;
            end if;

            Add_Context (Combined, C);
         end;
      end loop;

      return Build (Combined);
   end Build_With_AST_Coverage;

end Editor.Ada_Integrated_Semantic_Closure.AST_Coverage;
