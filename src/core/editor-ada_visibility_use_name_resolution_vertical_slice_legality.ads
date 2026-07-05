with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality is

   --  Case 1317 vertical-slice visibility/use-clause/name-resolution legality.
   --  This package models concrete Ada direct visibility, selected/expanded-name
   --  visibility, use/use type visibility, hiding, homographs, child/private-child
   --  visibility, limited/private-view barriers, and operator visibility.  It is
   --  intended as real input to overload resolution and selected-name legality,
   --  not as another diagnostic/provenance/recheck wrapper.

   type Lookup_Id is new Natural;
   No_Lookup : constant Lookup_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Lookup_Kind is
     (Lookup_Simple_Name,
      Lookup_Selected_Name,
      Lookup_Expanded_Name,
      Lookup_Operator_Symbol,
      Lookup_Use_Visible_Operator,
      Lookup_Use_Visible_Declaration,
      Lookup_Generic_Formal_Name,
      Lookup_Child_Unit_Name,
      Lookup_Private_Child_Unit_Name,
      Lookup_Renamed_Entity,
      Lookup_Attribute_Prefix,
      Lookup_Unknown);

   type Declaration_Kind is
     (Decl_Unknown,
      Decl_Package,
      Decl_Subprogram,
      Decl_Operator,
      Decl_Type,
      Decl_Subtype,
      Decl_Object,
      Decl_Component,
      Decl_Exception,
      Decl_Generic,
      Decl_Formal,
      Decl_Child_Unit,
      Decl_Private_Child_Unit,
      Decl_Renaming,
      Decl_Not_Declaration);

   type Region_Kind is
     (Region_Unknown,
      Region_Library,
      Region_Package_Spec,
      Region_Package_Body,
      Region_Subprogram,
      Region_Block,
      Region_Generic_Spec,
      Region_Generic_Body,
      Region_Private_Part,
      Region_Protected_Body,
      Region_Task_Body);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Visibility_Source is
     (Visibility_None,
      Visibility_Direct,
      Visibility_Selected,
      Visibility_Use_Package,
      Visibility_Use_Type,
      Visibility_With,
      Visibility_Renaming,
      Visibility_Implicit_Operator,
      Visibility_Inherited_Primitive,
      Visibility_Generic_Formal);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_Ambiguous_Overload_Set,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Symbol_Evidence,
      Legality_No_Visible_Declaration,
      Legality_Declaration_Not_Directly_Visible,
      Legality_Use_Clause_Not_Visible,
      Legality_Use_Type_Operator_Not_Visible,
      Legality_Hidden_By_Inner_Declaration,
      Legality_Homograph_Conflict,
      Legality_Ambiguous_Use_Visibility,
      Legality_Selected_Prefix_Not_Visible,
      Legality_Selected_Selector_Not_Visible,
      Legality_With_Clause_Missing,
      Legality_Private_Child_Not_Visible,
      Legality_Limited_View_Barrier,
      Legality_Private_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Renaming_Target_Not_Visible,
      Legality_Wrong_Declaration_Kind,
      Legality_Overload_Context_Blocker,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Symbol_Fingerprint_Mismatch,
      Legality_Visibility_Fingerprint_Mismatch,
      Legality_View_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Lookup_Info is record
      Id       : Lookup_Id := No_Lookup;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Lookup_Kind := Lookup_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Region   : Region_Kind := Region_Unknown;
      Candidate_Kind : Declaration_Kind := Decl_Unknown;
      Expected_Kind  : Declaration_Kind := Decl_Unknown;
      Source   : Visibility_Source := Visibility_None;
      View     : View_Kind := View_Full;

      Has_AST_Coverage : Boolean := True;
      Has_Symbol_Evidence : Boolean := True;
      Has_Visible_Declaration : Boolean := True;
      Directly_Visible : Boolean := True;
      Use_Clause_Visible : Boolean := True;
      Use_Type_Operator_Visible : Boolean := True;
      Hidden_By_Inner_Declaration : Boolean := False;
      Homograph_Conflict : Boolean := False;
      Multiple_Use_Candidates : Boolean := False;
      Ambiguity_Allowed_By_Overload : Boolean := False;
      Selected_Prefix_Visible : Boolean := True;
      Selected_Selector_Visible : Boolean := True;
      With_Clause_Present : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Limited_View_Allows_Use : Boolean := True;
      Private_View_Allows_Use : Boolean := True;
      Incomplete_View_Allows_Use : Boolean := True;
      Generic_Formal_View_Allows_Use : Boolean := True;
      Renaming_Target_Visible : Boolean := True;
      Declaration_Kind_Compatible : Boolean := True;
      Overload_Context_OK : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_Symbol_Fingerprint : Natural := 0;
      Expected_Visibility_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Symbol_Fingerprint : Natural := 0;
      Visibility_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Lookup   : Lookup_Id := No_Lookup;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Lookup_Kind := Lookup_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      Resolved_Source : Visibility_Source := Visibility_None;
      AST_Blockers : Natural := 0;
      Symbol_Blockers : Natural := 0;
      No_Visible_Declaration_Blockers : Natural := 0;
      Direct_Visibility_Blockers : Natural := 0;
      Use_Clause_Blockers : Natural := 0;
      Use_Type_Operator_Blockers : Natural := 0;
      Hiding_Blockers : Natural := 0;
      Homograph_Blockers : Natural := 0;
      Ambiguous_Use_Blockers : Natural := 0;
      Selected_Prefix_Blockers : Natural := 0;
      Selected_Selector_Blockers : Natural := 0;
      With_Clause_Blockers : Natural := 0;
      Private_Child_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Renaming_Blockers : Natural := 0;
      Declaration_Kind_Blockers : Natural := 0;
      Overload_Context_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Symbol_Fingerprint_Blockers : Natural := 0;
      Visibility_Fingerprint_Blockers : Natural := 0;
      View_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Lookup_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Lookup_Model);
   procedure Add_Lookup (Model : in out Lookup_Model; Info : Lookup_Info);

   function Build (Lookups : Lookup_Model) return Result_Model;

   function Lookup_Count (Model : Lookup_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Lookup_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Lookup_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Lookup_Model is record
      Items : Lookup_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality;
