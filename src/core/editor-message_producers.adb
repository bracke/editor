with Editor.Feature_Targets;
with Editor.Feature_Panel;
with Editor.Feature_Messages;
with Editor.Producer_Contracts;

package body Editor.Message_Producers is

   function Normalize_Message_Source (Source : String) return String is
   begin
      return Editor.Producer_Contracts.Normalize_Producer_Source (Source);
   end Normalize_Message_Source;

   procedure Reproject_If_Active
     (State : in out Editor.State.State_Type)
   is
   begin
      Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
        (State.Feature_Messages, State.Feature_Panel);
   end Reproject_If_Active;

   function Post_Message_With_Result
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String := "";
      Kind     : Message_Source_Kind := Editor.Feature_Messages.Unknown_Source)
      return Producer_Result
   is
      Clean_Text   : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (Text);
      Clean_Source : constant String := Normalize_Message_Source (Source);
   begin
      if Clean_Text'Length = 0 then
         return Editor.Producer_Contracts.Rejected_Empty_Text;
      end if;

      Editor.Feature_Messages.Add_Message
        (Messages    => State.Feature_Messages,
         Severity    => Severity,
         Text        => Clean_Text,
         Source      => Clean_Source,
         Source_Kind => Kind);
      Reproject_If_Active (State);
      return Editor.Producer_Contracts.Accepted_Untargeted;
   end Post_Message_With_Result;

   function Post_Targeted_Message_With_Result
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String;
      Kind     : Message_Source_Kind;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural) return Producer_Result
   is
      Clean_Text   : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (Text);
      Clean_Source : constant String := Normalize_Message_Source (Source);
      Target       : constant Editor.Feature_Targets.Feature_Row_Target_Validation :=
        Editor.Feature_Targets.Validate_Buffer_Target_For_Feature_Row
          (State, Buffer, Line, Column);
   begin
      if Clean_Text'Length = 0 then
         return Editor.Producer_Contracts.Rejected_Empty_Text;
      end if;

      Editor.Feature_Messages.Add_Message
        (Messages    => State.Feature_Messages,
         Severity    => Severity,
         Text        => Clean_Text,
         Source      => Clean_Source,
         Has_Target  => Target.Valid,
         Buffer      => Target.Buffer,
         Line        => Target.Line,
         Column      => Target.Column,
         Source_Kind => Kind);
      Reproject_If_Active (State);
      if Target.Valid then
         return Editor.Producer_Contracts.Accepted;
      else
         return Editor.Producer_Contracts.Accepted_Untargeted;
      end if;
   end Post_Targeted_Message_With_Result;

   procedure Post_Message
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String := "";
      Kind     : Message_Source_Kind := Editor.Feature_Messages.Unknown_Source)
   is
      Result : constant Producer_Result :=
        Post_Message_With_Result (State, Severity, Text, Source, Kind);
      pragma Unreferenced (Result);
   begin
      null;
   end Post_Message;

   procedure Post_Targeted_Message
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String;
      Kind     : Message_Source_Kind;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural)
   is
      Result : constant Producer_Result :=
        Post_Targeted_Message_With_Result
          (State, Severity, Text, Source, Kind, Buffer, Line, Column);
      pragma Unreferenced (Result);
   begin
      null;
   end Post_Targeted_Message;

end Editor.Message_Producers;
