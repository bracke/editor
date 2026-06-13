with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Project_Index is

   Max_Index_Files : constant Positive := 512;
   Max_Index_Units : constant Positive := 2048;

   type Indexed_File_Key is record
      Path                 : Ada.Strings.Unbounded.Unbounded_String;
      Buffer_Token         : Natural := 0;
      Buffer_Revision      : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      Fingerprint          : Natural := 0;
   end record;

   type Index_State is private;

   type Indexed_Unit_Role is
     (Unit_Any,
      Unit_Package_Spec,
      Unit_Private_Package_Spec,
      Unit_Package_Body,
      Unit_Subprogram_Spec,
      Unit_Subprogram_Body,
      Unit_Separate_Body);

   type Indexed_Unit is record
      Unit_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Role                 : Indexed_Unit_Role := Unit_Any;
      Path                 : Ada.Strings.Unbounded.Unbounded_String;
      Key                  : Indexed_File_Key;
      Symbol               : Editor.Ada_Language_Model.Symbol_Info;
   end record;

   package Indexed_Unit_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Indexed_Unit);

   type Unit_Resolution_Result is record
      Matches  : Indexed_Unit_Vectors.Vector;
      Overflow : Boolean := False;
   end record;

   type Indexed_Symbol is record
      Path   : Ada.Strings.Unbounded.Unbounded_String;
      Key    : Indexed_File_Key;
      Symbol : Editor.Ada_Language_Model.Symbol_Info;
   end record;

   package Indexed_Symbol_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Indexed_Symbol);

   type Index_Resolution_Result is record
      Matches  : Indexed_Symbol_Vectors.Vector;
      Overflow : Boolean := False;
   end record;

   procedure Clear (Index : in out Index_State);

   procedure Put_Analysis
     (Index                : in out Index_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result);

   procedure Invalidate_Path (Index : in out Index_State; Path : String);
   procedure Invalidate_Path_Subtree (Index : in out Index_State; Root_Path : String);
   procedure Invalidate_Buffer (Index : in out Index_State; Buffer_Token : Natural);
   procedure Invalidate_Lifecycle
     (Index : in out Index_State; Lifecycle_Generation : Natural);

   function Contains_Path
     (Index : Index_State;
      Path  : String) return Boolean;

   function Contains_Current
     (Index                : Index_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean;

   function Contains_Key
     (Index : Index_State;
      Key   : Indexed_File_Key) return Boolean;

   function Contains_Open_Buffer_Key
     (Index                : Index_State;
      Key                  : Indexed_File_Key;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural) return Boolean;

   function Resolve
     (Index : Index_State;
      Name  : String) return Index_Resolution_Result;

   function Resolve_Current
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Index_Resolution_Result;

   function First_Match
     (Index : Index_State;
      Name  : String) return Indexed_Symbol;

   function Has_Match
     (Index : Index_State;
      Name  : String) return Boolean;

   function First_Current_Match
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Indexed_Symbol;

   function Has_Current_Match
     (Index                : Index_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean;

   type Unique_Target_Result is record
      Available : Boolean := False;
      Ambiguous : Boolean := False;
      Overflow  : Boolean := False;
      Target    : Indexed_Symbol;
   end record;

   type Navigation_Target_Status is
     (Navigation_Target_Unavailable,
      Navigation_Target_Unique,
      Navigation_Target_Ambiguous,
      Navigation_Target_Overflow);

   type Navigation_Candidate_Result is record
      Status     : Navigation_Target_Status := Navigation_Target_Unavailable;
      Candidates : Indexed_Symbol_Vectors.Vector;
   end record;

   function Resolve_Navigation_Candidates
     (Index                       : Index_State;
      Name                        : String;
      Kind                        : Editor.Ada_Language_Model.Symbol_Kind;
      Want_Body                   : Boolean;
      Profile_Summary             : String := "";
      Require_Profile             : Boolean := False;
      Accept_Generic_Package_Spec : Boolean := False;
      Accept_Generic_Subprogram   : Boolean := False;
      Accept_Operator_Function    : Boolean := False) return Navigation_Candidate_Result;

   function Resolve_Related_Unit_Candidates
     (Index     : Index_State;
      From      : Indexed_Symbol;
      Want_Body : Boolean) return Navigation_Candidate_Result;

   function Resolve_Unit_Family_Targets
     (Index : Index_State;
      From  : Indexed_Symbol;
      Role  : Indexed_Unit_Role := Unit_Any) return Navigation_Candidate_Result;

   function Navigation_Candidate_Display_Label
     (Candidate : Indexed_Symbol) return String;

   function Navigation_Candidate_Detail_Label
     (Candidate : Indexed_Symbol) return String;

   function Resolve_Unique_Navigation_Target
     (Index                       : Index_State;
      Name                        : String;
      Kind                        : Editor.Ada_Language_Model.Symbol_Kind;
      Want_Body                   : Boolean;
      Profile_Summary             : String := "";
      Require_Profile             : Boolean := False;
      Accept_Generic_Package_Spec : Boolean := False;
      Accept_Generic_Subprogram   : Boolean := False;
      Accept_Operator_Function    : Boolean := False) return Unique_Target_Result;

   function Resolve_Unit
     (Index     : Index_State;
      Unit_Name : String;
      Role      : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result;

   function Resolve_Unique_Unit_Target
     (Index     : Index_State;
      Unit_Name : String;
      Role      : Indexed_Unit_Role := Unit_Any) return Unique_Target_Result;

   function Resolve_Related_Unit_Target
     (Index     : Index_State;
      From      : Indexed_Symbol;
      Want_Body : Boolean) return Unique_Target_Result;

   function Resolve_Separate_Parent_Target
     (Index         : Index_State;
      Separate_Body : Indexed_Symbol) return Unique_Target_Result;

   function Resolve_Parent_Unit_Target
     (Index : Index_State;
      From  : Indexed_Symbol) return Unique_Target_Result;

   function Resolve_Child_Units
     (Index  : Index_State;
      Parent : Indexed_Symbol;
      Role   : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result;

   function Resolve_Unit_Family
     (Index : Index_State;
      From  : Indexed_Symbol;
      Role  : Indexed_Unit_Role := Unit_Any) return Unit_Resolution_Result;

   function File_Count (Index : Index_State) return Natural;

   function File_Key_At
     (Index : Index_State;
      Position : Positive) return Indexed_File_Key;

   function File_Analysis_At
     (Index : Index_State;
      Position : Positive) return Editor.Ada_Language_Model.Analysis_Result;

   function Unit_At
     (Index : Index_State;
      Position : Positive) return Indexed_Unit;

   function Unit_Role_For_Symbol
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Indexed_Unit_Role;

   function Unit_Count (Index : Index_State) return Natural;
   function Symbol_Count (Index : Index_State) return Natural;
   function Overflowed (Index : Index_State) return Boolean;
   function Fingerprint (Index : Index_State) return Natural;

private
   type Indexed_File is record
      Key      : Indexed_File_Key;
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
   end record;

   package File_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Indexed_File);

   type Index_State is record
      Files : File_Vectors.Vector;
      Units : Indexed_Unit_Vectors.Vector;
      Index_Overflow : Boolean := False;
      Unit_Overflow  : Boolean := False;
      Index_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Project_Index;
