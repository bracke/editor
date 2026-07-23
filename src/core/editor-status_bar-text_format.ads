with Ada.Strings.Unbounded;

package Editor.Status_Bar.Text_Format is

   function Enabled
     (Config : Status_Bar_Config) return Boolean;

   function Height_In_Rows
     (Config : Status_Bar_Config) return Natural;

   function Plural
     (Count    : Natural;
      Singular : String;
      Plural_Text  : String) return String;

   function Status_Truncate_Label
     (Text        : String;
      Max_Columns : Natural := 64) return String;

   function Segment_Text
     (Value : Ada.Strings.Unbounded.Unbounded_String) return String;

   function Status_Segment_Text
     (Value : Ada.Strings.Unbounded.Unbounded_String) return String;

   function Outcome_Class_From_Severity
     (Severity : Ada.Strings.Unbounded.Unbounded_String) return String;

   function Is_Priority_Feedback
     (Severity : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Field_Or_Fallback
     (Value    : Ada.Strings.Unbounded.Unbounded_String;
      Fallback : String) return String;

   function Format_Left
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Message_Kind_For
     (Label : Ada.Strings.Unbounded.Unbounded_String) return Status_Message_Kind;

   function Status_Build_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Diagnostics_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Search_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Quick_Open_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_File_Tree_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Workspace_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Outline_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

   function Status_Recent_Projects_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind;

end Editor.Status_Bar.Text_Format;
