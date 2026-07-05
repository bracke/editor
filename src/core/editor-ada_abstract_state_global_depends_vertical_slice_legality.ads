with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality is

   --  Case 1303 vertical-slice abstract/refined-state and Global/Depends
   --  legality.  This package checks concrete source-shaped state,
   --  constituent, Global, Depends, volatile/atomic, and shared-state rows.
   --  It is deliberately a semantic slice, not another diagnostic or
   --  stabilization wrapper.

   type State_Id is new Natural;
   No_State : constant State_Id := 0;

   type Operation_Id is new Natural;
   No_Operation : constant Operation_Id := 0;

   type Use_Id is new Natural;
   No_Use : constant Use_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type State_Kind is
     (State_Abstract,
      State_Constituent,
      State_Refined,
      State_Volatile,
      State_Atomic,
      State_Shared,
      State_Unknown);

   type Flow_Mode is
     (Mode_None,
      Mode_In,
      Mode_Out,
      Mode_In_Out,
      Mode_Proof_In);

   type Use_Kind is
     (Use_Global,
      Use_Depends_Edge,
      Use_Refined_State_Mapping,
      Use_Constituent_Declaration,
      Use_Call_Effect,
      Use_Shared_State_Effect,
      Use_Unknown);

   type State_Status is
     (State_Not_Checked,
      State_Legal_Global,
      State_Legal_Depends,
      State_Legal_Refined_State,
      State_Legal_Constituent,
      State_Legal_Shared_Effect,
      State_Missing_State,
      State_Missing_Operation,
      State_Duplicate_Abstract_State,
      State_Mode_Mismatch,
      State_Missing_Refined_State_Aspect,
      State_Missing_Constituent,
      State_Extra_Constituent,
      State_Constituent_Mode_Mismatch,
      State_Invisible_Constituent,
      State_Depends_Missing_Source,
      State_Depends_Missing_Target,
      State_Depends_Cycle,
      State_Volatile_Ordering_Error,
      State_Atomic_Mixed_Access_Error,
      State_Unprotected_Shared_Access,
      State_Source_Fingerprint_Mismatch,
      State_State_Fingerprint_Mismatch,
      State_Multiple_Blockers,
      State_Indeterminate);

   type State_Info is record
      Id       : State_Id := No_State;
      Parent   : State_Id := No_State;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : State_Kind := State_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Allowed_Mode : Flow_Mode := Mode_In_Out;
      Declared : Boolean := True;
      Visible  : Boolean := True;
      Is_Abstract : Boolean := False;
      Is_Constituent : Boolean := False;
      Is_Volatile : Boolean := False;
      Is_Atomic : Boolean := False;
      Is_Shared : Boolean := False;
      Requires_Protected_Access : Boolean := False;
      Source_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
   end record;

   type Operation_Info is record
      Id       : Operation_Id := No_Operation;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Global_Mode : Flow_Mode := Mode_None;
      Depends_Mode : Flow_Mode := Mode_None;
      Has_Global_Aspect : Boolean := True;
      Has_Depends_Aspect : Boolean := True;
      Has_Refined_State_Aspect : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Contract_Fingerprint : Natural := 0;
   end record;

   type Use_Info is record
      Id       : Use_Id := No_Use;
      Operation : Operation_Id := No_Operation;
      Target_State : State_Id := No_State;
      Source_State : State_Id := No_State;
      Parent_State : State_Id := No_State;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Use_Kind := Use_Unknown;
      Mode     : Flow_Mode := Mode_None;
      Has_Refined_State_Aspect : Boolean := True;
      Constituent_Present : Boolean := True;
      Extra_Constituent : Boolean := False;
      Constituent_Mode_Matches : Boolean := True;
      Depends_Source_Visible : Boolean := True;
      Depends_Target_Visible : Boolean := True;
      Depends_Cycle : Boolean := False;
      Volatile_Order_Known : Boolean := True;
      Atomic_Access_Consistent : Boolean := True;
      Shared_Access_Protected : Boolean := True;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Use_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Use_Ref  : Use_Id := No_Use;
      Operation : Operation_Id := No_Operation;
      Target_State : State_Id := No_State;
      Source_State : State_Id := No_State;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : State_Status := State_Not_Checked;
      Missing_State_Blockers : Natural := 0;
      Missing_Operation_Blockers : Natural := 0;
      Duplicate_State_Blockers : Natural := 0;
      Mode_Blockers : Natural := 0;
      Refined_State_Blockers : Natural := 0;
      Constituent_Blockers : Natural := 0;
      Visibility_Blockers : Natural := 0;
      Depends_Blockers : Natural := 0;
      Volatile_Blockers : Natural := 0;
      Atomic_Blockers : Natural := 0;
      Shared_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      State_Fingerprint_Blockers : Natural := 0;
      Source_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type State_Model is private;
   type Operation_Model is private;
   type Use_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out State_Model);
   procedure Clear (Model : in out Operation_Model);
   procedure Clear (Model : in out Use_Model);

   procedure Add_State (Model : in out State_Model; Info : State_Info);
   procedure Add_Operation (Model : in out Operation_Model; Info : Operation_Info);
   procedure Add_Use (Model : in out Use_Model; Info : Use_Info);

   function Build
     (States     : State_Model;
      Operations : Operation_Model;
      Uses       : Use_Model) return Result_Model;

   function State_Count (Model : State_Model) return Natural;
   function Operation_Count (Model : Operation_Model) return Natural;
   function Use_Count (Model : Use_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : State_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package State_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => State_Info);
   package Operation_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Operation_Info);
   package Use_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Use_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type State_Model is record
      Items : State_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Operation_Model is record
      Items : Operation_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Use_Model is record
      Items : Use_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality;
