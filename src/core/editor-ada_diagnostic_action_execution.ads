with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;

package Editor.Ada_Diagnostic_Action_Execution is

   subtype Diagnostic_Command_Descriptor is
     Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor;
   subtype Diagnostic_Command_Descriptor_Id is
     Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor_Id;

   type Diagnostic_Action_Execution_Status is
     (Diagnostic_Action_Execution_Executed,
      Diagnostic_Action_Execution_Unavailable,
      Diagnostic_Action_Execution_Rejected_Stale);

   type Diagnostic_Action_Execution_Effect is
     (Diagnostic_Action_Effect_None,
      Diagnostic_Action_Effect_Navigate,
      Diagnostic_Action_Effect_Explain,
      Diagnostic_Action_Effect_Edit,
      Diagnostic_Action_Effect_Review_Expression,
      Diagnostic_Action_Effect_Review_Overload_Ranking,
      Diagnostic_Action_Effect_Review_Generic,
      Diagnostic_Action_Effect_Review_Cross_Unit,
      Diagnostic_Action_Effect_Review_Representation);

   type Diagnostic_Action_Execution_Result is record
      Status        : Diagnostic_Action_Execution_Status :=
        Diagnostic_Action_Execution_Unavailable;
      Effect        : Diagnostic_Action_Execution_Effect :=
        Diagnostic_Action_Effect_None;
      Descriptor_Id : Diagnostic_Command_Descriptor_Id :=
        Editor.Ada_Diagnostic_Command_Projection.No_Diagnostic_Command_Descriptor;
      Message       : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line    : Positive := 1;
      Start_Column  : Positive := 1;
      End_Line      : Positive := 1;
      End_Column    : Positive := 1;
      Has_Edit      : Boolean := False;
      Edit_Start_Line   : Positive := 1;
      Edit_Start_Column : Positive := 1;
      Edit_End_Line     : Positive := 1;
      Edit_End_Column   : Positive := 1;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint   : Natural := 0;
   end record;

   type Diagnostic_Action_Execution_Result_Set is private;
   type Diagnostic_Command_Descriptor_Array is
     array (Positive range <>) of Diagnostic_Command_Descriptor;

   function Execute
     (Descriptor : Diagnostic_Command_Descriptor)
      return Diagnostic_Action_Execution_Result;

   function Execute_All
     (Model : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Projection_Model)
      return Diagnostic_Action_Execution_Result_Set;

   function Execute_All
     (Descriptors : Diagnostic_Command_Descriptor_Array)
      return Diagnostic_Action_Execution_Result_Set;

   function Result_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function Result_At
     (Results : Diagnostic_Action_Execution_Result_Set;
      Index   : Positive) return Diagnostic_Action_Execution_Result;

   function Executed_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function Rejected_Stale_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function Unavailable_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function Editable_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function First_Success
     (Results : Diagnostic_Action_Execution_Result_Set)
      return Diagnostic_Action_Execution_Result;

   function Fingerprint
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural;

   function Is_Executable
     (Descriptor : Diagnostic_Command_Descriptor) return Boolean;

   function Is_Success
     (Result : Diagnostic_Action_Execution_Result) return Boolean;

private
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Action_Execution_Result);

   type Diagnostic_Action_Execution_Result_Set is record
      Results           : Result_Vectors.Vector;
      Executed_Total    : Natural := 0;
      Rejected_Total    : Natural := 0;
      Unavailable_Total  : Natural := 0;
      Editable_Total     : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Action_Execution;
