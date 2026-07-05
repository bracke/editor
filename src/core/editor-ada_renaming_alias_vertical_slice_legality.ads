with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Renaming_Alias_Vertical_Slice_Legality is

   --  Case 1309 vertical-slice renaming/alias legality.
   --  This package checks concrete Ada renaming and aliasing rules against
   --  source-shaped semantic rows.  It intentionally models language legality
   --  directly instead of adding another diagnostic/provenance/closure layer.

   type Rename_Id is new Natural;
   No_Rename : constant Rename_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Rename_Kind is
     (Rename_Object,
      Rename_Exception,
      Rename_Package,
      Rename_Subprogram,
      Rename_Generic_Unit,
      Rename_Entry,
      Rename_Operator,
      Rename_Unknown);

   type Entity_Kind is
     (Entity_Unknown,
      Entity_Object,
      Entity_Constant,
      Entity_Exception,
      Entity_Package,
      Entity_Subprogram,
      Entity_Generic_Unit,
      Entity_Entry,
      Entity_Operator,
      Entity_Type,
      Entity_Component,
      Entity_Function_Result);

   type Type_Class is
     (Type_Unknown,
      Type_Void,
      Type_Boolean,
      Type_Enumeration,
      Type_Integer,
      Type_Modular,
      Type_Universal_Integer,
      Type_Real,
      Type_Universal_Real,
      Type_Access,
      Type_Access_Subprogram,
      Type_Record,
      Type_Array,
      Type_Class_Wide,
      Type_Private,
      Type_Limited);

   type Mode_Kind is
     (Mode_None,
      Mode_In,
      Mode_In_Out,
      Mode_Out,
      Mode_Access,
      Mode_Protected);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Target_Missing,
      Legality_Target_Not_Visible,
      Legality_Renamed_Kind_Mismatch,
      Legality_Object_Type_Mismatch,
      Legality_Object_Mode_Mismatch,
      Legality_Constant_View_Mismatch,
      Legality_Limited_View_Blocked,
      Legality_Private_View_Blocked,
      Legality_Accessibility_Blocked,
      Legality_Subprogram_Profile_Mismatch,
      Legality_Operator_Profile_Mismatch,
      Legality_Generic_Contract_Mismatch,
      Legality_Package_Contract_Mismatch,
      Legality_Entry_Family_Mismatch,
      Legality_Alias_Cycle,
      Legality_Alias_Depth_Exceeded,
      Legality_Predicate_Blocked,
      Legality_Shared_State_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Rename_Info is record
      Id       : Rename_Id := No_Rename;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Rename_Kind := Rename_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context : Boolean := True;
      Has_Target : Boolean := True;
      Target_Visible : Boolean := True;

      Expected_Target_Kind : Entity_Kind := Entity_Unknown;
      Actual_Target_Kind   : Entity_Kind := Entity_Unknown;
      Expected_Type : Type_Class := Type_Unknown;
      Actual_Type   : Type_Class := Type_Unknown;
      Expected_Mode : Mode_Kind := Mode_None;
      Actual_Mode   : Mode_Kind := Mode_None;

      Renaming_Defines_Constant_View : Boolean := False;
      Target_Is_Variable : Boolean := True;
      Target_Is_Limited_View : Boolean := False;
      Target_Is_Private_View : Boolean := False;
      Full_View_Visible : Boolean := True;

      Accessibility_Legal : Boolean := True;
      Subprogram_Profile_Matches : Boolean := True;
      Operator_Profile_Matches : Boolean := True;
      Generic_Contract_Matches : Boolean := True;
      Package_Contract_Matches : Boolean := True;
      Entry_Family_Profile_Matches : Boolean := True;

      Alias_Cycle_Detected : Boolean := False;
      Alias_Depth : Natural := 0;
      Alias_Depth_Limit : Natural := 32;

      Predicate_Legal : Boolean := True;
      Runtime_Check_Required : Boolean := False;
      Shared_State_Legal : Boolean := True;
      Universal_Compatible : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Rename   : Rename_Id := No_Rename;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Rename_Kind := Rename_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Target_Missing_Blockers : Natural := 0;
      Target_Visibility_Blockers : Natural := 0;
      Kind_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Mode_Blockers : Natural := 0;
      Constant_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Subprogram_Profile_Blockers : Natural := 0;
      Operator_Profile_Blockers : Natural := 0;
      Generic_Contract_Blockers : Natural := 0;
      Package_Contract_Blockers : Natural := 0;
      Entry_Family_Blockers : Natural := 0;
      Alias_Cycle_Blockers : Natural := 0;
      Alias_Depth_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Shared_State_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Resolved_Target_Kind : Entity_Kind := Entity_Unknown;
      Resolved_Type : Type_Class := Type_Unknown;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Rename_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Rename_Model);
   procedure Add_Renaming (Model : in out Rename_Model; Info : Rename_Info);

   function Build (Renamings : Rename_Model) return Result_Model;

   function Rename_Count (Model : Rename_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Rename_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Rename_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Rename_Model is record
      Items : Rename_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Renaming_Alias_Vertical_Slice_Legality;
