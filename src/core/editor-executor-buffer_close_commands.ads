with Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Project;
with Editor.State;

package Editor.Executor.Buffer_Close_Commands is

   procedure Execute_Close_All_Buffers_Confirmed
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers_Confirmed
     (S      : in out Editor.State.State_Type;
      Active : Editor.Buffers.Buffer_Id);

   procedure Finalize_Cleanup_Buffer_Close
     (S          : in out Editor.State.State_Type;
      Id         : Editor.Buffers.Buffer_Id;
      Was_Active : Boolean);

   function Dirty_Close_Start_Message
     (All_Buffers : Boolean;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String;

   function Dirty_Buffer_Summary_For_All_Buffers
     return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Dirty_Buffer_Summary_For_All_Buffers
     (Project : Editor.Project.Project_State)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary;

   function Dirty_Close_Open_Buffer_Fingerprint return Natural;

   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural;

   function Dirty_Close_Open_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;

   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String;

   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean;

   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean;

   procedure Clear_Dirty_Close_Prompt
     (S : in out Editor.State.State_Type);

   procedure Start_Dirty_Close_Prompt
     (S           : in out Editor.State.State_Type;
      Scope       : Editor.State.Dirty_Close_Scope;
      All_Buffers : Boolean;
      Buffer_Id   : Editor.Buffers.Buffer_Id;
      Summary     : Editor.Dirty_Guards.Dirty_Buffer_Summary);

   procedure Close_Buffer_By_Discard
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean);

   procedure Execute_Close_All_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Other_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_All_Clean_Buffers
     (S : in out Editor.State.State_Type);

   procedure Execute_Discard_Pending_Transition
     (S : in out Editor.State.State_Type);

   procedure Execute_Cancel_Close
     (S : in out Editor.State.State_Type);

   procedure Execute_Confirm_Close_Discard
     (S : in out Editor.State.State_Type);

   procedure Execute_Confirm_Close_Save
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id);

   procedure Execute_Buffer_Close_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Buffer_Close_Commands;
