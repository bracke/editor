with Editor.Commands;
with Editor.Executor;
with Editor.Navigation_History;
with Editor.State;

package Editor.Executor.Navigation_Commands is


   function Current_Navigation_Location
     (S      : Editor.State.State_Type;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location;

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location;

   procedure Record_Navigation_If_Target_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location;
      Target   : Editor.Navigation_History.Navigation_Location);

   procedure Record_Navigation_If_Current_Changed
     (S        : in out Editor.State.State_Type;
      Previous : Editor.Navigation_History.Navigation_Location);

   function Same_Navigation_Place
     (S        : Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location) return Boolean;

   function Apply_Navigation_Location
     (S        : in out Editor.State.State_Type;
      Location : Editor.Navigation_History.Navigation_Location;
      Status   : out Editor.Executor.Navigation_Apply_Status) return Boolean;

   function Navigation_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Navigation_History_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   procedure Execute_Navigation_Back
     (S : in out Editor.State.State_Type);

   procedure Execute_Navigation_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Navigation_History_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Prefill_Goto_Line_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Delete_Forward
     (S : in out Editor.State.State_Type);

end Editor.Executor.Navigation_Commands;
