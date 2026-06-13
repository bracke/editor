with Ada.Strings.Unbounded;

package Editor.Build_Working_Context is

   --  Phase 502 public build working-context foundation.  This package is
   --  deliberately pure/metadata-only: it never probes the filesystem,
   --  discovers project metadata, changes cwd, executes tools, or persists
   --  state.

   type Build_Working_Context_Kind is
     (Build_Working_Context_None,
      Build_Working_Context_Current_Project_Root,
      Build_Working_Context_Current_Workspace_Root,
      Build_Working_Context_Test_Fixture,
      Build_Working_Context_Unavailable);

   type Working_Context_Source_Kind is
     (Working_Context_Source_None,
      Working_Context_Source_Canonical_Project,
      Working_Context_Source_Canonical_Workspace,
      Working_Context_Source_Test_Fixture,
      Working_Context_Source_Unavailable,
      Working_Context_Source_Raw_Text,
      Working_Context_Source_Shell_Derived,
      Working_Context_Source_Project_Metadata_Derived,
      Working_Context_Source_Filesystem_Discovered,
      Working_Context_Source_Persisted);

   type Build_Working_Context_Validation_Status is
     (Build_Working_Context_Valid,
      Build_Working_Context_Rejected_None,
      Build_Working_Context_Rejected_Unavailable,
      Build_Working_Context_Rejected_Missing_Canonical_Source,
      Build_Working_Context_Rejected_Unsafe_Source,
      Build_Working_Context_Rejected_Raw_Text,
      Build_Working_Context_Rejected_Shell_Derived,
      Build_Working_Context_Rejected_Project_Metadata_Derived,
      Build_Working_Context_Rejected_Filesystem_Discovered,
      Build_Working_Context_Rejected_Persisted,
      Build_Working_Context_Rejected_Invalid_Label,
      Build_Working_Context_Rejected_Invalid_Path);

   type Build_Working_Context_Record is record
      Kind : Build_Working_Context_Kind := Build_Working_Context_None;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Canonical_Path_If_Available : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Source_Kind : Working_Context_Source_Kind := Working_Context_Source_None;
      Validation_Status : Build_Working_Context_Validation_Status :=
        Build_Working_Context_Rejected_None;
      Validation_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function None return Build_Working_Context_Record;

   function Unavailable (Reason : String) return Build_Working_Context_Record;

   function Current_Project_Root
     (Canonical_Path : String) return Build_Working_Context_Record;

   function Current_Workspace_Root
     (Canonical_Path : String) return Build_Working_Context_Record;

   function Test_Fixture
     (Canonical_Path : String := "test-fixture-context")
      return Build_Working_Context_Record;

   function Unsafe_Context
     (Kind         : Build_Working_Context_Kind;
      Label        : String;
      Source_Kind  : Working_Context_Source_Kind;
      Path_If_Any  : String := "") return Build_Working_Context_Record;

   function Context_From_Explicit_Token
     (Token : String) return Build_Working_Context_Record;

   function Validate_Build_Working_Context
     (Context : Build_Working_Context_Record)
      return Build_Working_Context_Validation_Status;

   function Build_Working_Context_Display_Label
     (Context : Build_Working_Context_Record) return String;

   function Build_Working_Context_Message
     (Status : Build_Working_Context_Validation_Status) return String;

   function Request_Identity_Token
     (Context : Build_Working_Context_Record) return String;

   function Assert_Build_Working_Context_Is_Structured
     (Context : Build_Working_Context_Record) return Boolean;

   function Assert_Build_Working_Context_Is_Transient
     (Context : Build_Working_Context_Record) return Boolean;

   function Assert_Build_Working_Context_Does_Not_Probe_Filesystem
     (Context : Build_Working_Context_Record) return Boolean;

   function Assert_Build_Working_Context_Persistence_Excluded
     (Context : Build_Working_Context_Record) return Boolean;

end Editor.Build_Working_Context;
