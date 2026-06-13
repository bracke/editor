with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Feature_Panel;

package Editor.Feature_Messages is

   --  The Messages feature is a session-local feature-panel surface for
   --  editor-originated messages. Messages owns source rows, filters, severity
   --  visibility, selection reconciliation, retention, adjacent deduplication,
   --  action affordances, and lifecycle cleanup. Generic feature-panel code owns
   --  only projection rows, reveal mechanics, visible-row mapping, and focus.
   --  Producers may append through the Messages producer API, but must not
   --  mutate message storage or projection internals directly.
   --
   --  Messages is not a compiler diagnostics engine, LSP diagnostics store,
   --  build log, persistent notification database, project-wide analyzer,
   --  search-results model, full logging subsystem, or background event queue.
   --  Messages may optionally carry validated buffer targets and may navigate
   --  only through shared editor navigation helpers after target validation.

   type Message_Severity is
     (Info_Message,
      Warning_Message,
      Error_Message);

   --  Source kind is a producer-facing classification used for session-local
   --  filtering and display only. It is not a background queue, persistent log
   --  channel, compiler source, LSP source, or file-watcher handle.
   type Message_Source_Kind is
     (Editor_Source,
      File_Source,
      Project_Source,
      Workspace_Source,
      Command_Source,
      Unknown_Source);

   type Message_Id is new Natural;
   No_Message : constant Message_Id := 0;
   No_Buffer  : constant Natural := 0;

   type Message_Item is private;
   type Message_Feature_State is private;

   procedure Clear
     (Messages : in out Message_Feature_State);

   procedure Add_Message
     (Messages   : in out Message_Feature_State;
      Severity   : Message_Severity;
      Text       : String;
      Source     : String := "";
      Has_Target : Boolean := False;
      Buffer     : Natural := No_Buffer;
      Line       : Natural := 0;
      Column     : Natural := 0;
      Source_Kind : Message_Source_Kind := Unknown_Source);

   procedure Clear_Messages
     (Messages : in out Message_Feature_State);

   procedure Set_Filter_Text
     (Messages : in out Message_Feature_State;
      Text     : String);

   procedure Clear_Filter
     (Messages : in out Message_Feature_State);

   procedure Reconcile_Messages_After_Row_Change
     (Messages        : Message_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Message_Id := No_Message;
      Previous_Source : Natural := 0);

   procedure Assert_Messages_State_Consistent
     (Messages : Message_Feature_State);

   procedure Assert_Messages_Projection_Consistent
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State);

   procedure Show_All
     (Messages : in out Message_Feature_State);

   procedure Toggle_Info
     (Messages : in out Message_Feature_State);

   procedure Toggle_Warnings
     (Messages : in out Message_Feature_State);

   procedure Toggle_Errors
     (Messages : in out Message_Feature_State);

   function Filter_Is_Active
     (Messages : Message_Feature_State) return Boolean;

   function Visible_Row_Count
     (Messages : Message_Feature_State) return Natural;

   function Severity_Is_Visible
     (Messages : Message_Feature_State;
      Severity : Message_Severity) return Boolean;

   function Row_Count
     (Messages : Message_Feature_State) return Natural;

   function Is_Empty
     (Messages : Message_Feature_State) return Boolean;

   function Item_Id
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Id;

   function Item_Severity
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Severity;

   function Item_Text
     (Messages : Message_Feature_State;
      Index    : Positive) return String;

   function Item_Source_Label
     (Messages : Message_Feature_State;
      Index    : Positive) return String;

   function Item_Source_Kind
     (Messages : Message_Feature_State;
      Index    : Positive) return Message_Source_Kind;

   function Item_Repeat_Count
     (Messages : Message_Feature_State;
      Index    : Positive) return Positive;

   function Item_Has_Target
     (Messages : Message_Feature_State;
      Index    : Positive) return Boolean;

   function Item_Target_Buffer
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural;

   function Item_Target_Line
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural;

   function Item_Target_Column
     (Messages : Message_Feature_State;
      Index    : Positive) return Natural;

   function Has_Selected_Message
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Selected_Message_Id
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Message_Id;

   function Selected_Message_Source_Index
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return Natural;

   function Selected_Message_Text
     (Messages : Message_Feature_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Format_Message_For_Copy
     (Messages : Message_Feature_State;
      Index    : Positive) return String;

   function Clear_Message_By_Id
     (Messages : in out Message_Feature_State;
      Id       : Message_Id) return Boolean;

   function Clear_Selected_Message
     (Messages : in out Message_Feature_State;
      Panel    : in out Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Clear_Messages_By_Severity
     (Messages : in out Message_Feature_State;
      Severity : Message_Severity) return Natural;

   function Clear_Messages_By_Source_Kind
     (Messages : in out Message_Feature_State;
      Kind     : Message_Source_Kind) return Natural;

   procedure Reconcile_Messages_Selection_After_Delete
     (Messages        : Message_Feature_State;
      Panel           : in out Editor.Feature_Panel.Feature_Panel_State;
      Previous_Id     : Message_Id;
      Previous_Source : Natural);

   function Severity_Label
     (Severity : Message_Severity) return String;

   function Source_Kind_Label
     (Kind : Message_Source_Kind) return String;

   function Max_Retained_Messages return Natural;

   function Build_Messages_Header_Text
     (Messages : Message_Feature_State) return String;


   procedure Project_Rows
     (Messages : Message_Feature_State;
      Panel    : in out Editor.Feature_Panel.Feature_Panel_State);

   function Map_Message_Row_To_Item
     (Messages                    : Message_Feature_State;
      Panel                       : Editor.Feature_Panel.Feature_Panel_State;
      Row                         : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural;

   function Validate_Message_Target
     (Messages            : Message_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean;

   procedure Reset_For_Buffer_Close
     (Messages     : in out Message_Feature_State;
      Buffer_Token : Natural);

   procedure Reset_For_Project_Close
     (Messages : in out Message_Feature_State);

   procedure Reset_For_Workspace_Close
     (Messages : in out Message_Feature_State);

   function Validate_Row_Action
     (Messages                    : Message_Feature_State;
      Panel                       : Editor.Feature_Panel.Feature_Panel_State;
      Row                         : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean;

   function Message_Messages_Shown return String;
   function Message_Messages_Cleared return String;
   function Message_No_Messages return String;
   function Message_No_Selected_Message return String;
   function Message_No_Visible_Message return String;
   function Message_No_Target return String;
   function Message_Target_Unavailable return String;
   function Message_Filter_Cleared return String;
   function Message_All_Severities_Shown return String;
   function Message_Info_Hidden return String;
   function Message_Info_Shown return String;
   function Message_Warnings_Hidden return String;
   function Message_Warnings_Shown return String;
   function Message_Errors_Hidden return String;
   function Message_Errors_Shown return String;
   function Message_Message_Cleared return String;
   function Message_Message_Copied return String;
   function Reason_No_Message_Rows return String;

private
   type Messages_Filter_State is record
      Text          : Ada.Strings.Unbounded.Unbounded_String;
      Show_Info     : Boolean := True;
      Show_Warnings : Boolean := True;
      Show_Errors   : Boolean := True;
   end record;

   type Message_Item is record
      Id            : Message_Id := No_Message;
      Severity      : Message_Severity := Info_Message;
      Text          : Ada.Strings.Unbounded.Unbounded_String;
      Source_Kind   : Message_Source_Kind := Unknown_Source;
      Source_Label  : Ada.Strings.Unbounded.Unbounded_String;
      Repeat_Count  : Positive := 1;
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
   end record;

   package Message_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Message_Item);

   type Message_Feature_State is record
      Rows    : Message_Row_Vectors.Vector;
      Next_Id : Message_Id := 1;
      Filter  : Messages_Filter_State;
   end record;

end Editor.Feature_Messages;
