with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers;

package Editor.Ada_Language_Service is

   type Service_State is private;

   type Service_Status is
     (Service_Success,
      Service_Unavailable,
      Service_Ambiguous,
      Service_Overflow,
      Service_Stale);

   subtype Semantic_Request_Id is Natural;
   No_Semantic_Request : constant Semantic_Request_Id := 0;

   type Semantic_Request_Kind is
     (Semantic_Request_None,
      Semantic_Request_Goto_Declaration,
      Semantic_Request_Goto_Body,
      Semantic_Request_Goto_Spec,
      Semantic_Request_Find_References,
      Semantic_Request_Workspace_Symbols,
      Semantic_Request_Completion,
      Semantic_Request_Hover,
      Semantic_Request_Rename);

   type Semantic_Request_Status_Kind is
     (Semantic_Request_No_Request,
      Semantic_Request_Pending,
      Semantic_Request_Completed,
      Semantic_Request_Cancelled,
      Semantic_Request_Superseded,
      Semantic_Request_Stale);

   type Semantic_Request_Status is record
      Id                : Semantic_Request_Id := No_Semantic_Request;
      Kind              : Semantic_Request_Kind := Semantic_Request_None;
      Status            : Semantic_Request_Status_Kind :=
        Semantic_Request_No_Request;
      Query             : Ada.Strings.Unbounded.Unbounded_String;
      Index_Fingerprint : Natural := 0;
      Result_Status     : Service_Status := Service_Unavailable;
   end record;

   type Source_Location is record
      Path   : Ada.Strings.Unbounded.Unbounded_String;
      Line   : Positive := 1;
      Column : Positive := 1;
   end record;

   type Language_Target is record
      Status  : Service_Status := Service_Unavailable;
      Target  : Source_Location;
      Key     : Editor.Ada_Project_Index.Indexed_File_Key;
      Name    : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Language_Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Language_Target);

   type Language_Target_Set is record
      Status  : Service_Status := Service_Unavailable;
      Targets : Language_Target_Vectors.Vector;
   end record;

   type Completion_Item is record
      Label  : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Kind   : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Target : Source_Location;
      Key    : Editor.Ada_Project_Index.Indexed_File_Key;
   end record;

   package Completion_Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Completion_Item);

   type Completion_Result is record
      Status : Service_Status := Service_Unavailable;
      Items  : Completion_Item_Vectors.Vector;
   end record;

   type Hover_Result is record
      Status  : Service_Status := Service_Unavailable;
      Label   : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Target  : Source_Location;
      Key     : Editor.Ada_Project_Index.Indexed_File_Key;
   end record;

   type Rename_Preview is record
      Status         : Service_Status := Service_Unavailable;
      Old_Name       : Ada.Strings.Unbounded.Unbounded_String;
      New_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Edit_Count     : Natural := 0;
      Conflict_Count : Natural := 0;
      Edits          : Language_Target_Vectors.Vector;
      Conflicts      : Language_Target_Vectors.Vector;
   end record;

   type Index_Status is record
      File_Count    : Natural := 0;
      Unit_Count    : Natural := 0;
      Symbol_Count  : Natural := 0;
      Fingerprint   : Natural := 0;
      Overflowed    : Boolean := False;
   end record;

   type Semantic_Backend_Kind is
     (Semantic_Backend_Internal_Index,
      Semantic_Backend_GNAT_Compiler);

   type Semantic_Backend_Status is record
      Active_Backend              : Semantic_Backend_Kind :=
        Semantic_Backend_Internal_Index;
      Internal_Index_Available    : Boolean := False;
      Internal_Diagnostics_Active : Boolean := False;
      Compiler_Backend_Available  : Boolean := False;
      Compiler_Diagnostics_Active : Boolean := False;
      Navigation_From_Index       : Boolean := False;
      Diagnostics_From_Internal   : Boolean := False;
      Diagnostics_From_Compiler   : Boolean := False;
      Semantic_Requests_Available : Boolean := False;
      Semantic_Requests_Cancellable : Boolean := False;
      Active_Request_Id           : Semantic_Request_Id := No_Semantic_Request;
      Active_Request_Kind         : Semantic_Request_Kind :=
        Semantic_Request_None;
      Active_Request_Status       : Semantic_Request_Status_Kind :=
        Semantic_Request_No_Request;
      Previous_Request_Status     : Semantic_Request_Status_Kind :=
        Semantic_Request_No_Request;
      Fingerprint                 : Natural := 0;
   end record;

   type Language_Service_Capabilities is record
      Navigation_Supported          : Boolean := True;
      Navigation_Ready              : Boolean := False;
      References_Supported          : Boolean := True;
      References_Ready              : Boolean := False;
      Workspace_Symbols_Supported   : Boolean := True;
      Workspace_Symbols_Ready       : Boolean := False;
      Completion_Supported          : Boolean := True;
      Completion_Ready              : Boolean := False;
      Hover_Supported               : Boolean := True;
      Hover_Ready                   : Boolean := False;
      Rename_Preview_Supported      : Boolean := True;
      Rename_Preview_Ready          : Boolean := False;
      Diagnostics_Supported         : Boolean := True;
      Internal_Diagnostics_Ready    : Boolean := False;
      Compiler_Diagnostics_Ready    : Boolean := False;
      Request_Lifecycle_Supported   : Boolean := True;
      Request_Cancellation_Available : Boolean := False;
      Fingerprint                   : Natural := 0;
   end record;

   Max_Semantic_Diagnostics : constant Positive := 512;
   Max_Compiler_Diagnostics : constant Positive := 512;

   type Semantic_Diagnostic_Severity is
     (Semantic_Error,
      Semantic_Warning,
      Semantic_Info,
      Semantic_Hint);

   type Semantic_Diagnostic is record
      Severity     : Semantic_Diagnostic_Severity := Semantic_Info;
      Message      : Ada.Strings.Unbounded.Unbounded_String;
      Path         : Ada.Strings.Unbounded.Unbounded_String;
      Has_Location : Boolean := False;
      Line         : Natural := 0;
      Column       : Natural := 0;
      Source       : Ada.Strings.Unbounded.Unbounded_String;
      Has_Command_Descriptor : Boolean := False;
      Command_Descriptor :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor;
   end record;

   package Semantic_Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Diagnostic);

   type Semantic_Diagnostic_Status is record
      Diagnostic_Count : Natural := 0;
      Error_Count      : Natural := 0;
      Warning_Count    : Natural := 0;
      Info_Count       : Natural := 0;
      Hint_Count       : Natural := 0;
      Fingerprint      : Natural := 0;
      Overflowed       : Boolean := False;
   end record;

   subtype Compiler_Diagnostic_Severity is
     Editor.External_Producers.Compiler_Diagnostic_Severity;

   type Compiler_Diagnostic is record
      Severity     : Compiler_Diagnostic_Severity :=
        Editor.External_Producers.Compiler_Unknown;
      Message      : Ada.Strings.Unbounded.Unbounded_String;
      File_Label   : Ada.Strings.Unbounded.Unbounded_String;
      Has_Location : Boolean := False;
      Line         : Natural := 0;
      Column       : Natural := 0;
      Tool_Name    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Compiler_Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Compiler_Diagnostic);

   type Compiler_Backend_Status is record
      Has_Run                  : Boolean := False;
      Input_Count              : Natural := 0;
      Accepted_Count           : Natural := 0;
      Rejected_Malformed_Count : Natural := 0;
      Diagnostic_Count         : Natural := 0;
      Error_Count              : Natural := 0;
      Warning_Count            : Natural := 0;
      Info_Count               : Natural := 0;
      Note_Count               : Natural := 0;
      Unknown_Count            : Natural := 0;
      Fingerprint              : Natural := 0;
      Overflowed               : Boolean := False;
   end record;

   procedure Clear (Service : in out Service_State);

   function From_Index
     (Index : Editor.Ada_Project_Index.Index_State) return Service_State;

   procedure Put_Index
     (Service : in out Service_State;
      Index   : Editor.Ada_Project_Index.Index_State);

   function Project_Index
     (Service : Service_State) return Editor.Ada_Project_Index.Index_State;

   procedure Put_Buffer_Analysis
     (Service              : in out Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result);

   procedure Invalidate_Path (Service : in out Service_State; Path : String);
   procedure Invalidate_Path_Subtree
     (Service : in out Service_State;
      Root_Path : String);
   procedure Invalidate_Buffer
     (Service : in out Service_State;
      Buffer_Token : Natural);
   procedure Invalidate_Lifecycle
     (Service : in out Service_State;
      Lifecycle_Generation : Natural);

   function Status (Service : Service_State) return Index_Status;

   function Status
     (Index : Editor.Ada_Project_Index.Index_State) return Index_Status;

   function Backend_Status
     (Service : Service_State) return Semantic_Backend_Status;

   function Backend_Label
     (Status : Semantic_Backend_Status) return String;

   function Capabilities
     (Service : Service_State) return Language_Service_Capabilities;

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String;

   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String;

   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id;

   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id);

   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status;

   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean;

   procedure Clear_Semantic_Diagnostics (Service : in out Service_State);

   procedure Clear_Semantic_Diagnostics_By_Source_Prefix
     (Service       : in out Service_State;
      Path          : String;
      Source_Prefix : String);

   procedure Put_Semantic_Diagnostic
     (Service    : in out Service_State;
      Diagnostic : Semantic_Diagnostic);

   procedure Put_Semantic_Diagnostic_Feed
     (Service      : in out Service_State;
      Path         : String;
      Feed         : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
      Source_Label : String := "semantic-feed");

   function Semantic_Diagnostics_Status
     (Service : Service_State) return Semantic_Diagnostic_Status;

   function Semantic_Diagnostics_Status_For_Path
     (Service : Service_State;
      Path    : String) return Semantic_Diagnostic_Status;

   function Semantic_Diagnostic_Count
     (Service : Service_State) return Natural;

   function Semantic_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Semantic_Diagnostic;

   function Semantic_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural;

   function Semantic_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Semantic_Diagnostic;

   procedure Clear_Compiler_Backend (Service : in out Service_State);

   procedure Put_Compiler_Diagnostic_Lines
     (Service         : in out Service_State;
      Lines           : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Tool_Name       : String := "gnat";
      Run_Fingerprint : Natural := 0);

   function Compiler_Status
     (Service : Service_State) return Compiler_Backend_Status;

   function Compiler_Status_For_Path
     (Service : Service_State;
      Path    : String) return Compiler_Backend_Status;

   function Compiler_Diagnostic_Count
     (Service : Service_State) return Natural;

   function Compiler_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Compiler_Diagnostic;

   function Compiler_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural;

   function Compiler_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Compiler_Diagnostic;

   function Contains_Current
     (Service              : Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean;

   function Goto_Declaration
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target;

   function Request_Goto_Declaration
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target;

   function Goto_Declaration_Current
     (Service              : Service_State;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target;

   function Request_Goto_Declaration_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target;

   function Goto_Body
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;

   function Request_Goto_Body
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;

   function Goto_Spec
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;

   function Request_Goto_Spec
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;

   function Find_References
     (Service : Service_State;
      Name    : String) return Language_Target_Set;

   function Request_Find_References
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Language_Target_Set;

   function Find_Current_References
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set;

   function Request_Find_Current_References
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set;

   function Workspace_Symbols
     (Service : Service_State;
      Query   : String := "") return Language_Target_Set;

   function Request_Workspace_Symbols
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Query   : String := "") return Language_Target_Set;

   function Complete
     (Service : Service_State;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result;

   function Request_Complete
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result;

   function Complete_Current
     (Service              : Service_State;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result;

   function Request_Complete_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result;

   function Hover
     (Service : Service_State;
      Name    : String) return Hover_Result;

   function Request_Hover
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Hover_Result;

   function Hover_Current
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result;

   function Request_Hover_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result;

   function Preview_Rename
     (Service  : Service_State;
      Old_Name : String;
      New_Name : String) return Rename_Preview;

   function Request_Preview_Rename
     (Service  : in out Service_State;
      Id       : Semantic_Request_Id;
      Old_Name : String;
      New_Name : String) return Rename_Preview;

   function Preview_Rename_Current
     (Service              : Service_State;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview;

   function Request_Preview_Rename_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview;

private
   type Service_State is record
      Index                : Editor.Ada_Project_Index.Index_State;
      Semantic_Diagnostics : Semantic_Diagnostic_Vectors.Vector;
      Semantic_State       : Semantic_Diagnostic_Status;
      Compiler_Diagnostics : Compiler_Diagnostic_Vectors.Vector;
      Compiler_State       : Compiler_Backend_Status;
      Next_Request_Id      : Semantic_Request_Id := No_Semantic_Request;
      Active_Request       : Semantic_Request_Status;
      Previous_Request     : Semantic_Request_Status;
   end record;

end Editor.Ada_Language_Service;
