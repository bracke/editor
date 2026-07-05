with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality is

   --  Case 1311 vertical-slice tagged type and dispatching legality.
   --  This package checks concrete Ada tagged type, type extension,
   --  primitive operation, overriding, interface, and dispatching-call
   --  rules against source-shaped semantic rows.  It is deliberately a
   --  direct legality model rather than a closure, provenance, search, or
   --  diagnostic wrapper.

   type Dispatch_Id is new Natural;
   No_Dispatch : constant Dispatch_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Dispatch_Kind is
     (Dispatch_Tagged_Type_Declaration,
      Dispatch_Type_Extension,
      Dispatch_Private_Extension,
      Dispatch_Interface_Type,
      Dispatch_Interface_Implementation,
      Dispatch_Primitive_Declaration,
      Dispatch_Primitive_Override,
      Dispatch_Dispatching_Call,
      Dispatch_Class_Wide_Call,
      Dispatch_Controlling_Result_Call,
      Dispatch_Inherited_Primitive,
      Dispatch_Abstract_Primitive,
      Dispatch_Null_Extension,
      Dispatch_Unknown);

   type Type_Class is
     (Type_Unknown,
      Type_Tagged,
      Type_Tagged_Private,
      Type_Tagged_Limited,
      Type_Class_Wide,
      Type_Interface,
      Type_Synchronized_Interface,
      Type_Task_Interface,
      Type_Protected_Interface,
      Type_Untagged,
      Type_Access,
      Type_Abstract_Tagged);

   type Primitive_Class is
     (Primitive_Unknown,
      Primitive_Function,
      Primitive_Procedure,
      Primitive_Operator,
      Primitive_Entry,
      Primitive_Abstract,
      Primitive_Null,
      Primitive_Inherited,
      Primitive_Renamed);

   type Override_Mode is
     (Override_Not_Specified,
      Override_Required,
      Override_Forbidden,
      Override_Allowed,
      Override_Unknown);

   type Controlling_Mode is
     (Controlling_None,
      Controlling_Operand,
      Controlling_Result,
      Controlling_Operand_And_Result,
      Controlling_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Not_Tagged,
      Legality_Parent_Missing,
      Legality_Parent_Not_Tagged,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Interface_Mismatch,
      Legality_Interface_Not_Implemented,
      Legality_Abstract_Primitive_Not_Overridden,
      Legality_Concrete_Primitive_Required,
      Legality_Primitive_Profile_Mismatch,
      Legality_Overriding_Required,
      Legality_Overriding_Forbidden,
      Legality_Inherited_Primitive_Hidden,
      Legality_Dispatching_Target_Missing,
      Legality_Controlling_Operand_Missing,
      Legality_Controlling_Result_Mismatch,
      Legality_Class_Wide_Mismatch,
      Legality_Ambiguous_Dispatching_Call,
      Legality_Non_Dispatching_Call,
      Legality_Accessibility_Blocked,
      Legality_Generic_Contract_Blocked,
      Legality_Renaming_Blocked,
      Legality_Exception_Finalization_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Dispatch_Info is record
      Id       : Dispatch_Id := No_Dispatch;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Dispatch_Kind := Dispatch_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context : Boolean := True;
      Type_Kind : Type_Class := Type_Tagged;
      Parent_Type_Kind : Type_Class := Type_Tagged;
      Has_Parent_Type : Boolean := True;
      Parent_Visible : Boolean := True;
      Private_View_Available : Boolean := True;
      Limited_View_Available : Boolean := True;

      Primitive_Kind : Primitive_Class := Primitive_Function;
      Override : Override_Mode := Override_Not_Specified;
      Has_Overridden_Primitive : Boolean := True;
      Profile_Conformant : Boolean := True;
      Abstract_Primitive_Overridden : Boolean := True;
      Concrete_Primitive_Available : Boolean := True;
      Inherited_Primitive_Visible : Boolean := True;

      Implements_Interface : Boolean := True;
      Required_Interface_Present : Boolean := True;
      Interface_Profile_Conformant : Boolean := True;
      Null_Extension_Legal : Boolean := True;

      Has_Dispatching_Target : Boolean := True;
      Controlling : Controlling_Mode := Controlling_Operand;
      Has_Controlling_Operand : Boolean := True;
      Controlling_Operand_Class_Wide : Boolean := True;
      Controlling_Result_Compatible : Boolean := True;
      Class_Wide_Compatible : Boolean := True;
      Candidate_Count : Natural := 1;
      Visible_Candidate_Count : Natural := 1;
      Dispatching_Call_Expected : Boolean := True;
      Runtime_Tag_Check_Required : Boolean := False;

      Accessibility_Legal : Boolean := True;
      Generic_Contract_Legal : Boolean := True;
      Renaming_Legal : Boolean := True;
      Exception_Finalization_Legal : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Dispatch : Dispatch_Id := No_Dispatch;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Dispatch_Kind := Dispatch_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Not_Tagged_Blockers : Natural := 0;
      Parent_Missing_Blockers : Natural := 0;
      Parent_Not_Tagged_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Interface_Mismatch_Blockers : Natural := 0;
      Interface_Missing_Blockers : Natural := 0;
      Abstract_Not_Overridden_Blockers : Natural := 0;
      Concrete_Required_Blockers : Natural := 0;
      Profile_Blockers : Natural := 0;
      Overriding_Required_Blockers : Natural := 0;
      Overriding_Forbidden_Blockers : Natural := 0;
      Inherited_Hidden_Blockers : Natural := 0;
      Dispatch_Target_Blockers : Natural := 0;
      Controlling_Operand_Blockers : Natural := 0;
      Controlling_Result_Blockers : Natural := 0;
      Class_Wide_Blockers : Natural := 0;
      Ambiguous_Dispatch_Blockers : Natural := 0;
      Non_Dispatching_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Generic_Contract_Blockers : Natural := 0;
      Renaming_Blockers : Natural := 0;
      Exception_Finalization_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Dispatch_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Dispatch_Model);
   procedure Add_Dispatch (Model : in out Dispatch_Model; Info : Dispatch_Info);

   function Build (Dispatches : Dispatch_Model) return Result_Model;

   function Dispatch_Count (Model : Dispatch_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Dispatch_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dispatch_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Dispatch_Model is record
      Items : Dispatch_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality;
