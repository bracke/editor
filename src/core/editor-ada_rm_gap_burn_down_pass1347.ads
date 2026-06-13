with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1347 is

   --  Pass1347 is the fifth RM gap burn-down pass.  It closes a concrete
   --  representation/freezing/interfacing Ada legality gap by requiring
   --  representation clauses, operational attributes, freezing points,
   --  record and enumeration layout, import/export convention evidence,
   --  cross-slice consumers, remediation state, and balanced source-shaped
   --  regression evidence to agree on one canonical result.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Representation_Freezing_Interfacing,
      Gap_Freezing_Order,
      Gap_Record_Enum_Representation,
      Gap_Operational_Attribute,
      Gap_Import_Export_Convention,
      Gap_Cross_Slice_Representation_Use,
      Gap_Unknown);

   type Representation_Item_Kind is
     (Item_Record_Representation_Clause,
      Item_Record_Component_Clause,
      Item_Enumeration_Representation_Clause,
      Item_Aspect_Specification,
      Item_Attribute_Definition_Clause,
      Item_Stream_Attribute,
      Item_Convention,
      Item_Import,
      Item_Export,
      Item_External_Name,
      Item_Link_Name,
      Item_Address,
      Item_Storage,
      Item_Unknown);

   type Representation_Context_Kind is
     (Context_Type_Declaration,
      Context_Object_Declaration,
      Context_Subprogram,
      Context_Access_Subprogram,
      Context_Generic_Body_Replay,
      Context_Aggregate_Initialization,
      Context_Assignment_Conversion,
      Context_Dispatching_Call,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Late_Representation_After_Freezing,
      Status_Illegal_Late_Aspect_After_Freezing,
      Status_Illegal_Missing_Representation_Target,
      Status_Illegal_Wrong_Kind_Representation_Target,
      Status_Illegal_Private_Full_View_Freezing_Disagreement,
      Status_Illegal_Nonstatic_Component_Position,
      Status_Illegal_Component_First_Last_Bit_Range,
      Status_Illegal_Record_Component_Overlap,
      Status_Illegal_Record_Size_Overflow,
      Status_Illegal_Component_Size_Overflow,
      Status_Illegal_Alignment_Conflict,
      Status_Illegal_Storage_Order_Conflict,
      Status_Illegal_Enum_Representation_Incomplete,
      Status_Illegal_Enum_Extra_Literal,
      Status_Illegal_Enum_Duplicate_Code,
      Status_Illegal_Enum_Nonstatic_Value,
      Status_Illegal_Enum_Negative_Value,
      Status_Illegal_Enum_Nonmonotonic_Order,
      Status_Illegal_Stream_Profile_Mismatch,
      Status_Illegal_Stream_View_Barrier,
      Status_Illegal_Stream_External_Representation_Conflict,
      Status_Illegal_Convention_Profile_Mismatch,
      Status_Illegal_C_Profile_Incompatible,
      Status_Illegal_Import_Export_Target_Mismatch,
      Status_Illegal_Import_Export_Conflict,
      Status_Illegal_Duplicate_Interfacing_Item,
      Status_Illegal_External_Name,
      Status_Illegal_Link_Name,
      Status_Illegal_Access_Subprogram_Convention_Mismatch,
      Status_Illegal_Address_Storage_Conflict,
      Status_Illegal_Aggregate_Layout_Evidence_Not_Consumed,
      Status_Illegal_Assignment_Representation_Barrier_Lost,
      Status_Illegal_Callable_Convention_Disagreement,
      Status_Illegal_Dispatch_Convention_Evidence_Lost,
      Status_Illegal_Generic_Replay_Stale_Representation,
      Status_Runtime_Address_Alignment_Check_Preserved,
      Status_Runtime_Stream_Tag_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Generic_Template_Freezing_Barrier,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Representation_Model_Disagreement,
      Status_Consumer_Freezing_Model_Disagreement,
      Status_Consumer_Interfacing_Model_Disagreement,
      Status_Consumer_Diagnostic_Bridge_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Representation_Fingerprint_Mismatch,
      Status_Freezing_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Burn_Down_Row is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Target_State : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Item : Representation_Item_Kind := Item_Unknown;
      Context : Representation_Context_Kind := Context_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Evidence : Boolean := True;
      Remediation_Entry_Present : Boolean := True;
      Matrix_Coverage_Present : Boolean := True;
      Implementing_Package_Present : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Coverage_Entry_Updated_To_Covered : Boolean := True;
      Balanced_Regression_Evidence : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Representation_Clause_Before_Freezing : Boolean := True;
      Aspect_Before_Freezing : Boolean := True;
      Representation_Target_Present : Boolean := True;
      Representation_Target_Kind_Compatible : Boolean := True;
      Private_Full_View_Freezing_Agrees : Boolean := True;
      Generic_Formal_Freezing_Barrier : Boolean := False;
      Generic_Template_Freezing_Barrier : Boolean := False;
      Record_Component_Positions_Static : Boolean := True;
      Component_First_Last_Bits_Valid : Boolean := True;
      Record_Components_Nonoverlapping : Boolean := True;
      Record_Size_Fits : Boolean := True;
      Component_Size_Fits : Boolean := True;
      Alignment_Compatible : Boolean := True;
      Storage_Order_Compatible : Boolean := True;
      Enum_Representation_Complete : Boolean := True;
      Enum_No_Extra_Literals : Boolean := True;
      Enum_No_Duplicate_Codes : Boolean := True;
      Enum_Values_Static : Boolean := True;
      Enum_Values_Nonnegative : Boolean := True;
      Enum_Order_Monotonic : Boolean := True;
      Stream_Profile_Compatible : Boolean := True;
      Stream_View_Allowed : Boolean := True;
      No_Stream_External_Representation_Conflict : Boolean := True;
      Convention_Profile_Compatible : Boolean := True;
      C_Profile_Compatible : Boolean := True;
      Import_Export_Target_Compatible : Boolean := True;
      No_Import_Export_Conflict : Boolean := True;
      No_Duplicate_Interfacing_Items : Boolean := True;
      External_Name_Legal : Boolean := True;
      Link_Name_Legal : Boolean := True;
      Access_Subprogram_Convention_Compatible : Boolean := True;
      Address_Storage_Compatible : Boolean := True;
      Aggregate_Consumes_Layout_Evidence : Boolean := True;
      Assignment_Conversion_Consumes_Representation : Boolean := True;
      Callable_Profile_Consumes_Convention : Boolean := True;
      Dispatch_Consumes_Convention : Boolean := True;
      Generic_Replay_Uses_Fresh_Representation : Boolean := True;
      Runtime_Address_Alignment_Check : Boolean := False;
      Runtime_Stream_Tag_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Consumer_Representation_Model_Agrees : Boolean := True;
      Consumer_Freezing_Model_Agrees : Boolean := True;
      Consumer_Interfacing_Model_Agrees : Boolean := True;
      Consumer_Diagnostic_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
      Freezing_Fingerprint : Natural := 0;
      Expected_Freezing_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Row);

   type Burn_Down_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Burn_Down_Entry is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Promoted_State : Remediation_State := Remediation.State_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Classification : Precision_Classification := Precision.Class_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Items : Entry_Vectors.Vector;
      Burned_Down_Count : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row);

   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry;
   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean;
   function Representation_Freezing_Interfacing_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Pass1347;
